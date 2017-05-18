//
//  RequestingCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 5/14/17.
//
//

import Foundation
import AsyncRequest

internal let syncQueue = DispatchQueue(label: "com.allcache.SyncQueue", attributes: .concurrent)

class RequestingCache<T: AnyObject> {
    
    var fetching: [String: Request<FetcherResult<T>>] = [:]
    var requesting: [String: Request<T>] = [:]
    
    @inline(__always)
    func request(forKey key: String, completion: @escaping (_ getObject: () throws -> T) -> Void) -> (request: Request<T>, ongoing: Bool) {
        if let request = getCachedRequest(withIdentifier: key) {
            if request.completed {
                setCached(request: nil, forIdentifier: key)
            } else {
                return (request.proxy(completion: completion), true)
            }
        }
        setCached(request: Request(), forIdentifier: key)
        let request = getCachedRequest(withIdentifier: key)!
        return (request.proxy(completion: completion), false)
    }
    
    @inline(__always)
    func getCachedRequest(withIdentifier identifier: String) -> Request<T>? {
        var request: Request<T>?
        syncQueue.sync {
            request = self.requesting[identifier]
        }
        return request
    }
    
    @inline(__always)
    func setCached(request: Request<T>?, forIdentifier identifier: String) {
        syncQueue.async(flags: .barrier, execute: {
            self.requesting[identifier] = request
        })
    }
    
    // MARK: - Fetching
    
    @inline(__always)
    func fetchingRequest(fetcher: Fetcher<T>, completion: @escaping (_ getObject: () throws -> FetcherResult<T>) -> Void) -> Request<FetcherResult<T>> {
        if let request = getCachedFetchingRequest(withIdentifier: fetcher.identifier) {
            request.add(completionHandler: completion)
            return request
        }
        let request = fetcher.fetch(respondIn: diskQueue, completion: completion)
        setCached(fetching: request, forIdentifier: fetcher.identifier)
        return request
    }
    
    @inline(__always)
    func getCachedFetchingRequest(withIdentifier identifier: String) -> Request<FetcherResult<T>>? {
        var request: Request<FetcherResult<T>>?
        syncQueue.sync {
            request = self.fetching[identifier]
        }
        return request
    }
    
    @inline(__always)
    func setCached(fetching: Request<FetcherResult<T>>?, forIdentifier identifier: String) {
        syncQueue.async(flags: .barrier, execute: {
            self.fetching[identifier] = fetching
        })
    }
    
}
