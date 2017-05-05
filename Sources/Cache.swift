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
internal let syncQueue = DispatchQueue(label: "com.allcache.SyncQueue", attributes: .concurrent)

private let processQueue = DispatchQueue(label: "com.allcache.ProcessQueue", attributes: .concurrent)

private let fetchQueue = DispatchQueue(label: "com.allcache.FetchQueue", attributes: [])
private let diskWriteQueue = DispatchQueue(label: "com.allcache.DiskWriteQueue", attributes: [])

public let Log = LoggerContainer(loggers: [ConsoleLogger(formatter: AllCacheFormatter(), level: .all)])

/// The Cache class is a generic container that stores key-value pairs, 
/// internally has a memory cache and a disk cache
open class Cache<T: AnyObject> {
    
    private var fetching: [String: Request<FetcherResult<T>>] = [:]
    private var requesting: [String: Request<T>] = [:]
    
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
    required public init(identifier: String, serializer: DataSerializer<T>, maxCapacity: Int = 0) throws {
        self.identifier = identifier
        self.diskCache = try! DiskCache<T>(identifier: identifier, serializer: serializer, maxCapacity: maxCapacity)
        registerForLowMemoryNotification()
    }
    
    // MARK: - Configuration
    
    #if os(iOS)
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
    open func object(forKey key: String) -> T? {
        if let object = memoryCache.object(forKey: key) {
            Log.debug("-\(key) found in memory")
            return object
        }
        Log.debug("-\(key) NOT found in memory")
        
        if let object = diskCache?.object(forKey: key) {
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
        if let request = getCachedRequest(withIdentifier: key) {
            if request.canceled {
                setCached(request: nil, forIdentifier: key)
            } else {
                request.add(completionHandler: completion)
                return request
            }
        }
        setCached(request: Request(completionHandler: completion), forIdentifier: key)
        let request = getCachedRequest(withIdentifier: key)!
        
        if let object = memoryCache.object(forKey: key) {
            Log.debug("\(key) found in memory")
            responseQueue.async { request.complete(withObject: object) }
            setCached(request: nil, forIdentifier: key)
            return request
        }
        Log.debug("\(key) NOT found in memory")
        
        diskQueue.async {
            self.searchInDisk(forKey: key, request: request, fetcher: fetcher)
        }
        return request
    }
    
    private func searchInDisk(forKey key: String, request: Request<T>, fetcher: ObjectFetcher<T>) {
        if let object = diskCache?.object(forKey: key) {
            Log.debug("\(key) found in disk")
            responseQueue.async {
                request.complete(withObject: object)
                self.memoryCache.set(object: object, forKey: key)
                self.setCached(request: nil, forIdentifier: key)
            }
            diskCache?.updateLastAccess(ofKey: key)
        } else {
            Log.debug("\(key) NOT found in disk")
            if request.canceled {
                setCached(request:nil, forIdentifier: key)
                return
            }
            
            let completionHandler: (_ getObject: () throws -> FetcherResult<T>) -> Void = { getFetcherResult in
                do {
                    let result = try getFetcherResult()
                    Log.debug("\(key) fetched")
                    self.responseQueue.async {
                        request.complete(withObject: result.object)
                        self.memoryCache.set(object: result.object, forKey: key)
                        self.setCached(request: nil, forIdentifier: key)
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
                        self.setCached(request: nil, forIdentifier: key)
                    }
                }
                syncQueue.async(flags: .barrier, execute: {
                    self.fetching[fetcher.identifier] = nil
                })
            }
            
            var fetcherRequest = getCachedFetchingRequest(withIdentifier: fetcher.identifier)
            if let fetcherRequest = fetcherRequest {
                fetcherRequest.add(completionHandler: completionHandler)
            } else {
                syncQueue.async(flags: .barrier, execute: {
                    self.fetching[fetcher.identifier] = fetcher.fetchAndRespond(in: diskQueue, completion: completionHandler)
                })
                fetcherRequest = getCachedFetchingRequest(withIdentifier: fetcher.identifier)
                request.subrequest = fetcherRequest
                if fetcherRequest == nil {
                    request.complete(withError: FetchError.notFound)
                    setCached(request: nil, forIdentifier: fetcher.identifier)
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
        if let request = getCachedRequest(withIdentifier: descriptor.key) {
            if request.canceled {
                setCached(request: nil, forIdentifier: descriptor.key)
            } else {
                request.add(completionHandler: completion)
                return request
            }
        }
        setCached(request: Request(completionHandler: completion), forIdentifier: descriptor.key)
        let request = getCachedRequest(withIdentifier: descriptor.key)!
        
        //      MARK: - Search in Memory o'
        if let object = memoryCache.object(forKey: descriptor.key) {
            Log.debug("\(descriptor.key) found in memory")
            responseQueue.async { request.complete(withObject: object) }
            setCached(request: nil, forIdentifier: descriptor.key)
            return request
        }
        Log.debug("\(descriptor.key) NOT found in memory")
        
//      MARK: - Search in Disk o'
        
        diskQueue.async {
            if let object = self.diskCache?.object(forKey: descriptor.key) {
                Log.debug("\(descriptor.key) found in disk")
                self.responseQueue.async {
                    request.complete(withObject: object)
                    self.memoryCache.set(object: object, forKey: descriptor.key)
                    self.setCached(request: nil, forIdentifier: descriptor.key)
                }
                self.diskCache?.updateLastAccess(ofKey: descriptor.key)
                return
            }
            Log.debug("\(descriptor.key) NOT found in disk")
            if request.canceled {
                self.setCached(request: nil, forIdentifier: descriptor.key)
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
                        self.setCached(request: nil, forIdentifier: descriptor.key)
                        return
                    }
                    
//                  MARK: - Search in Disk o
                    diskQueue.async {
                        self.searchInDisk(for: descriptor, request: request)
                    }
                }
            }
        }
        return request
    }
    
    private func searchInDisk(for descriptor: CachableDescriptor<T>, request: Request<T>) {
        if let rawObject = diskCache?.object(forKey: descriptor.originalKey) {
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
                setCached(request: nil, forIdentifier: descriptor.key)
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
                self.responseQueue.async {
                    request.complete(withError: error)
                    self.setCached(request: nil, forIdentifier: descriptor.key)
                }
            }
            syncQueue.async(flags: .barrier, execute: {
                self.fetching[descriptor.originalKey] = nil
            })
        }
        
        var fetcherRequest = getCachedFetchingRequest(withIdentifier: descriptor.originalKey)
        if let fetcherRequest = fetcherRequest {
            fetcherRequest.add(completionHandler: completionHandler)
        } else {
            syncQueue.async(flags: .barrier, execute: {
                self.fetching[descriptor.originalKey] = descriptor.fetchAndRespond(in: diskQueue, completion: completionHandler)
            })
            fetcherRequest = self.getCachedFetchingRequest(withIdentifier: descriptor.originalKey)
            request.subrequest = fetcherRequest
            if fetcherRequest == nil {
                request.complete(withError: FetchError.notFound)
                setCached(request: nil, forIdentifier: descriptor.key)
            }
        }
    }
    
    // MARK: - Request caching
    
    @inline(__always) private func getCachedFetchingRequest(withIdentifier identifier: String) -> Request<FetcherResult<T>>? {
        var request: Request<FetcherResult<T>>?
        syncQueue.sync {
            request = self.fetching[identifier]
        }
        return request
    }
    
    @inline(__always) fileprivate func getCachedRequest(withIdentifier identifier: String) -> Request<T>? {
        var request: Request<T>?
        syncQueue.sync {
            request = self.requesting[identifier]
        }
        return request
    }
    
    @inline(__always) fileprivate func setCached(request: Request<T>?, forIdentifier identifier: String) {
        syncQueue.async(flags: .barrier, execute: {
            self.requesting[identifier] = request
        })
    }
    
    // MARK: - Set
    
    open func setObject(_ object: T, forKey key: String, errorHandler: ((_ error: Error) -> Void)? = nil) {
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
    
    open func removeObjectForKey(_ key: String, errorHandler: ((_ error: Error) -> Void)? = nil) {
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
                self.setCached(request: nil, forIdentifier: descriptor.key)
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
