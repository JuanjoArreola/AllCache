//
//  MemoryCache.swift
//  NewCache
//
//  Created by JuanJo on 13/05/20.
//

import Foundation

class Box<T> {
    var instance: T
    
    init(_ instance: T) {
        self.instance = instance
    }
}

/// You can add, remove, and query items in the cache from different threads without having to lock the cache yourself.
public final class MemoryCache<T> {
    
    private let cache = NSCache<NSString, Box<T>>()
    
    func instance(forKey key: String) -> T? {
        return cache.object(forKey: key as NSString)?.instance
    }
    
    func set(_ instance: T, forKey key: String) {
        self.cache.setObject(Box(instance), forKey: key as NSString)
    }
    
    public func removeInstance(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    public func clear() {
        cache.removeAllObjects()
    }
}
