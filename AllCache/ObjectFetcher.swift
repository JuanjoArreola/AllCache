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

/// Abstract class intended to be subclassed to fetch an object of a concrete type
public class ObjectFetcher<T: AnyObject> {
    
    public var identifier: String!
    
    public required init(identifier: String) {
        self.identifier = identifier
    }
    
    public func fetchAndRespondInQueue(queue: dispatch_queue_t, completion: (getObject: () throws -> T) -> Void) -> Request<T> {
        let request = Request<T>(completionHandler: completion)
        dispatch_async(queue) {
            request.completeWithError(FetchError.NotImplemented)
        }
        return request
    }
}