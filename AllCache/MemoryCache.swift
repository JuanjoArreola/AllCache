//
//  MemoryCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

public final class MemoryCache<T: AnyObject> {
    
    private var cache = NSCache<String, T>()
    
    public func objectForKey(_ key: String) -> T? {
        return cache.object(forKey: key) as? T
    }
    
    public func setObject(_ object: T?, forKey key: String) {
        if let object = object {
            cache.setObject(object, forKey: key)
        }
    }
    
    public func removeObjectForKey(_ key: String) {
        cache.removeObject(forKey: key)
    }
    
    public func clear() {
        cache.removeAllObjects()
    }
    
}
