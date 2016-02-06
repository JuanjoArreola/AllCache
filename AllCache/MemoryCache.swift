//
//  MemoryCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

final class MemoryCache<T: AnyObject> {
    
    private var imageCache = NSCache()
    
    func objectForKey(key: String) -> T? {
        return imageCache.objectForKey(key) as? T
    }
    
    func setObject(object: T?, forKey key: String) {
        if let object = object {
            imageCache.setObject(object, forKey: key)
        }
    }
    
    func clear() {
        imageCache.removeAllObjects()
    }
    
}
