//
//  ObjectFetcher.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

public enum FetchError: Error {
    case invalidData
    case parseError
    case notFound
    case notImplemented
}

open class FetcherResult<T> {
    public var object: T
    public var data: Data?
    
    public required init(object: T, data: Data?) {
        self.object = object
        self.data = data
    }
}

/// Abstract class intended to be subclassed to fetch an object of a concrete type
open class Fetcher<T> {
    
    open var identifier: String
    
    public required init(identifier: String) {
        self.identifier = identifier
    }
    
    open func fetch(respondIn queue: DispatchQueue, completion: @escaping (_ getFetcherResult: () throws -> FetcherResult<T>) -> Void) -> Request<FetcherResult<T>> {
        fatalError("Not implemented")
    }
}
