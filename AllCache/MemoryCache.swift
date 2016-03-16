//
//  MemoryCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

public final class MemoryCache<T: AnyObject> {
    
    private var cache = NSCache()
    
    public func objectForKey(key: String) -> T? {
        return cache.objectForKey(key) as? T
    }
    
    public func setObject(object: T?, forKey key: String) {
        if let object = object {
            cache.setObject(object, forKey: key)
        }
    }
    
    public func removeObjectForKey(key: String) {
        cache.removeObjectForKey(key)
    }
    
    public func clear() {
        cache.removeAllObjects()
    }
    
}
