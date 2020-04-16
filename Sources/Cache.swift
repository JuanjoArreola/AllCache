//
//  Cache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation
import Logg
import AsyncRequest

internal let diskQueue = DispatchQueue(label: "com.allcache.DiskQueue", attributes: .concurrent)
private let diskWriteQueue = DispatchQueue(label: "com.allcache.DiskWriteQueue", attributes: [])

private let fetchQueue = DispatchQueue(label: "com.allcache.FetchQueue", attributes: [])
private let processQueue = DispatchQueue(label: "com.allcache.ProcessQueue", attributes: .concurrent)

public let log = CompositeLogger(loggers: [ConsoleLogger(formatter: AllCacheFormatter(), level: [.warning, .error, .severe])])

/// The Cache class is a generic container that stores key-value pairs, 
/// internally has a memory cache and a disk cache
open class Cache<T: AnyObject> {
    
    private let requestCache = RequestingCache<T>()
    private let lowMemoryHandler = LowMemoryHandler<T>()
    
    public let identifier: String
    
    public let memoryCache = MemoryCache<T>()
    public let diskCache: DiskCache<T>
    
    open var responseQueue = DispatchQueue.main
    open var moveOriginalToMemoryCache = false
    open var moveOriginalToDiskCache = true
    
    /// The designated initializer for a cache
    /// - parameter identifier: The identifier of the cache, is used to create a folder for the disk cache
    /// - parameter serializer: The serializer that converts objects into Data and Data into objects
    /// - parameter maxCapacity: The maximum size of the disk cache in bytes. This is only a hint
    required public init(identifier: String, serializer: DataSerializer<T>, maxCapacity: Int = 0) throws {
        self.identifier = identifier
        diskCache = try DiskCache<T>(identifier: identifier, serializer: serializer)
        diskCache.maxCapacity = maxCapacity
        lowMemoryHandler.cache = self
    }
    
    // MARK: - GET
    
    /// Search an object in caches, does not try to fetch it if not found
    open func object(forKey key: String) throws -> T? {
        if let object = memoryCache.object(forKey: key) {
            return object
        }
        let object = try diskCache.object(forKey: key)
        memoryCache.set(object: object, forKey: key)
        return object
    }
    
    /// Search an object in the caches, if the object is found the completion closure is called,
    /// if not, the cache search for the original object and apply the objectProcessor,
    /// if the origianl object wasn't found it uses the objectFetcher to try to get it.
    /// - parameter key: the key of the object to search
    /// - parameter fetcher: The object that fetches the object if is not currently in the cache
    /// - parameter processor: The object that process the original object to obtain the final object
    /// - parameter completion: The clusure to call when the cache finds the object
    /// - returns: A request object
    open func object(forKey key: String, fetcher: Fetcher<T>, processor: Processor<T>? = nil, completion: @escaping (T) -> Void) -> Request<T> {
        let descriptor = CachableDescriptor<T>(key: key, fetcher: fetcher, processor: processor)
        return object(for: descriptor, completion: completion)
    }
    
    /// Search an object in the caches, if the object is found the completion closure is called,
    /// if not, the cache search for the original object and apply the objectProcessor,
    /// if the origianl object wasn't found it uses the objectFetcher to try to get it.
    /// - parameter descriptor: An object that encapsulates the key, origianlKey, objectFetcher and objectProcessor
    /// - parameter completion: The clusure to call when the cache finds the object
    /// - returns: An optional request
    open func object(for descriptor: CachableDescriptor<T>, completion: @escaping (T) -> Void) -> Request<T> {
        let (request, ongoing) = requestCache.request(forKey: descriptor.resultKey)
        let proxy = request.proxy(success: completion)
        if ongoing { return proxy }
        
        if let object = memoryCache.object(forKey: descriptor.resultKey) {
            request.complete(with: object, in: responseQueue)
            return proxy
        }
        diskQueue.async {
            self.searchOnDisk(key: descriptor.resultKey, descriptor: descriptor, request: request)
        }
        return proxy
    }
    
    private func searchOnDisk(key: String, descriptor: CachableDescriptor<T>, request: Request<T>) {
        do {
            if let object = try diskCache.object(forKey: key) {
                responseQueue.async {
                    request.complete(with: object)
                    self.memoryCache.set(object: object, forKey: key)
                }
            } else if let _ = descriptor.processor {
                responseQueue.async {
                    self.searchOriginal(key: descriptor.key, descriptor: descriptor, request: request)
                }
            } else {
                fetchObject(for: descriptor, request: request)
            }
        } catch {
            request.complete(with: error, in: responseQueue)
        }
    }
    
    private func searchOriginal(key: String, descriptor: CachableDescriptor<T>, request: Request<T>) {
        if let rawObject = memoryCache.object(forKey: key) {
            process(rawObject: rawObject, with: descriptor, request: request)
            return
        }
        diskQueue.async {
            do {
                if let rawObject = try self.diskCache.object(forKey: key) {
                    self.process(rawObject: rawObject, with: descriptor, request: request)
                    self.saveToMemory(original: rawObject, forKey: key)
                } else {
                    self.fetchObject(for: descriptor, request: request)
                }
            } catch {
                request.complete(with: error, in: self.responseQueue)
            }
        }
    }
    
    @inline(__always)
    private func saveToMemory(original object: T, forKey key: String) {
        if moveOriginalToMemoryCache {
            memoryCache.set(object: object, forKey: key, in: responseQueue)
        }
    }
    
    private func fetchObject(for descriptor: CachableDescriptor<T>, request: Request<T>) {
        request.subrequest = requestCache.fetchingRequest(fetcher: descriptor.fetcher, completion: { result in            
            if descriptor.processor == nil {
                self.memoryCache.set(object: result.object, forKey: descriptor.key, in: self.responseQueue)
                request.complete(with: result.object, in: self.responseQueue)
                self.persist(object: result.object, data: result.data, key: descriptor.key)
                return
            }
            self.process(rawObject: result.object, with: descriptor, request: request)
            self.saveToMemory(original: result.object, forKey: descriptor.key)
            if self.moveOriginalToDiskCache {
                self.persist(object: result.object, data: result.data, key: descriptor.key)
            }
        }).fail { error in
            request.complete(with: error, in: self.responseQueue)
        }
    }
    
    @inline(__always)
    private func process(rawObject: T, with descriptor: CachableDescriptor<T>, request: Request<T>) {
        guard let processor = descriptor.processor, !request.completed else { return }
        
        processQueue.async {
            log.debug("processing (\(descriptor.resultKey))")
            do {
                let object = try processor.process(object: rawObject)
                self.memoryCache.set(object: object, forKey: descriptor.resultKey, in: self.responseQueue)
                request.complete(with: object, in: self.responseQueue)
                self.persist(object: object, data: nil, key: descriptor.resultKey)
            } catch {
                request.complete(with: error, in: self.responseQueue)
            }
        }
    }
    
    @inline(__always)
    private func persist(object: T?, data: Data?, key: String) {
        diskWriteQueue.async {
            do {
                if let data = data {
                    try self.diskCache.set(data: data, forKey: key)
                } else if let object = object {
                    try self.diskCache.set(object: object, forKey: key)
                }
            } catch {
                log.error(error)
            }
        }
    }
    
    // MARK: - Set
    
    open func set(_ object: T, forKey key: String, errorHandler: ((_ error: Error) -> Void)? = nil) {
        memoryCache.set(object: object, forKey: key)
        diskQueue.async(flags: .barrier, execute: {
            do {
                try self.diskCache.set(object: object, forKey: key)
            } catch {
                self.responseQueue.async { errorHandler?(error) }
            }
        })
    }
    
    // MARK: - Delete
    
    open func removeObject(forKey key: String, errorHandler: ((_ error: Error) -> Void)? = nil) {
        memoryCache.removeObject(forKey: key)
        diskQueue.async(flags: .barrier, execute: {
            do {
                try self.diskCache.removeObject(forKey: key)
            } catch {
                self.responseQueue.async { errorHandler?(error) }
            }
        }) 
    }
    
    open func clear() {
        memoryCache.clear()
        diskQueue.async {
            self.diskCache.clear()
        }
    }
}

public extension Cache where T: Codable {
    
    convenience init(identifier: String, maxCapacity: Int = 0) throws {
        try self.init(identifier: identifier, serializer: CodableSerializer<T>(), maxCapacity: maxCapacity)
    }
}
