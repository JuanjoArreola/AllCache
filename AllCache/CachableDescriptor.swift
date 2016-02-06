//
//  CachableDescriptor.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation


public class CachableDescriptor<T: AnyObject> {
    let key: String
    let originalKey: String
    var identifier: String!
    
    required public init(key: String, originalKey: String) {
        self.key = key
        self.originalKey = key
    }
    
    func fetchAndRespondInQueue(queue: dispatch_queue_t, completion: ((getObject: () throws -> T) -> Void)? = nil) -> Request<T>? { return nil }
    
    func processObject(object: T, respondInQueue queue: dispatch_queue_t, completion: (getObject: () throws -> T) -> Void) {}
}


public class CachableDescriptorWrapper<T: AnyObject>: CachableDescriptor<T> {
    
    let objectFetcher: ObjectFetcher<T>
    let objectProcessor: ObjectProcessor<T>
    
    public required init(key: String, originalKey: String, objectFetcher: ObjectFetcher<T>, objectProcessor: ObjectProcessor<T>) {
        self.objectFetcher = objectFetcher
        self.objectProcessor = objectProcessor
        super.init(key: key, originalKey: originalKey)
    }
    
    override func fetchAndRespondInQueue(queue: dispatch_queue_t, completion: ((getObject: () throws -> T) -> Void)?) -> Request<T>? {
        return objectFetcher.fetchAndRespondInQueue(queue, completion: completion)
    }
    
    override func processObject(object: T, respondInQueue queue: dispatch_queue_t, completion: (getObject: () throws -> T) -> Void) {
        objectProcessor.processObject(object, respondInQueue: queue, completion: completion)
    }
}