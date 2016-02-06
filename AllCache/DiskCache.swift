//
//  DiskCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

class DiskCache<T: AnyObject> {
    
    let persistentStoreManager: PersistentStoreManager<T>
    
    required init(persistentStoreManager: PersistentStoreManager<T>) {
        self.persistentStoreManager = persistentStoreManager
    }
    
    func objectForKey(key: String) -> T? {
        return nil
    }
    
    func setObject(object: T?, forKey key: String) {
        
    }
    
    func updateLastAccessOfKey(key: String) {
        
    }
    
    func clear() {
        
    }
}

public enum PersistentStoreError: ErrorType {
    case NotImplemented
}

public class PersistentStoreManager<T> {
    var storeURL: NSURL!
    
    func persist(object: T, fileName: String) throws {
        throw PersistentStoreError.NotImplemented
    }
    
    func retrieve(fileName: String) throws -> T {
        throw PersistentStoreError.NotImplemented
    }
    
    func delete(fileName: String) throws {
        throw PersistentStoreError.NotImplemented
    }
}
