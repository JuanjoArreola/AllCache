//
//  ElementDescriptor.swift
//  NewCache
//
//  Created by JuanJo on 13/05/20.
//

import Foundation

struct ElementDescriptor<T, F: Fetcher, P: Processor> where F.T == T, P.T == T {
    var key: String
    var fetcher: F?
    var processor: P?
    
    var descriptorKey: String {
        if let processor = processor {
            return [key, processor.key].joined(separator: "-")
        }
        return key
    }
}
