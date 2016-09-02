//
//  CachableDescriptor.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

/// Abstract class that provides all the information that a cache requires to search, fetch and process an object
open class CachableDescriptor<T: AnyObject> {
    open let key: String
    open let originalKey: String
    
    required public init(key: String, originalKey: String) {
        self.key = key
        self.originalKey = originalKey
    }
    
    func fetchAndRespondInQueue(_ queue: DispatchQueue, completion: (_ getObject: () throws -> FetcherResult<T>) -> Void) -> Request<FetcherResult<T>>? { return nil }
    
    func processObject(_ object: T, respondInQueue queue: DispatchQueue, completion: (_ getObject: () throws -> T) -> Void) {}
}


/// Concrete subclass of CachableDescriptor that serves as a wrapper for an objectFetcher and objectProcessor
public final class CachableDescriptorWrapper<T: AnyObject>: CachableDescriptor<T> {
    
    let objectFetcher: ObjectFetcher<T>
    let objectProcessor: ObjectProcessor<T>
    
    public required init(key: String, originalKey: String, objectFetcher: ObjectFetcher<T>, objectProcessor: ObjectProcessor<T>) {
        self.objectFetcher = objectFetcher
        self.objectProcessor = objectProcessor
        super.init(key: key, originalKey: originalKey)
    }

    required public init(key: String, originalKey: String) {
        fatalError("init(key:originalKey:) has not been implemented")
    }
    
    public override func fetchAndRespondInQueue(_ queue: DispatchQueue, completion: (_ getFetcherResult: () throws -> FetcherResult<T>) -> Void) -> Request<FetcherResult<T>> {
        let request = Request<FetcherResult<T>>(completionHandler: completion)
        queue.async {
            request.completeWithError(FetchError.notImplemented)
        }
        return request
    }
    
    override func processObject(_ object: T, respondInQueue queue: DispatchQueue, completion: (_ getObject: () throws -> T) -> Void) {
        objectProcessor.processObject(object, respondInQueue: queue, completion: completion)
    }
}
