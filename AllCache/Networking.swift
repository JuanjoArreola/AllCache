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
    case url
    case json
}

enum EncodeError: Error {
    case invalidMethod, invalidURL
}


public func request(URL url: URL, method: HTTPMethod = .GET, parameters: [String: AnyObject]? = [:], parameterEncoding: ParameterEncoding = .url, completion: @escaping ((data: Data?, response: URLResponse?, error: Error?)) -> Void) throws -> URLSessionDataTask {
    
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    try request.encode(parameters: parameters, withEncoding: parameterEncoding)
    
    let task = URLSession.shared.dataTask(with: request, completionHandler: completion)
    task.resume()
    return task
}

extension URLRequest {
    
    mutating func encode(parameters: [String: Any]?, withEncoding encoding: ParameterEncoding) throws {
        guard let method = httpMethod else { throw EncodeError.invalidMethod }
        switch encoding {
        case .url:
            if URLRequest.parametersInURL(forMethod: method) {
                guard let params = parameters else { return }
                guard let url = self.url else { throw EncodeError.invalidURL }
                if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    let parametersString = URLRequest.encode(parameters: params)
                    let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + parametersString
                    urlComponents.percentEncodedQuery = percentEncodedQuery
                    self.url = urlComponents.url
                }
            } else {
                setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                if let params = parameters {
                    let parametersString = URLRequest.encode(parameters: params)
                    self.httpBody = parametersString.data(using: String.Encoding.utf8, allowLossyConversion: false)
                }
            }
            
        case .json:
            self.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let params = parameters {
                self.httpBody = try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions())
            }
        }
    }
    
    static func parametersInURL(forMethod method: String) -> Bool {
        switch method {
        case "GET", "HEAD", "DELETE":
            return true
        default:
            return false
        }
    }
    
    static func encode(parameters: [String: Any]) -> String {
        let array = parameters.map { (key, value) -> String in
            let string = String(describing: value)
            return "\(key)=\(string)"
        }
        return array.joined(separator: "&")
    }
}
