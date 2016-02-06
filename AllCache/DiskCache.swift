//
//  DiskCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation
import CoreData

public class DiskCache<T: AnyObject> {
    
    public let identifier: String
    private let persistentStoreManager: PersistentStoreManager<T>
    private let dataStack: DataStack
    private let objectInfoRepository: ManagedObjectRepository<ObjectInfo>
    
    required public init(identifier: String, persistentStoreManager: PersistentStoreManager<T>) {
        self.identifier = identifier
        self.persistentStoreManager = persistentStoreManager
        
        let bundle = NSBundle(forClass: DiskCache.self)
        let modelURL = bundle.URLForResource("AllCache", withExtension: "momd")!
        let fileManager = NSFileManager.defaultManager()
        let documents = try! fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
        let dataStoreURL = documents.URLByAppendingPathComponent("AllCache.sqlite")
        
        self.dataStack = try! DataStack(managedObjectModelURL: modelURL, dataStoreURL: dataStoreURL, options: nil, concurrencyType: .PrivateQueueConcurrencyType)
        objectInfoRepository = ManagedObjectRepository<ObjectInfo>(entityName: "ObjectInfo", managedObjectContext: dataStack.managedObjectContext)!
    }
    
    func objectForKey(key: String) -> T? {
        guard let objectInfo = getObjectInfoWithKey(key) else {
            return nil
        }
        do {
            objectInfo.lastAccess = NSDate()
            return try persistentStoreManager.retrieve(path: objectInfo.path)
        } catch {
            Log.error(error)
            return nil
        }
    }
    
    func setObject(object: T, forKey key: String) throws {
        var objectInfo: ObjectInfo! = getObjectInfoWithKey(key)
        if objectInfo == nil {
            objectInfo = objectInfoRepository.create()
            objectInfo.cache = identifier
            objectInfo.key = key
        }
        let result = try persistentStoreManager.persist(object, fileName: "\(identifier)-\(key.hash)")
        objectInfo?.path = result.path
        objectInfo?.size = result.size
        objectInfo?.lastAccess = NSDate()
    }
    
    func updateLastAccessOfKey(key: String) {
        if let objectInfo = getObjectInfoWithKey(key) {
            objectInfo.lastAccess = NSDate()
        }
    }
    
    func deleteObjectForKey(key: String) throws {
        guard let objectInfo = getObjectInfoWithKey(key) else {
            return
        }
        try persistentStoreManager.delete(objectInfo.path)
    }
    
    func clear() {
        
    }
    
    private func getObjectInfoWithKey(key: String) -> ObjectInfo? {
        do {
            let predicate = NSPredicate(format: "cache == %@ AND key == %@", identifier, key)
            let infoArray = try objectInfoRepository.getWithPredicate(predicate)
            return infoArray.first
        } catch {
            Log.error(error)
        }
        return nil
    }
}

public enum PersistentStoreError: ErrorType {
    case NotImplemented
    case InvalidPath
    case InvalidData
}

public class PersistentStoreManager<T> {
    var storeURL: NSURL!
    
    internal init(storeURL: NSURL) {
        self.storeURL = storeURL
    }
    
    func persist(object: T, fileName: String) throws -> (path: String, size: Int) {
        throw PersistentStoreError.NotImplemented
    }
    
    func retrieve(path path: String) throws -> T {
        throw PersistentStoreError.NotImplemented
    }
    
    func delete(path: String) throws {
        throw PersistentStoreError.NotImplemented
    }
}
