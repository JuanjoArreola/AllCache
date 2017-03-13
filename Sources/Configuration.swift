//
//  Configuration.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation


public final class Configuration: NSObject {
    
    private static let properties: [String: Any]? = {
        if let path = Bundle.main.path(forResource: "AllCacheProperties", ofType: "plist") {
            return NSDictionary(contentsOfFile: path) as? [String: Any]
        }
        return nil
    }()
    
    static var logLevel: Int = {
        if let level = properties?["log_level"] as? Int {
            if level >= 0 && level <= 4 {
                return level
            }
        }
        return 2
    }()
    
    static var showFile: Bool = {
        return properties?["show_file"] as? Bool ?? false
    }()
    
    static var showFunc: Bool = {
        return properties?["show_func"] as? Bool ?? false
    }()
    
    static var showLine: Bool = {
        return properties?["show_line"] as? Bool ?? false
    }()
}
