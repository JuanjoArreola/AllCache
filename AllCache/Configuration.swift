//
//  Configuration.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation


public final class Configuration: NSObject {
    
    fileprivate static let defaultProperties: [String: AnyObject] = {
        let bundle = Bundle(for: Configuration.self)
        let path = bundle.path(forResource: "allcache_properties", ofType: "plist")
        return NSDictionary(contentsOfFile: path!) as! [String:AnyObject]
    }()
    
    fileprivate static let properties: [String: AnyObject]? = {
        if let path = Bundle.main.path(forResource: "AllCacheProperties", ofType: "plist") {
            return NSDictionary(contentsOfFile: path) as? [String: AnyObject]
        }
        return nil
    }()
    
    static var logLevel: Int = {
        if let level = properties?["log_level"] as? Int {
            if level >= 0 && level <= 4 {
                return level
            }
        }
        return defaultProperties["log_level"] as! Int
    }()
    
    static var showFile: Bool = {
        return properties?["show_file"] as? Bool ?? defaultProperties["show_file"] as! Bool
    }()
    
    static var showFunc: Bool = {
        return properties?["show_func"] as? Bool ?? defaultProperties["show_func"] as! Bool
    }()
    
    static var showLine: Bool = {
        return properties?["show_line"] as? Bool ?? defaultProperties["show_line"] as! Bool
    }()
}
