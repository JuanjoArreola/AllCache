//
//  ObjectProcessor.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

open class Processor<T> {
    
    public let identifier: String
    public var next: Processor<T>?
    
    var key: String {
        if let processor = next {
            return "\(processor.key)__\(identifier)"
        }
        return identifier
    }
    
    public init(identifier: String, next: Processor<T>? = nil) {
        self.identifier = identifier
        self.next = next
    }
    
    open func process(object: T) throws -> T {
        fatalError("Not implemented")
    }
}
