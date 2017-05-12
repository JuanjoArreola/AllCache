//
//  MemoryCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

public final class MemoryCache<T: AnyObject> {
    private let cache = NSCache<NSString, T>()
    
    public func object(forKey key: String) -> T? {
        return cache.object(forKey: key as NSString)
    }
    
    public func set(object: T?, forKey key: String) {
        if let object = object {
            cache.setObject(object, forKey: key as NSString)
        }
    }
    
    public func removeObject(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    public func clear() {
        cache.removeAllObjects()
    }
    
}