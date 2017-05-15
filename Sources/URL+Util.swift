//
//  URL+Util.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 5/13/17.
//
//

import Foundation

extension URL {
    var contentAccessDate: Date? {
        if let values = try? resourceValues(forKeys: Set([.contentAccessDateKey])) {
            return values.allValues[.contentAccessDateKey] as? Date
        }
        return nil
    }
    
    // bytes
    var totalFileAllocatedSize: Int? {
        if let values = try? resourceValues(forKeys: Set([.totalFileAllocatedSizeKey])) {
            return (values.allValues[.totalFileAllocatedSizeKey] as? NSNumber)?.intValue
        }
        return nil
    }
    
}
