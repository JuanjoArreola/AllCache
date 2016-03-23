//
//  Cache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

internal let diskQueue: dispatch_queue_t = dispatch_queue_create("com.allcache.DiskQueue", DISPATCH_QUEUE_CONCURRENT)
private let fetchQueue: dispatch_queue_t = dispatch_queue_create("com.allcache.FetchQueue", DISPATCH_QUEUE_SERIAL)
private let processQueue: dispatch_queue_t = dispatch_queue_create("com.allcache.ProcessQueue", DISPATCH_QUEUE_CONCURRENT)
internal let syncQueue: dispatch_queue_t = dispatch_queue_create("com.allcache.SyncQueue", DISPATCH_QUEUE_CONCURRENT)

/// The Cache class is a generic container that stores key-value pairs, internally has a memory cache and a disk cache
public class Cache<T: AnyObject> {
    
    private var fetching: [String: Request<T>] = [:]
    private var requesting: [String: Request<T>] = [:]
    
    public let memoryCache = MemoryCache<T>()
    public internal(set) var diskCache: DiskCache<T>!
    public let identifier: String
    public var responseQueue = dispatch_get_main_queue()
    public var moveOriginalToMemoryCache = false
    public var moveOriginalToDiskCache = true
    
    /// The designated initializer for a cache
    /// - parameter identifier: The identifier of the cache, is used to create a folder for the disk cache
    /// - parameter dataSerializer: The serializer that converts objects into NSData en NSData into objects
    /// - parameter maxCapacity: The maximum size of the disk cache in bytes. This is only a hint
    required public init(identifier: String, dataSerializer: DataSerializer<T>, maxCapacity: Int = 0) throws {
        self.identifier = identifier
        self.diskCache = try! DiskCache<T>(identifier: identifier, dataSerializer: dataSerializer, maxCapacity: maxCapacity)
    }
    
    /// Search an object in the caches, if the object is found the completion closure is called, if not it uses the objectFetcher to try to get it.
    /// - parameter key: the key of the object to search
    /// - parameter objectFetcher: The object that fetches the object if is not currently in the cache
    /// - parameter completion: The clusure to call when the cache finds the object
    /// - returns: An optional request
    public func objectForKey(key: String, objectFetcher: ObjectFetcher<T>, completion: (getObject: () throws -> T) -> Void) -> Request<T>? {
        if let request = requesting[key] {
            request.addCompletionHandler(completion)
            return request
        }
        dispatch_barrier_async(syncQueue) {
            self.requesting[key] = Request(completionHandler: completion)
        }
        let request = getCachedRequestWithIdentifier(key)!
        
        if let object = memoryCache.objectForKey(key) {
            Log.debug("\(key) found in memory")
            request.completeWithObject(object)
            return nil
        }
        Log.debug("\(key) NOT found in memory")
        
        dispatch_async(diskQueue) {
            if let object = self.diskCache?.objectForKey(key) {
                Log.debug("\(key) found in disk")
                dispatch_async(self.responseQueue) {
                    request.completeWithObject(object)
                    self.memoryCache.setObject(object, forKey: key)
                }
                self.diskCache?.updateLastAccessOfKey(key)
            } else {
                Log.debug("\(key) NOT found in disk")
                if request.canceled { return }
                
                let completionHandler: (getObject: () throws -> T) -> Void = {getObject in
                    do {
                        let object = try getObject()
                        Log.debug("\(key) fetched")
                        dispatch_async(self.responseQueue) {
                            request.completeWithObject(object)
                            self.memoryCache.setObject(object, forKey: key)
                        }
                        _ = try? self.diskCache?.setObject(object, forKey: key)
                    } catch {
                        dispatch_async(self.responseQueue) {
                            request.completeWithError(error)
                        }
                    }
                    dispatch_barrier_async(syncQueue) {
                        self.fetching[objectFetcher.identifier] = nil
                    }
                }
                
                var fetcherRequest = self.getCachedFetchingRequestWithIdentifier(objectFetcher.identifier)
                if let fetcherRequest = fetcherRequest {
                    fetcherRequest.addCompletionHandler(completionHandler)
                } else {
                    dispatch_barrier_async(syncQueue) {
                        self.fetching[objectFetcher.identifier] = objectFetcher.fetchAndRespondInQueue(diskQueue, completion: completionHandler)
                    }
                    fetcherRequest = self.getCachedFetchingRequestWithIdentifier(objectFetcher.identifier)
                    if fetcherRequest == nil {
                        request.completeWithError(FetchError.NotFound)
                    }
                }
            }
        }
        return request
    }
    
    private func getCachedFetchingRequestWithIdentifier(identifier: String) -> Request<T>? {
        var request: Request<T>?
        dispatch_sync(syncQueue) {
            request = self.fetching[identifier]
        }
        return request
    }
    
    private func getCachedRequestWithIdentifier(identifier: String) -> Request<T>? {
        var request: Request<T>?
        dispatch_sync(syncQueue) {
            request = self.requesting[identifier]
        }
        return request
    }
    
    /// Search an object in the caches, if the object is found the completion closure is called, if not, the cache search for the original object and apply the objectProcessor, if the origianl object wasn't found it uses the objectFetcher to try to get it.
    /// - parameter key: the key of the object to search
    /// - parameter originalKey: the key of the original object to search
    /// - parameter objectFetcher: The object that fetches the object if is not currently in the cache
    /// - parameter objectProcessor: The object that process the original object to obtain the final object
    /// - parameter completion: The clusure to call when the cache finds the object
    /// - returns: An optional request
    func objectForKey(key: String, originalKey: String, objectFetcher: ObjectFetcher<T>, objectProcessor: ObjectProcessor<T>, completion: (getObject: () throws -> T) -> Void) -> Request<T>? {
        let descriptor = CachableDescriptorWrapper<T>(key: key, originalKey: originalKey, objectFetcher: objectFetcher, objectProcessor: objectProcessor)
        return objectForDescriptor(descriptor, completion: completion)
    }
    
    /// Search an object in the caches, if the object is found the completion closure is called, if not, the cache search for the original object and apply the objectProcessor, if the origianl object wasn't found it uses the objectFetcher to try to get it.
    /// - parameter descriptor: An object that encapsulates the key, origianlKey, objectFetcher and objectProcessor
    /// - parameter completion: The clusure to call when the cache finds the object
    /// - returns: An optional request
    func objectForDescriptor(descriptor: CachableDescriptor<T>, completion: (getObject: () throws -> T) -> Void) -> Request<T>? {
        
        //      MARK: - Search in Memory o'
        if let object = memoryCache.objectForKey(descriptor.key) {
            Log.debug("\(descriptor.key) found in memory")
            completion(getObject: { return object })
            return nil
        }
        Log.debug("\(descriptor.key) NOT found in memory")
        
        //      MARK: - Search in Disk o'
        let request = Request(completionHandler: completion)
        dispatch_async(diskQueue) {
            if let object = self.diskCache?.objectForKey(descriptor.key) {
                Log.debug("\(descriptor.key) found in disk")
                dispatch_async(self.responseQueue) {
                    request.completeWithObject(object)
                    self.memoryCache.setObject(object, forKey: descriptor.key)
                }
                self.diskCache?.updateLastAccessOfKey(descriptor.key)
                return
            }
            Log.debug("\(descriptor.key) NOT found in disk")
            if request.canceled { return }
            
            //          MARK: - Search in Memory o
            dispatch_async(self.responseQueue) {
                if let rawObject = self.memoryCache.objectForKey(descriptor.originalKey) {
                    Log.debug("\(descriptor.originalKey) found in memory")
                    self.processRawObject(rawObject, withDescriptor: descriptor, request: request)
                }
                else {
                    Log.debug("\(descriptor.originalKey) NOT found in memory")
                    if request.canceled { return }
                    
//                  MARK: - Search in Disk o
                    dispatch_async(diskQueue) {
                        if let rawObject = self.diskCache?.objectForKey(descriptor.originalKey) {
                            Log.debug("\(descriptor.originalKey) found in memory")
                            self.processRawObject(rawObject, withDescriptor: descriptor, request: request)
                            if self.moveOriginalToMemoryCache {
                                dispatch_async(self.responseQueue) {
                                    self.memoryCache.setObject(rawObject, forKey: descriptor.originalKey)
                                }
                            }
                            self.diskCache?.updateLastAccessOfKey(descriptor.originalKey)
                        }
                        else {
                            Log.debug("\(descriptor.originalKey) NOT found in disk")
                            
                            if request.canceled { return }
                            
                            let completionHandler: (getObject: () throws -> T) -> Void = {getObject in
                                do {
                                    let rawObject = try getObject()
                                    Log.debug("\(descriptor.originalKey) fetched")
                                    
                                    self.processRawObject(rawObject, withDescriptor: descriptor, request: request)
                                    if self.moveOriginalToMemoryCache {
                                        dispatch_async(self.responseQueue) {
                                            self.memoryCache.setObject(rawObject, forKey: descriptor.originalKey)
                                        }
                                    }
                                    if self.moveOriginalToDiskCache {
                                        _ = try? self.diskCache?.setObject(rawObject, forKey: descriptor.originalKey)
                                    }
                                } catch {
                                    dispatch_async(self.responseQueue) {
                                        request.completeWithError(error)
                                    }
                                }
                                dispatch_barrier_async(syncQueue) {
                                    self.fetching[descriptor.originalKey] = nil
                                }
                            }
                            
//                          MARK: - Fetch Object
                            var fetcherRequest = self.getCachedFetchingRequestWithIdentifier(descriptor.originalKey)
                            if let fetcherRequest = fetcherRequest {
                                fetcherRequest.addCompletionHandler(completionHandler)
                            } else {
                                dispatch_barrier_async(syncQueue) {
                                    self.fetching[descriptor.originalKey] = descriptor.fetchAndRespondInQueue(diskQueue, completion: completionHandler)
                                }
                                fetcherRequest = self.getCachedFetchingRequestWithIdentifier(descriptor.originalKey)
                                request.subrequest = fetcherRequest
                                if fetcherRequest == nil {
                                    request.completeWithError(FetchError.NotFound)
                                }
                            }
                        }
                    }
                }
            }
        }
        return request
    }
    
    public func setObject(object: T, forKey key: String, errorHandler: ((error: ErrorType) -> Void)? = nil) {
        memoryCache.setObject(object, forKey: key)
        dispatch_barrier_async(diskQueue) {
            do {
                try self.diskCache.setObject(object, forKey: key)
            } catch {
                dispatch_async(self.responseQueue) {
                    errorHandler?(error: error)
                }
            }
        }
    }
    
    public func removeObjectForKey(key: String, errorHandler: ((error: ErrorType) -> Void)? = nil) {
        memoryCache.removeObjectForKey(key)
        dispatch_barrier_async(diskQueue) {
            do {
                try self.diskCache.removeObjectForKey(key)
            } catch {
                dispatch_async(self.responseQueue) {
                    errorHandler?(error: error)
                }
            }
        }
    }
    
    public func clear() {
        memoryCache.clear()
        dispatch_async(diskQueue) {
            self.diskCache.clear()
        }
    }
    
    private func processRawObject(rawObject: T, withDescriptor descriptor: CachableDescriptor<T>, request: Request<T>) {
        if request.canceled { return }
        dispatch_async(processQueue) {
            Log.debug("processing \(descriptor.originalKey)")
            descriptor.processObject(rawObject, respondInQueue: self.responseQueue) { (getObject) in
                do {
                    let object = try getObject()
                    request.completeWithObject(object)
                    self.memoryCache.setObject(object, forKey: descriptor.key)
                    dispatch_async(diskQueue) {
                        _ = try? self.diskCache?.setObject(object, forKey: descriptor.key)
                    }
                } catch {
                    request.completeWithError(error)
                }
            }
        }
    }
    
    var description: String {
        let disk: String = diskCache?.identifier ?? "-"
        return "Cache<\(T.self)>(\(identifier)) disk cache: \(disk)"
    }
    
}