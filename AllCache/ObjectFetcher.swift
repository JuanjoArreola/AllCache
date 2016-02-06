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
}

/// Abstract class intended to be subclassed to fetch an object of a concrete type
public class ObjectFetcher<T: AnyObject> {
    
    var identifier: String!
    
    func fetchAndRespondInQueue(queue: dispatch_queue_t, completion: ((getObject: () throws -> T) -> Void)? = nil) -> Request<T>? { return nil }
}