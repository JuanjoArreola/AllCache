//
//  Request.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

public enum RequestError: Error {
    case canceled
}

public protocol Cancellable {
    func cancel()
}

open class Request<T: Any>: Cancellable, CustomDebugStringConvertible {
    
    private var completionHandlers: [(_ getObject: () throws -> T) -> Void]? = []
    private var result: (() throws -> T)?
    
    open var subrequest: Cancellable? {
        didSet {
            if canceled {
                subrequest?.cancel()
            }
        }
    }
    
    open var completed: Bool {
        return result != nil
    }
    
    open var canceled = false
    
    required public init() {}
    
    public convenience init(completionHandler: @escaping (_ getObject: () throws -> T) -> Void) {
        self.init()
        completionHandlers?.append(completionHandler)
    }
    
    open func cancel() {
        sync() { self.canceled = true }
        subrequest?.cancel()
        complete(withError: RequestError.canceled)
    }
    
    open func complete(withObject object: T) {
        if result == nil {
            result = { return object }
            callHandlers()
        }
    }
    
    open func complete(withError error: Error) {
        if result == nil {
            result = { throw error }
            callHandlers()
        }
    }
    
    func callHandlers() {
        guard let getClosure = result else { return }
        completionHandlers?.forEach({ $0(getClosure) })
        sync() { self.completionHandlers = nil }
    }
    
    open func add(completionHandler completion: @escaping (_ getObject: () throws -> T) -> Void) {
        if let getClosure = result {
            completion(getClosure)
        } else {
            sync() { self.completionHandlers?.append(completion) }
        }
    }
    
    open var debugDescription: String {
        return String(describing: self)
    }
}

private func sync(closure: @escaping () -> Void) {
    syncQueue.async(flags: .barrier, execute: closure)
}


open class AllCacheURLRequest<T: Any>: Request<T> {
    
    var dataTask: URLSessionDataTask?
    
    required public init() {}
    
    override open func cancel() {
        dataTask?.cancel()
        super.cancel()
    }
    
    override open var debugDescription: String {
        var desc = "URLRequest<\(T.self)>"
        if let url = dataTask?.originalRequest?.url {
            desc += "(\(url))"
        }
        return desc
    }
}
