//
//  Cache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation
import Logg

internal let diskQueue = DispatchQueue(label: "com.allcache.DiskQueue", attributes: .concurrent)
private let diskWriteQueue = DispatchQueue(label: "com.allcache.DiskWriteQueue", attributes: [])

private let fetchQueue = DispatchQueue(label: "com.allcache.FetchQueue", attributes: [])
private let processQueue = DispatchQueue(label: "com.allcache.ProcessQueue", attributes: .concurrent)


public let Log = LoggerContainer(loggers: [ConsoleLogger(formatter: AllCacheFormatter(), level: .all)])

/// The Cache class is a generic container that stores key-value pairs, 
/// internally has a memory cache and a disk cache
open class Cache<T: AnyObject> {
    
    private var requestCache = RequestingCache<T>()
    
    open let memoryCache = MemoryCache<T>()
    open var diskCache: DiskCache<T>!
    open let identifier: String
    
    open var responseQueue = DispatchQueue.main
    open var moveOriginalToMemoryCache = false
    open var moveOriginalToDiskCache = true
    
    /// The designated initializer for a cache
    /// - parameter identifier: The identifier of the cache, is used to create a folder for the disk cache
    /// - parameter serializer: The serializer that converts objects into Data and Data into objects
    /// - parameter maxCapacity: The maximum size of the disk cache in bytes. This is only a hint
    required public init(identifier: String, serializer: DataSerializer<T>, maxCapacity: Int = 0) throws {
        self.identifier = identifier
        self.diskCache = try DiskCache<T>(identifier: identifier, serializer: serializer, maxCapacity: maxCapacity)
        registerForLowMemoryNotification()
    }
    
    // MARK: - Configuration
    
    #if os(iOS) || os(tvOS)
    func registerForLowMemoryNotification() {
        let name = NSNotification.Name.UIApplicationDidReceiveMemoryWarning
        let selector = #selector(self.handleMemoryWarning(notification:))
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    #else
    
    func registerForLowMemoryNotification() {}
    
    #endif
    
    // MARK: - GET
    
    /// Search an object in caches, does not try to fetch it if not found
    open func object(forKey key: String) throws -> T? {
        if let object = memoryCache.object(forKey: key) {
            Log.debug("\(key) found in memory")
            return object
        }
        Log.debug("\(key) NOT found in memory")
        
        if let object = try diskCache?.object(forKey: key) {
            Log.debug("-\(key) found in disk")
            memoryCache.set(object: object, forKey: key)
            diskQueue.async {
                self.diskCache?.updateLastAccess(ofKey: key)
            }
            return object
        }
        Log.debug("\(key) NOT found in disk")
        return nil
    }
    
    /// Search an object in the caches, if the object is found the completion closure is called, if not, the cache search for the original object and apply the objectProcessor, if the origianl object wasn't found it uses the objectFetcher to try to get it.
    /// - parameter key: the key of the object to search
    /// - parameter fetcher: The object that fetches the object if is not currently in the cache
    /// - parameter processor: The object that process the original object to obtain the final object
    /// - parameter completion: The clusure to call when the cache finds the object
    /// - returns: A request object
    open func object(forKey key: String, fetcher: Fetcher<T>, processor: Processor<T>? = nil, completion: @escaping (_ getObject: () throws -> T) -> Void) -> Request<T> {
        let descriptor = CachableDescriptor<T>(key: key, fetcher: fetcher, processor: processor)
        return object(for: descriptor, completion: completion)
    }
    
    /// Search an object in the caches, if the object is found the completion closure is called, if not, the cache search for the original object and apply the objectProcessor, if the origianl object wasn't found it uses the objectFetcher to try to get it.
    /// - parameter descriptor: An object that encapsulates the key, origianlKey, objectFetcher and objectProcessor
    /// - parameter completion: The clusure to call when the cache finds the object
    /// - returns: An optional request
    open func object(for descriptor: CachableDescriptor<T>, completion: @escaping (_ getObject: () throws -> T) -> Void) -> Request<T> {
        let key = descriptor.resultKey ?? descriptor.key
        let (request, ongoing) = requestCache.request(forKey: key, completion: completion)
        if ongoing { return request }
        
        if let object = memoryCache.object(forKey: key) {
            Log.debug("\(key) found in memory")
            responseQueue.async { request.complete(withObject: object) }
            requestCache.setCached(request: nil, forIdentifier: key)
            return request
        }
        Log.debug("\(key) NOT found in memory")
        
        diskQueue.async {
            do {
                if let object = try self.diskCache?.object(forKey: key) {
                    Log.debug("\(descriptor.key) found in disk")
                    self.responseQueue.async {
                        request.complete(withObject: object)
                        self.memoryCache.set(object: object, forKey: key)
                        self.requestCache.setCached(request: nil, forIdentifier: key)
                    }
                    self.diskCache?.updateLastAccess(ofKey: key)
                    return
                }
            } catch {
                self.responseQueue.async { request.complete(withError: error) }
                return
            }
            Log.debug("\(descriptor.key) NOT found in disk")
            
            if let _ = descriptor.processor {
                self.searchOriginal(key: descriptor.key, descriptor: descriptor, request: request)
            } else {
                self.fetchObject(for: descriptor, request: request)
            }
        }
        return request
    }
    
    private func searchOriginal(key: String, descriptor: CachableDescriptor<T>, request: Request<T>) {
        self.responseQueue.async {
            if let rawObject = self.memoryCache.object(forKey: key) {
                Log.debug("\(key) found in memory")
                self.process(rawObject: rawObject, withDescriptor: descriptor, request: request)
                return
            }
            diskQueue.async {
                do {
                    if let rawObject = try self.diskCache?.object(forKey: key) {
                        Log.debug("\(descriptor.key) found in disk")
                        self.process(rawObject: rawObject, withDescriptor: descriptor, request: request)
                        if self.moveOriginalToMemoryCache {
                            self.responseQueue.async {
                                self.memoryCache.set(object: rawObject, forKey: key)
                            }
                        }
                        self.diskCache?.updateLastAccess(ofKey: descriptor.key)
                    } else if request.canceled {
                        self.requestCache.setCached(request: nil, forIdentifier: descriptor.key)
                    } else {
                        Log.debug("\(key) NOT found in disk")
                        self.fetchObject(for: descriptor, request: request)
                    }
                } catch {
                    self.responseQueue.async { request.complete(withError: error) }
                }
            }
        }
        
    }
    
    private func fetchObject(for descriptor: CachableDescriptor<T>, request: Request<T>) {
        let completionHandler: (_ getObject: () throws -> FetcherResult<T>) -> Void = { getFetcherResult in
            do {
                let result = try getFetcherResult()
                let rawObject = result.object
                Log.debug("\(descriptor.fetcher.identifier) fetched")
                
                if let _ = descriptor.processor {
                    self.process(rawObject: rawObject, withDescriptor: descriptor, request: request)
                    if self.moveOriginalToMemoryCache {
                        self.responseQueue.async {
                            self.memoryCache.set(object: rawObject, forKey: descriptor.key)
                        }
                    }
                    if self.moveOriginalToDiskCache {
                        self.persist(object: rawObject, data: result.data, key: descriptor.key)
                    }
                } else {
                    self.responseQueue.async {
                        request.complete(withObject: result.object)
                        self.memoryCache.set(object: result.object, forKey: descriptor.key)
//                        self.requestCache.setCached(request: nil, forIdentifier: descriptor.key)
                    }
                    self.persist(object: result.object, data: result.data, key: descriptor.key)
                }
                
            } catch {
                self.responseQueue.async { request.complete(withError: error) }
                self.requestCache.setCached(request: nil, forIdentifier: descriptor.key)
            }
            self.requestCache.setCached(fetching: nil, forIdentifier: descriptor.fetcher.identifier)
        }
        
        request.subrequest = requestCache.fetchingRequest(fetcher: descriptor.fetcher, completion: completionHandler)
    }
    
    @inline(__always)
    private func process(rawObject: T, withDescriptor descriptor: CachableDescriptor<T>, request: Request<T>) {
        guard let processor = descriptor.processor, let resultKey = descriptor.resultKey, !request.canceled else {
            return
        }
        processQueue.async {
            Log.debug("processing \(resultKey)")
            processor.process(object: rawObject, respondIn: self.responseQueue) { (getObject) in
                do {
                    let object = try getObject()
                    self.responseQueue.async {
                        request.complete(withObject: object)
                        self.memoryCache.set(object: object, forKey: resultKey)
                    }
                    self.persist(object: object, data: nil, key: resultKey)
                } catch {
                    request.complete(withError: error)
                }
                self.requestCache.setCached(request: nil, forIdentifier: resultKey)
            }
        }
    }
    
    @inline(__always)
    private func persist(object: T?, data: Data?, key: String) {
        diskWriteQueue.async {
            do {
                if let data = data {
                    try self.diskCache?.set(data: data, forKey: key)
                } else if let object = object {
                    try self.diskCache?.set(object: object, forKey: key)
                }
            } catch {
                Log.error(error)
            }
        }
    }
    
    // MARK: - Set
    
    open func set(_ object: T, forKey key: String, errorHandler: ((_ error: Error) -> Void)? = nil) {
        memoryCache.set(object: object, forKey: key)
        diskQueue.async(flags: .barrier, execute: {
            do {
                try self.diskCache?.set(object: object, forKey: key)
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
                try self.diskCache?.removeObject(forKey: key)
            } catch {
                self.responseQueue.async { errorHandler?(error) }
            }
        }) 
    }
    
    open func clear() {
        memoryCache.clear()
        diskQueue.async {
            self.diskCache?.clear()
        }
    }
    
    // MARK: -
    
    @objc func handleMemoryWarning(notification: Notification) {
        memoryCache.clear()
    }
    
    var description: String {
        let disk: String = diskCache?.identifier ?? "-"
        return "Cache<\(T.self)>(\(identifier)) disk cache: \(disk)"
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

public extension Cache where T: NSCoding {
    
    convenience public init(identifier: String, maxCapacity: Int = 0) throws {
        try self.init(identifier: identifier, serializer: DataSerializer<T>(), maxCapacity: maxCapacity)
    }
}
