//
//  ObjectFetcher.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

enum FetchError: ErrorType {
    case InvalidData
    case ParseError
    case NotFound
    case NotImplemented
}

public class FetcherResult<T> {
    var object: T
    var data: NSData?
    
    public required init(object: T, data: NSData?) {
        self.object = object
        self.data = data
    }
}

/// Abstract class intended to be subclassed to fetch an object of a concrete type
public class ObjectFetcher<T: AnyObject> {
    
    public var identifier: String!
    
    public required init(identifier: String) {
        self.identifier = identifier
    }
    
    public func fetchAndRespondInQueue(queue: dispatch_queue_t, completion: (getFetcherResult: () throws -> FetcherResult<T>) -> Void) -> Request<FetcherResult<T>> {
        let request = Request<FetcherResult<T>>(completionHandler: completion)
        dispatch_async(queue) {
            request.completeWithError(FetchError.NotImplemented)
        }
        return request
    }
}