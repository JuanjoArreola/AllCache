//
//  Processor.swift
//  AllCache
//
//  Created by JuanJo on 13/05/20.
//

import Foundation

open class Processor<T> {
    
    public let identifier: String
    public var next: Processor<T>?
    
    open var key: String {
        if let processor = next {
            return "\(processor.key)-\(identifier)"
        }
        return identifier
    }
    
    public init(identifier: String, next: Processor<T>? = nil) {
        self.identifier = identifier
        self.next = next
    }
    
    open func process(_ instance: T) throws -> T {
        return instance
    }
}
