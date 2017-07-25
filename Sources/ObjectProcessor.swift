//
//  Processor.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

open class Processor<T> {
    
    public var identifier: String
    public var next: Processor<T>?
    
    public var key: String {
        if let processor = next {
            return "\(processor.key)__\(identifier)"
        }
        return identifier
    }
    
    public init(identifier: String, next: Processor<T>? = nil) {
        self.identifier = identifier
        self.next = next
    }
    
    open func process(object: T, respondIn queue: DispatchQueue, completion: @escaping (_ getObject: () throws -> T) -> Void) {
        fatalError("Not implemented")
    }
}
