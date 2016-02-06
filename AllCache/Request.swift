//
//  Request.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

enum RequestError: ErrorType {
    case Canceled
}

public class Request<T: AnyObject> {
    
    private var completionHandlers: [(getObject: () throws -> T) -> Void] = []
    private var result: (() throws -> T)?
    
    public var completed: Bool {
        return result != nil
    }
    
    public var canceled = false
    
    required public init() {}
    
    convenience init(completionHandler: (getObject: () throws -> T) -> Void) {
        self.init()
        completionHandlers.append(completionHandler)
    }
    
    func cancel() {
        canceled = true
        completeWithError(RequestError.Canceled)
    }
    
    func completeWithObject(object: T) {
        if result == nil {
            result = { return object }
            callHandlers()
        }
    }
    
    func completeWithError(error: ErrorType) {
        if result == nil {
            result = { throw error }
            callHandlers()
        }
    }
    
    func callHandlers() {
        guard let getClosure = result else { return }
        for handler in completionHandlers {
            handler(getObject: getClosure)
        }
    }
    
    func addCompletionHandler(completion: (getObject: () throws -> T) -> Void) {
        if let getClosure = result {
            completion(getObject: getClosure)
        } else {
            completionHandlers.append(completion)
        }
    }
}


public class URLRequest<T: AnyObject>: Request<T> {
    
    var dataTask: NSURLSessionDataTask?
    
    required public init() {}
    
    override func cancel() {
        dataTask?.cancel()
        super.cancel()
    }
}
