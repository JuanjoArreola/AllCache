//
//  Request.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

enum RequestError: Error {
    case canceled
}

public protocol Cancellable {
    func cancel()
}

open class Request<T: Any>: Cancellable, CustomDebugStringConvertible {
    
    fileprivate var completionHandlers: [(_ getObject: () throws -> T) -> Void]? = []
    fileprivate var result: (() throws -> T)?
    
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
    
    public convenience init(completionHandler: (_ getObject: () throws -> T) -> Void) {
        self.init()
        completionHandlers!.append(completionHandler)
    }
    
    open func cancel() {
        sync() { self.canceled = true }
        subrequest?.cancel()
        completeWithError(RequestError.canceled)
    }
    
    open func completeWithObject(_ object: T) {
        if result == nil {
            result = { return object }
            callHandlers()
        }
    }
    
    open func completeWithError(_ error: Error) {
        if result == nil {
            result = { throw error }
            callHandlers()
        }
    }
    
    func callHandlers() {
        guard let getClosure = result else { return }
        for handler in completionHandlers! {
            handler(getClosure)
        }
        sync() { self.completionHandlers = nil }
    }
    
    open func addCompletionHandler(_ completion: @escaping (_ getObject: () throws -> T) -> Void) {
        if let getClosure = result {
            completion(getClosure)
        } else {
            sync() { self.completionHandlers?.append(completion) }
        }
    }
    
    open var debugDescription: String {
        return String(self)
    }
}

private func sync(_ closure: () -> Void) {
    syncQueue.async(flags: .barrier, execute: closure)
}


open class AllCacheURLRequest<T: AnyObject>: Request<T> {
    
    var dataTask: URLSessionDataTask?
    
    required public init() {}
    
    override open func cancel() {
        Log.debug("Cancelling: \(dataTask?.originalRequest?.url)")
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
