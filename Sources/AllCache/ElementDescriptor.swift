//
//  ElementDescriptor.swift
//  AllCache
//
//  Created by JuanJo on 13/05/20.
//

import Foundation

public struct ElementDescriptor<T, F: Fetcher> where F.T == T {
    public var key: String
    public var fetcher: F?
    public var processor: Processor<T>?
    
    public var descriptorKey: String {
        if let processor = processor {
            return [key, processor.key].joined(separator: "-")
        }
        return key
    }
    
    public init(key: String, fetcher: F?, processor: Processor<T>?) {
        self.key = key
        self.fetcher = fetcher
        self.processor = processor
    }
}
