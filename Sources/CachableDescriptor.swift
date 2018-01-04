//
//  CachableDescriptor.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

/// Abstract class that provides all the information that a cache requires to search, fetch and process an object
open class CachableDescriptor<T: Any> {
    open let key: String
    
    open var resultKey: String {
        if let processor = processor {
            return "\(key)__\(processor.key)"
        }
        return key
    }
    
    let fetcher: Fetcher<T>
    let processor: Processor<T>?
    
    required public init(key: String, fetcher: Fetcher<T>, processor: Processor<T>?) {
        self.key = key
        self.fetcher = fetcher
        self.processor = processor
    }
}
