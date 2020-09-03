//
//  Fetcher.swift
//  AllCache
//
//  Created by JuanJo on 13/05/20.
//

import Foundation
import ShallowPromises

public struct FetcherResult<T> {
    var instance: T
    var data: Data?
    
    public init(instance: T, data: Data? = nil) {
        self.instance = instance
        self.data = data
    }
}

public protocol Fetcher {
    associatedtype T
    func fetch() -> Promise<FetcherResult<T>>
}

public enum FetchError: Error {
    case invalidData
    case parseError
    case notFound
}
