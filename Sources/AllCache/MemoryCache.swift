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
    
    public init() {
        
    }
    
    public func object(forKey key: String) -> T? {
        if let result = cache.object(forKey: key as NSString) {
            log.debug("🔑(\(key)) found in memory")
            return result
        }
        return nil
    }
    
    public func set(object: T?, forKey key: String) {
        if let object = object {
            cache.setObject(object, forKey: key as NSString)
        }
    }
    
    func set(object: T?, forKey key: String, in queue: DispatchQueue) {
        guard let object = object else { return }
        queue.async {
            self.cache.setObject(object, forKey: key as NSString)
        }
    }
    
    public func removeObject(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    public func clear() {
        cache.removeAllObjects()
    }
    
}
