//
//  Fetcher.swift
//  NewCache
//
//  Created by JuanJo on 13/05/20.
//

import Foundation
import ShallowPromises

struct FetcherResult<T> {
    var instance: T
    var data: Data?
}

protocol Fetcher {
    associatedtype T
    func fetch() -> Promise<FetcherResult<T>>
}
