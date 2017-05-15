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

private let processQueue = DispatchQueue(label: "com.allcache.ProcessQueue", attributes: .concurrent)

private let fetchQueue = DispatchQueue(label: "com.allcache.FetchQueue", attributes: [])
private let diskWriteQueue = DispatchQueue(label: "com.allcache.DiskWriteQueue", attributes: [])

public let Log = LoggerContainer(loggers: [ConsoleLogger(formatter: AllCacheFormatter(), level: .all)])

/// The Cache class is a generic container that stores key-value pairs, 
/// internally has a memory cache and a disk cache
open class Cache<T: AnyObject> {
    
    private var requestCache = RequestingCache<T>()
    
    open let memoryCache = MemoryCache<T>()
    open internal(set) var diskCache: DiskCache<T>!
    open let identifier: String
    open var responseQueue = DispatchQueue.main
    open var moveOriginalToMemoryCache = false
    open var moveOriginalToDiskCache = true
    open var saveRawData = true
    
    /// The designated initializer for a cache
    /// - parameter identifier: The identifier of the cache, is used to create a folder for the disk cache
    /// - parameter dataSerializer: The serializer that converts objects into Data and Data into objects
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
            Log.debug("-\(key) found in memory")
            return object
        }
        Log.debug("-\(key) NOT found in memory")
        
        if let object = try diskCache?.object(forKey: key) {
            Log.debug("-\(key) found in disk")
            memoryCache.set(object: object, forKey: key)
            diskQueue.async {
                self.diskCache?.updateLastAccess(ofKey: key)
            }
            return object
        }
        Log.debug("-\(key) NOT found in disk")
        return nil
    }
    
    /// Search an object in the caches, if not found, tries to fetch it.
    /// - parameter key: the key of the object to search
    /// - parameter fetcher: The fetcher try to fetch the object if is not currently in the cache
    /// - parameter completion: The clusure to call when the cache finds the object
    /// - returns: A request object
    open func object(forKey key: String, fetcher: ObjectFetcher<T>, completion: @escaping (_ getObject: () throws -> T) -> Void) -> Request<T> {
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
                try self.searchInDisk(forKey: key, request: request, fetcher: fetcher)
            } catch {
                self.responseQueue.async { request.complete(withError: error) }
            }
        }
        return request
    }
    
    private func searchInDisk(forKey key: String, request: Request<T>, fetcher: ObjectFetcher<T>) throws {
        if let object = try diskCache?.object(forKey: key) {
            Log.debug("\(key) found in disk")
            responseQueue.async {
                request.complete(withObject: object)
                self.memoryCache.set(object: object, forKey: key)
                self.requestCache.setCached(request: nil, forIdentifier: key)
            }
            diskCache?.updateLastAccess(ofKey: key)
        } else {
            Log.debug("\(key) NOT found in disk")
            if request.canceled {
                requestCache.setCached(request:nil, forIdentifier: key)
                return
            }
            
            let completionHandler: (_ getObject: () throws -> FetcherResult<T>) -> Void = { getFetcherResult in
                do {
                    let result = try getFetcherResult()
                    Log.debug("\(key) fetched")
                    self.responseQueue.async {
                        request.complete(withObject: result.object)
                        self.memoryCache.set(object: result.object, forKey: key)
                        self.requestCache.setCached(request: nil, forIdentifier: key)
                    }
                    if self.saveRawData, let data = result.data {
                        diskWriteQueue.async {
                            _ = try? self.diskCache.set(data: data, forKey: key)
                        }
                    } else {
                        diskWriteQueue.async {
                            _ = try? self.diskCache?.set(object: result.object, forKey: key)
                        }
                    }
                } catch {
                    self.responseQueue.async {
                        request.complete(withError: error)
                        self.requestCache.setCached(request: nil, forIdentifier: key)
                    }
                }
                self.requestCache.setCached(fetching: nil, forIdentifier: fetcher.identifier)
            }
            
            var fetcherRequest = requestCache.getCachedFetchingRequest(withIdentifier: fetcher.identifier)
            if let fetcherRequest = fetcherRequest {
                fetcherRequest.add(completionHandler: completionHandler)
            } else {
                let fetching = fetcher.fetchAndRespond(in: diskQueue, completion: completionHandler)
                self.requestCache.setCached(fetching: fetching, forIdentifier: fetcher.identifier)
                fetcherRequest = requestCache.getCachedFetchingRequest(withIdentifier: fetcher.identifier)
                request.subrequest = fetcherRequest
                if fetcherRequest == nil {
                    self.responseQueue.async { request.complete(withError: FetchError.notFound) }
                    requestCache.setCached(request: nil, forIdentifier: fetcher.identifier)
                }
            }
        }
    }
    
    /// Search an object in the caches, if the object is found the completion closure is called, if not, the cache search for the original object and apply the objectProcessor, if the origianl object wasn't found it uses the objectFetcher to try to get it.
    /// - parameter key: the key of the object to search
    /// - parameter originalKey: the key of the original object to search
    /// - parameter objectFetcher: The object that fetches the object if is not currently in the cache
    /// - parameter objectProcessor: The object that process the original object to obtain the final object
    /// - parameter completion: The clusure to call when the cache finds the object
    /// - returns: A request object
    func object(forKey key: String, originalKey: String, objectFetcher: ObjectFetcher<T>, objectProcessor: ObjectProcessor<T>, completion: @escaping (_ getObject: () throws -> T) -> Void) -> Request<T> {
        let descriptor = CachableDescriptorWrapper<T>(key: key, originalKey: originalKey, fetcher: objectFetcher, processor: objectProcessor)
        return object(for: descriptor, completion: completion)
    }
    
    /// Search an object in the caches, if the object is found the completion closure is called, if not, the cache search for the original object and apply the objectProcessor, if the origianl object wasn't found it uses the objectFetcher to try to get it.
    /// - parameter descriptor: An object that encapsulates the key, origianlKey, objectFetcher and objectProcessor
    /// - parameter completion: The clusure to call when the cache finds the object
    /// - returns: An optional request
    open func object(for descriptor: CachableDescriptor<T>, completion: @escaping (_ getObject: () throws -> T) -> Void) -> Request<T> {
        let (request, ongoing) = requestCache.request(forKey: descriptor.key, completion: completion)
        if ongoing { return request }
        
        //      MARK: - Search in Memory o'
        if let object = memoryCache.object(forKey: descriptor.key) {
            Log.debug("\(descriptor.key) found in memory")
            responseQueue.async { request.complete(withObject: object) }
            requestCache.setCached(request: nil, forIdentifier: descriptor.key)
            return request
        }
        Log.debug("\(descriptor.key) NOT found in memory")
        
//      MARK: - Search in Disk o'
        
        diskQueue.async {
            do {
                if let object = try self.diskCache?.object(forKey: descriptor.key) {
                    Log.debug("\(descriptor.key) found in disk")
                    self.responseQueue.async {
                        request.complete(withObject: object)
                        self.memoryCache.set(object: object, forKey: descriptor.key)
                        self.requestCache.setCached(request: nil, forIdentifier: descriptor.key)
                    }
                    self.diskCache?.updateLastAccess(ofKey: descriptor.key)
                    return
                }
            } catch {
                self.responseQueue.async {
                    request.complete(withError: error)
                }
                return
            }
            Log.debug("\(descriptor.key) NOT found in disk")
            if request.canceled {
                self.requestCache.setCached(request: nil, forIdentifier: descriptor.key)
                return
            }
            
//          MARK: - Search in Memory o
            
            self.responseQueue.async {
                if let rawObject = self.memoryCache.object(forKey: descriptor.originalKey) {
                    Log.debug("\(descriptor.originalKey) found in memory")
                    self.process(rawObject: rawObject, withDescriptor: descriptor, request: request)
                }
                else {
                    Log.debug("\(descriptor.originalKey) NOT found in memory")
                    if request.canceled {
                        self.requestCache.setCached(request: nil, forIdentifier: descriptor.key)
                        return
                    }
                    
//                  MARK: - Search in Disk o
                    diskQueue.async {
                        do {
                            try self.searchInDisk(for: descriptor, request: request)
                        } catch {
                            self.responseQueue.async { request.complete(withError: error) }
                        }
                    }
                }
            }
        }
        return request
    }
    
    private func searchInDisk(for descriptor: CachableDescriptor<T>, request: Request<T>) throws {
        if let rawObject = try diskCache?.object(forKey: descriptor.originalKey) {
            Log.debug("\(descriptor.originalKey) found in disk")
            process(rawObject: rawObject, withDescriptor: descriptor, request: request)
            if moveOriginalToMemoryCache {
                responseQueue.async {
                    self.memoryCache.set(object: rawObject, forKey: descriptor.originalKey)
                }
            }
            diskCache?.updateLastAccess(ofKey: descriptor.originalKey)
        }
        else {
            Log.debug("\(descriptor.originalKey) NOT found in disk")
            
            if request.canceled {
                requestCache.setCached(request: nil, forIdentifier: descriptor.key)
                return
            }
            fetchObject(for: descriptor, request: request)
        }
    }
    
    private func fetchObject(for descriptor: CachableDescriptor<T>, request: Request<T>) {
        let completionHandler: (_ getObject: () throws -> FetcherResult<T>) -> Void = { getFetcherResult in
            do {
                let result = try getFetcherResult()
                let rawObject = result.object
                Log.debug("\(descriptor.originalKey) fetched")
                
                self.process(rawObject: rawObject, withDescriptor: descriptor, request: request)
                if self.moveOriginalToMemoryCache {
                    self.responseQueue.async {
                        self.memoryCache.set(object: rawObject, forKey: descriptor.originalKey)
                    }
                }
                if self.moveOriginalToDiskCache {
                    if self.saveRawData, let data = result.data {
                        diskWriteQueue.async {
                            _ = try? self.diskCache?.set(data: data, forKey: descriptor.originalKey)
                        }
                    } else {
                        diskWriteQueue.async {
                            _ = try? self.diskCache?.set(object: rawObject, forKey: descriptor.originalKey)
                        }
                    }
                }
            } catch {
                self.responseQueue.async { request.complete(withError: error) }
                self.requestCache.setCached(request: nil, forIdentifier: descriptor.key)
            }
            self.requestCache.setCached(fetching: nil, forIdentifier: descriptor.originalKey)
        }
        
        var fetcherRequest = requestCache.getCachedFetchingRequest(withIdentifier: descriptor.originalKey)
        if let fetcherRequest = fetcherRequest {
            fetcherRequest.add(completionHandler: completionHandler)
        } else {
            let fetching = descriptor.fetchAndRespond(in: diskQueue, completion: completionHandler)
            self.requestCache.setCached(fetching: fetching, forIdentifier: descriptor.originalKey)
            fetcherRequest = self.requestCache.getCachedFetchingRequest(withIdentifier: descriptor.originalKey)
            request.subrequest = fetcherRequest
            if fetcherRequest == nil {
                self.responseQueue.async { request.complete(withError: FetchError.notFound) }
                requestCache.setCached(request: nil, forIdentifier: descriptor.key)
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
                self.responseQueue.async {
                    errorHandler?(error)
                }
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
                self.responseQueue.async {
                    errorHandler?(error)
                }
            }
        }) 
    }
    
    open func clear() {
        memoryCache.clear()
        diskQueue.async {
            self.diskCache.clear()
        }
    }
    
    private func process(rawObject: T, withDescriptor descriptor: CachableDescriptor<T>, request: Request<T>) {
        if request.canceled { return }
        processQueue.async {
            Log.debug("processing \(descriptor.key)")
            descriptor.process(object: rawObject, respondIn: self.responseQueue) { (getObject) in
                do {
                    let object = try getObject()
                    request.complete(withObject: object)
                    self.memoryCache.set(object: object, forKey: descriptor.key)
                    diskQueue.async {
                        do {
                            _ = try self.diskCache?.set(object: object, forKey: descriptor.key)
                        } catch {
                            Log.error(error)
                        }
                    }
                } catch {
                    request.complete(withError: error)
                }
                self.requestCache.setCached(request: nil, forIdentifier: descriptor.key)
            }
        }
    }
    
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
