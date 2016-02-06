//
//  Networking.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation


public enum HTTPMethod: String {
    case GET
    case POST
    case PUT
}

public enum ParameterEncoding {
    case URL
    case JSON
}


public func requestURL(url: NSURL, method: HTTPMethod = .GET, parameters: [String: AnyObject]? = [:], parameterEncoding: ParameterEncoding = .URL, completion: ((data: NSData?, response: NSURLResponse?, error:NSError?)) -> Void) throws -> NSURLSessionDataTask {
    
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = method.rawValue
    try request.encodeParameters(parameters, withEncoding: parameterEncoding)
    
    let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: completion)
    task.resume()
    return task
}

extension NSMutableURLRequest {
    
    func encodeParameters(parameters: [String: AnyObject]?, withEncoding encoding: ParameterEncoding) throws {
        switch encoding {
        case .URL:
            if NSMutableURLRequest.parametersInURLForMethod(self.HTTPMethod) {
                guard let params = parameters else {
                    return
                }
                if let URLComponents = NSURLComponents(URL: self.URL!, resolvingAgainstBaseURL: false) {
                    let parametersString = NSMutableURLRequest.encodeParameters(params)
                    let percentEncodedQuery = (URLComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + parametersString
                    URLComponents.percentEncodedQuery = percentEncodedQuery
                    self.URL = URLComponents.URL
                }
            } else {
                setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                if let params = parameters {
                    let parametersString = NSMutableURLRequest.encodeParameters(params)
                    self.HTTPBody = parametersString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                }
            }
            
        case .JSON:
            self.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let params = parameters {
                self.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions())
            }
        }
    }
    
    static func parametersInURLForMethod(method: String) -> Bool {
        switch method {
        case "GET", "HEAD", "DELETE":
            return true
        default:
            return false
        }
    }
    
    static func encodeParameters(parameters: [String: AnyObject]) -> String {
        let array = parameters.map { (key, value) -> String in
            let string = String(value)
            return "\(key)=\(string)"
        }
        return array.joinWithSeparator("&")
    }
}
