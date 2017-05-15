//
//  RequestingCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 5/14/17.
//
//

import Foundation

internal let syncQueue = DispatchQueue(label: "com.allcache.SyncQueue", attributes: .concurrent)

class RequestingCache<T: AnyObject> {
    
    var fetching: [String: Request<FetcherResult<T>>] = [:]
    var requesting: [String: Request<T>] = [:]
    
    @inline(__always)
    func request(forKey key: String, completion: @escaping (_ getObject: () throws -> T) -> Void) -> (request: Request<T>, ongoing: Bool) {
        if let request = getCachedRequest(withIdentifier: key) {
            if request.canceled {
                setCached(request: nil, forIdentifier: key)
            } else {
                request.add(completionHandler: completion)
                return (request, true)
            }
        }
        setCached(request: Request(completionHandler: completion), forIdentifier: key)
        return (getCachedRequest(withIdentifier: key)!, false)
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
    
    @inline(__always)
    func setCached(fetching: Request<FetcherResult<T>>?, forIdentifier identifier: String) {
        syncQueue.async(flags: .barrier, execute: {
            self.fetching[identifier] = fetching
        })
    }
}
