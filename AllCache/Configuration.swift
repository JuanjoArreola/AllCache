//
//  Configuration.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation


final class Configuration: NSObject {
    
    private static let defaultProperties: [String: AnyObject] = {
        let bundle = NSBundle(forClass: Configuration.self)
        let path = bundle.pathForResource("allcache_properties", ofType: "plist")
        return NSDictionary(contentsOfFile: path!) as! [String:AnyObject]
    }()
    
    private static let properties: [String: AnyObject]? = {
        if let path = NSBundle.mainBundle().pathForResource("AllCacheProperties", ofType: "plist") {
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