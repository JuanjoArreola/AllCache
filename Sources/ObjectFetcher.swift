//
//  ObjectFetcher.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

enum FetchError: Error {
    case invalidData
    case parseError
    case notFound
    case notImplemented
}

open class FetcherResult<T> {
    var object: T
    var data: Data?
    
    public required init(object: T, data: Data?) {
        self.object = object
        self.data = data
    }
}

/// Abstract class intended to be subclassed to fetch an object of a concrete type
open class ObjectFetcher<T: Any> {
    
    open var identifier: String!
    
    public required init(identifier: String) {
        self.identifier = identifier
    }
    
    open func fetchAndRespond(in queue: DispatchQueue, completion: @escaping (_ getFetcherResult: () throws -> FetcherResult<T>) -> Void) -> Request<FetcherResult<T>> {
        let request = Request<FetcherResult<T>>(completionHandler: completion)
        queue.async {
            request.complete(withError: FetchError.notImplemented)
        }
        return request
    }
}
