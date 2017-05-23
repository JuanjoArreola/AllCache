//
//  LowMemoryHandler.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 19/05/17.
//
//

import Foundation

class LowMemoryHandler<T: AnyObject> {
    
    weak var cache: Cache<T>? {
        didSet {
            registerForLowMemoryNotification()
        }
    }
    
    init() {}
    
    #if os(iOS) || os(tvOS)
    
    func registerForLowMemoryNotification() {
        let name = NSNotification.Name.UIApplicationDidReceiveMemoryWarning
        let selector = #selector(self.handleMemoryWarning(notification:))
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    #else
    
    func registerForLowMemoryNotification() {}
    
    #endif
    
    @objc func handleMemoryWarning(notification: Notification) {
        cache?.memoryCache.clear()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
