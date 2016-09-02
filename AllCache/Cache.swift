//
//  Cache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

internal let diskQueue: DispatchQueue = DispatchQueue(label: "com.allcache.DiskQueue", attributes: DispatchQueue.Attributes.concurrent)
private let processQueue: DispatchQueue = DispatchQueue(label: "com.allcache.ProcessQueue", attributes: DispatchQueue.Attributes.concurrent)
internal let syncQueue: DispatchQueue = DispatchQueue(label: "com.allcache.SyncQueue", attributes: DispatchQueue.Attributes.concurrent)

private let fetchQueue: DispatchQueue = DispatchQueue(label: "com.allcache.FetchQueue", attributes: [])
private let diskWriteQueue: DispatchQueue = DispatchQueue(label: "com.allcache.DiskWriteQueue", attributes: [])

/// The Cache class is a generic container that stores key-value pairs, internally has a memory cache and a disk cache
open class Cache<T: AnyObject> {
    
    fileprivate var fetching: [String: Request<FetcherResult<T>>] = [:]
    fileprivate var requesting: [String: Request<T>] = [:]
    
    open let memoryCache = MemoryCache<T>()
    open internal(set) var diskCache: DiskCache<T>!
    open let identifier: String
    open var responseQueue = DispatchQueue.main
    open var moveOriginalToMemoryCache = false
    open var moveOriginalToDiskCache = true
    open var saveRawData = true
    
    /// The designated initializer for a cache
    /// - parameter identifier: The identifier of the cache, is used to create a folder for the disk cache
    /// - parameter dataSerializer: The serializer that converts objects into NSData en NSData into objects
    /// - parameter maxCapacity: The maximum size of the disk cache in bytes. This is only a hint
    required public init(identifier: String, dataSerializer: DataSerializer<T>, maxCapacity: Int = 0) throws {
        self.identifier = identifier
        self.diskCache = try! DiskCache<T>(identifier: identifier, dataSerializer: dataSerializer, maxCapacity: maxCapacity)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleMemoryWarningNotification(_:)), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    open func objectForKey(_ key: String) -> T? {
        if let object = memoryCache.objectForKey(key) {
            Log.debug("-\(key) found in memory")
            return object
        }
        Log.debug("-\(key) NOT found in memory")
        
        if let object = self.diskCache?.objectForKey(key) {
            Log.debug("-\(key) found in disk")
            memoryCache.setObject(object, forKey: key)
            diskQueue.async {
                self.diskCache?.updateLastAccessOfKey(key)
            }
            return object
        }
        Log.debug("-\(key) NOT found in disk")
        return nil
    }
    
    /// Search an object in the caches, if the object is found the completion closure is called, if not it uses the objectFetcher to try to get it.
    /// - parameter key: the key of the object to search
    /// - parameter objectFetcher: The object that fetches the object if is not currently in the cache
    /// - parameter completion: The clusure to call when the cache finds the object
    /// - returns: An optional request
    open func objectForKey(_ key: String, objectFetcher: ObjectFetcher<T>, completion: (_ getObject: () throws -> T) -> Void) -> Request<T>? {
        if let request = getCachedRequestWithIdentifier(key) {
            if request.canceled {
                setCachedRequest(nil, forIdentifier: key)
            } else {
                request.addCompletionHandler(completion)
                return request
            }
        }
        setCachedRequest(Request(completionHandler: completion), forIdentifier: key)
        let request = getCachedRequestWithIdentifier(key)!
        
        if let object = memoryCache.objectForKey(key) {
            Log.debug("\(key) found in memory")
            request.completeWithObject(object)
            setCachedRequest(nil, forIdentifier: key)
            return request
        }
        Log.debug("\(key) NOT found in memory")
        
        diskQueue.async {
            if let object = self.diskCache?.objectForKey(key) {
                Log.debug("\(key) found in disk")
                self.responseQueue.async {
                    request.completeWithObject(object)
                    self.memoryCache.setObject(object, forKey: key)
                    self.setCachedRequest(nil, forIdentifier: key)
                }
                self.diskCache?.updateLastAccessOfKey(key)
            } else {
                Log.debug("\(key) NOT found in disk")
                if request.canceled {
                    self.setCachedRequest(nil, forIdentifier: key)
                    return
                }
                
                let completionHandler: (_ getObject: () throws -> FetcherResult<T>) -> Void = { getFetcherResult in
                    do {
                        let result = try getFetcherResult()
                        Log.debug("\(key) fetched")
                        self.responseQueue.async {
                            request.completeWithObject(result.object)
                            self.memoryCache.setObject(result.object, forKey: key)
                            self.setCachedRequest(nil, forIdentifier: key)
                        }
                        if self.saveRawData, let data = result.data {
                            _ = try? self.diskCache.setData(data, forKey: key)
                        } else {
                            _ = try? self.diskCache?.setObject(result.object, forKey: key)
                        }
                    } catch {
                        self.responseQueue.async {
                            request.completeWithError(error)
                            self.setCachedRequest(nil, forIdentifier: key)
                        }
                    }
                    syncQueue.async(flags: .barrier, execute: {
                        self.fetching[objectFetcher.identifier] = nil
                    }) 
                }
                
                var fetcherRequest = self.getCachedFetchingRequestWithIdentifier(objectFetcher.identifier)
                if let fetcherRequest = fetcherRequest {
                    fetcherRequest.addCompletionHandler(completionHandler)
                } else {
                    syncQueue.async(flags: .barrier, execute: {
                        self.fetching[objectFetcher.identifier] = objectFetcher.fetchAndRespondInQueue(diskQueue, completion: completionHandler)
                    }) 
                    fetcherRequest = self.getCachedFetchingRequestWithIdentifier(objectFetcher.identifier)
                    if fetcherRequest == nil {
                        request.completeWithError(FetchError.notFound)
                    }
                }
            }
        }
        return request
    }
    
    @inline(__always) fileprivate func getCachedFetchingRequestWithIdentifier(_ identifier: String) -> Request<FetcherResult<T>>? {
        var request: Request<FetcherResult<T>>?
        syncQueue.sync {
            request = self.fetching[identifier]
        }
        return request
    }
    
    @inline(__always) fileprivate func getCachedRequestWithIdentifier(_ identifier: String) -> Request<T>? {
        var request: Request<T>?
        syncQueue.sync {
            request = self.requesting[identifier]
        }
        return request
    }
    
    @inline(__always) fileprivate func setCachedRequest(_ request: Request<T>?, forIdentifier identifier: String) {
        syncQueue.async(flags: .barrier, execute: {
            self.requesting[identifier] = request
        }) 
    }
    
    /// Search an object in the caches, if the object is found the completion closure is called, if not, the cache search for the original object and apply the objectProcessor, if the origianl object wasn't found it uses the objectFetcher to try to get it.
    /// - parameter key: the key of the object to search
    /// - parameter originalKey: the key of the original object to search
    /// - parameter objectFetcher: The object that fetches the object if is not currently in the cache
    /// - parameter objectProcessor: The object that process the original object to obtain the final object
    /// - parameter completion: The clusure to call when the cache finds the object
    /// - returns: An optional request
    func objectForKey(_ key: String, originalKey: String, objectFetcher: ObjectFetcher<T>, objectProcessor: ObjectProcessor<T>, completion: (_ getObject: () throws -> T) -> Void) -> Request<T>? {
        let descriptor = CachableDescriptorWrapper<T>(key: key, originalKey: originalKey, objectFetcher: objectFetcher, objectProcessor: objectProcessor)
        return objectForDescriptor(descriptor, completion: completion)
    }
    
    /// Search an object in the caches, if the object is found the completion closure is called, if not, the cache search for the original object and apply the objectProcessor, if the origianl object wasn't found it uses the objectFetcher to try to get it.
    /// - parameter descriptor: An object that encapsulates the key, origianlKey, objectFetcher and objectProcessor
    /// - parameter completion: The clusure to call when the cache finds the object
    /// - returns: An optional request
    open func objectForDescriptor(_ descriptor: CachableDescriptor<T>, completion: (_ getObject: () throws -> T) -> Void) -> Request<T>? {
        if let request = getCachedRequestWithIdentifier(descriptor.key) {
            if request.canceled {
                setCachedRequest(nil, forIdentifier: descriptor.key)
            } else {
                request.addCompletionHandler(completion)
                return request
            }
        }
        setCachedRequest(Request(completionHandler: completion), forIdentifier: descriptor.key)
        let request = getCachedRequestWithIdentifier(descriptor.key)!
        
        //      MARK: - Search in Memory o'
        if let object = memoryCache.objectForKey(descriptor.key) {
            Log.debug("\(descriptor.key) found in memory")
            request.completeWithObject(object)
            return request
        }
        Log.debug("\(descriptor.key) NOT found in memory")
        
        //      MARK: - Search in Disk o'
        diskQueue.async {
            if let object = self.diskCache?.objectForKey(descriptor.key) {
                Log.debug("\(descriptor.key) found in disk")
                self.responseQueue.async {
                    request.completeWithObject(object)
                    self.memoryCache.setObject(object, forKey: descriptor.key)
                    self.setCachedRequest(nil, forIdentifier: descriptor.key)
                }
                self.diskCache?.updateLastAccessOfKey(descriptor.key)
                return
            }
            Log.debug("\(descriptor.key) NOT found in disk")
            if request.canceled {
                self.setCachedRequest(nil, forIdentifier: descriptor.key)
                return
            }
            
            //          MARK: - Search in Memory o
            self.responseQueue.async {
                if let rawObject = self.memoryCache.objectForKey(descriptor.originalKey) {
                    Log.debug("\(descriptor.originalKey) found in memory")
                    self.processRawObject(rawObject, withDescriptor: descriptor, request: request)
                }
                else {
                    Log.debug("\(descriptor.originalKey) NOT found in memory")
                    if request.canceled {
                        self.setCachedRequest(nil, forIdentifier: descriptor.key)
                        return
                    }
                    
//                  MARK: - Search in Disk o
                    diskQueue.async {
                        if let rawObject = self.diskCache?.objectForKey(descriptor.originalKey) {
                            Log.debug("\(descriptor.originalKey) found in disk")
                            self.processRawObject(rawObject, withDescriptor: descriptor, request: request)
                            if self.moveOriginalToMemoryCache {
                                self.responseQueue.async {
                                    self.memoryCache.setObject(rawObject, forKey: descriptor.originalKey)
                                }
                            }
                            self.diskCache?.updateLastAccessOfKey(descriptor.originalKey)
                        }
                        else {
                            Log.debug("\(descriptor.originalKey) NOT found in disk")
                            
                            if request.canceled {
                                self.setCachedRequest(nil, forIdentifier: descriptor.key)
                                return
                            }
                            
                            let completionHandler: (_ getObject: () throws -> FetcherResult<T>) -> Void = { getFetcherResult in
                                do {
                                    let result = try getFetcherResult()
                                    let rawObject = result.object
                                    Log.debug("\(descriptor.originalKey) fetched")
                                    
                                    self.processRawObject(rawObject, withDescriptor: descriptor, request: request)
                                    if self.moveOriginalToMemoryCache {
                                        self.responseQueue.async {
                                            self.memoryCache.setObject(rawObject, forKey: descriptor.originalKey)
                                        }
                                    }
                                    if self.moveOriginalToDiskCache {
                                        if self.saveRawData, let data = result.data {
                                            diskWriteQueue.async {
                                                _ = try? self.diskCache?.setData(data, forKey: descriptor.originalKey)
                                            }
                                        } else {
                                            diskWriteQueue.async {
                                                _ = try? self.diskCache?.setObject(rawObject, forKey: descriptor.originalKey)
                                            }
                                        }
                                    }
                                } catch {
                                    self.responseQueue.async {
                                        request.completeWithError(error)
                                        self.setCachedRequest(nil, forIdentifier: descriptor.key)
                                    }
                                }
                                syncQueue.async(flags: .barrier, execute: {
                                    self.fetching[descriptor.originalKey] = nil
                                }) 
                            }
                            
//                          MARK: - Fetch Object
                            var fetcherRequest = self.getCachedFetchingRequestWithIdentifier(descriptor.originalKey)
                            if let fetcherRequest = fetcherRequest {
                                fetcherRequest.addCompletionHandler(completionHandler)
                            } else {
                                syncQueue.async(flags: .barrier, execute: {
                                    self.fetching[descriptor.originalKey] = descriptor.fetchAndRespondInQueue(diskQueue, completion: completionHandler)
                                }) 
                                fetcherRequest = self.getCachedFetchingRequestWithIdentifier(descriptor.originalKey)
                                request.subrequest = fetcherRequest
                                if fetcherRequest == nil {
                                    request.completeWithError(FetchError.notFound)
                                    self.setCachedRequest(nil, forIdentifier: descriptor.key)
                                }
                            }
                        }
                    }
                }
            }
        }
        return request
    }
    
    open func setObject(_ object: T, forKey key: String, errorHandler: ((_ error: Error) -> Void)? = nil) {
        memoryCache.setObject(object, forKey: key)
        diskQueue.async(flags: .barrier, execute: {
            do {
                try self.diskCache.setObject(object, forKey: key)
            } catch {
                self.responseQueue.async {
                    errorHandler?(error)
                }
            }
        }) 
    }
    
    open func removeObjectForKey(_ key: String, errorHandler: ((_ error: Error) -> Void)? = nil) {
        memoryCache.removeObjectForKey(key)
        diskQueue.async(flags: .barrier, execute: {
            do {
                try self.diskCache.removeObjectForKey(key)
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
    
    fileprivate func processRawObject(_ rawObject: T, withDescriptor descriptor: CachableDescriptor<T>, request: Request<T>) {
        if request.canceled { return }
        processQueue.async {
            Log.debug("processing \(descriptor.key)")
            descriptor.processObject(rawObject, respondInQueue: self.responseQueue) { (getObject) in
                do {
                    let object = try getObject()
                    request.completeWithObject(object)
                    self.memoryCache.setObject(object, forKey: descriptor.key)
                    diskQueue.async {
                        _ = try? self.diskCache?.setObject(object, forKey: descriptor.key)
                    }
                } catch {
                    request.completeWithError(error)
                }
                self.setCachedRequest(nil, forIdentifier: descriptor.key)
            }
        }
    }
    
    @objc func handleMemoryWarningNotification(_ notification: Notification) {
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
