//
//  Cache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

private let diskQueue: dispatch_queue_t = dispatch_queue_create("com.crayon.allcache.DiskQueue", DISPATCH_QUEUE_SERIAL)
private let fetchQueue: dispatch_queue_t = dispatch_queue_create("com.crayon.allcache.FetchQueue", DISPATCH_QUEUE_SERIAL)
private let processQueue: dispatch_queue_t = dispatch_queue_create("com.crayon.allcache.ProcessQueue", DISPATCH_QUEUE_CONCURRENT)


public class Cache<T: AnyObject> {
    
    private var fetching = [String: Request<T>]()
    
    private let memoryCache: MemoryCache<T>? = MemoryCache<T>()
    private let diskCache: DiskCache<T>?
    public let identifier: String
    private var queue: dispatch_queue_t?
    var moveOriginalToMemoryCache = false
    var moveOriginalToDiskCache = true
    
    required public init(identifier: String) throws {
        self.identifier = identifier
        diskCache = nil
    }
    
    required public init(identifier: String, persistentStoreManager: PersistentStoreManager<T>) throws {
        self.identifier = identifier
        self.diskCache = DiskCache<T>(identifier: identifier, persistentStoreManager: persistentStoreManager)
    }
    
    func getObjectForKey(key: String, objectFetcher: ObjectFetcher<T>, completion: (getObject: () throws -> T) -> Void) -> Request<T>? {
        if let object = memoryCache?.objectForKey(key) {
            Log.debug("\(key) found in memory")
            completion(getObject: { return object })
            return nil
        }
        Log.debug("\(key) NOT found in memory")
        
        let request = Request(completionHandler: completion)
        
        dispatch_async(diskQueue) {
            if let object = self.diskCache?.objectForKey(key) {
                Log.debug("\(key) found in disk")
                dispatch_async(self.queue ?? dispatch_get_main_queue()) {
                    request.completeWithObject(object)
                    self.memoryCache?.setObject(object, forKey: key)
                }
                self.diskCache?.updateLastAccessOfKey(key)
            } else {
                Log.debug("\(key) NOT found in disk")
                
                var fetcherRequest = self.fetching[objectFetcher.identifier]
                if fetcherRequest == nil {
                    Log.debug("NO fetching request found for \(objectFetcher.identifier)")
                    fetcherRequest = objectFetcher.fetchAndRespondInQueue(diskQueue)
                    self.fetching[objectFetcher.identifier] = request
                }
                fetcherRequest?.addCompletionHandler({ (getObject) -> Void in
                    do {
                        let object = try getObject()
                        Log.debug("\(key) fetched")
                        dispatch_async(self.queue ?? dispatch_get_main_queue()) {
                            request.completeWithObject(object)
                            self.memoryCache?.setObject(object, forKey: key)
                        }
                        _ = try? self.diskCache?.setObject(object, forKey: key)
                    } catch {
                        dispatch_async(self.queue ?? dispatch_get_main_queue()) {
                            request.completeWithError(error)
                        }
                    }
                    self.fetching[objectFetcher.identifier] = nil
                })
            }
        }
        
        return request
    }
    
    func getObjectForKey(key: String, originalKey: String, objectFetcher: ObjectFetcher<T>, objectProcessor: ObjectProcessor<T>, completion: (getObject: () throws -> T) -> Void) -> Request<T>? {
        let descriptor = CachableDescriptorWrapper<T>(key: key, originalKey: originalKey, objectFetcher: objectFetcher, objectProcessor: objectProcessor)
        return getObjectForDescriptor(descriptor, completion: completion)
    }
    
    func getObjectForDescriptor(descriptor: CachableDescriptor<T>, completion: (getObject: () throws -> T) -> Void) -> Request<T>? {
        
        //      MARK: - Search in Memory o'
        if let object = memoryCache?.objectForKey(descriptor.key) {
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
                dispatch_async(self.queue ?? dispatch_get_main_queue()) {
                    request.completeWithObject(object)
                    self.memoryCache?.setObject(object, forKey: descriptor.key)
                }
                self.diskCache?.updateLastAccessOfKey(descriptor.key)
                return
            }
            Log.debug("\(descriptor.key) NOT found in disk")
            
            //          MARK: - Search in Memory o
            dispatch_async(self.queue ?? dispatch_get_main_queue()) {
                if let rawObject = self.memoryCache?.objectForKey(descriptor.originalKey) {
                    Log.debug("\(descriptor.originalKey) found in memory")
                    self.processRawObject(rawObject, withDescriptor: descriptor, request: request)
                }
                else {
                    Log.debug("\(descriptor.originalKey) NOT found in memory")
                    
                    //                  MARK: - Search in Disk o
                    dispatch_async(diskQueue) {
                        if let rawObject = self.diskCache?.objectForKey(descriptor.originalKey) {
                            Log.debug("\(descriptor.originalKey) found in memory")
                            self.processRawObject(rawObject, withDescriptor: descriptor, request: request)
                            if self.moveOriginalToMemoryCache {
                                dispatch_async(self.queue ?? dispatch_get_main_queue()) {
                                    self.memoryCache?.setObject(rawObject, forKey: descriptor.originalKey)
                                }
                            }
                            self.diskCache?.updateLastAccessOfKey(descriptor.originalKey)
                        }
                        else {
                            Log.debug("\(descriptor.originalKey) NOT found in disk")
                            
                            //                          MARK: - Fetch Object
                            var fetcherRequest = self.fetching[descriptor.identifier]
                            if fetcherRequest == nil {
                                Log.debug("NO fetching request found for \(descriptor.identifier)")
                                fetcherRequest = descriptor.fetchAndRespondInQueue(diskQueue)
                                self.fetching[descriptor.identifier] = request
                            }
                            fetcherRequest?.addCompletionHandler({ (getObject) in
                                do {
                                    let rawObject = try getObject()
                                    Log.debug("\(descriptor.originalKey) fetched")
                                    
                                    self.processRawObject(rawObject, withDescriptor: descriptor, request: request)
                                    if self.moveOriginalToMemoryCache {
                                        dispatch_async(self.queue ?? dispatch_get_main_queue()) {
                                            self.memoryCache?.setObject(rawObject, forKey: descriptor.originalKey)
                                        }
                                    }
                                    if self.moveOriginalToDiskCache {
                                        _ = try? self.diskCache?.setObject(rawObject, forKey: descriptor.originalKey)
                                    }
                                } catch {
                                    dispatch_async(self.queue ?? dispatch_get_main_queue()) {
                                        request.completeWithError(error)
                                    }
                                }
                                self.fetching[descriptor.identifier] = nil
                            })
                            
                        }
                    }
                }
            }
        }
        return request
    }
    
    func processRawObject(rawObject: T, withDescriptor descriptor: CachableDescriptor<T>, request: Request<T>) {
        dispatch_async(processQueue) {
            Log.debug("processing \(descriptor.originalKey)")
            descriptor.processObject(rawObject, respondInQueue: self.queue ?? dispatch_get_main_queue()) { (getObject) in
                do {
                    let object = try getObject()
                    request.completeWithObject(object)
                    self.memoryCache?.setObject(object, forKey: descriptor.key)
                    dispatch_async(diskQueue) {
                        _ = try? self.diskCache?.setObject(object, forKey: descriptor.key)
                    }
                } catch {
                    request.completeWithError(error)
                }
            }
        }
    }
    
}