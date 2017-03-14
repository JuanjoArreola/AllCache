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
    case invalidMethod, invalidURL, encodingError
}


public func request(url: URL, method: HTTPMethod = .GET, parameters: [String: Any]? = [:], parameterEncoding: ParameterEncoding = .url, completion: @escaping ((data: Data?, response: URLResponse?, error: Error?)) -> Void) throws -> URLSessionDataTask {
    
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    try request.encode(parameters: parameters, with: parameterEncoding)
    
    let task = URLSession.shared.dataTask(with: request, completionHandler: completion)
    task.resume()
    return task
}

public extension URLRequest {
    
    mutating func encode(parameters: [String: Any]?, with encoding: ParameterEncoding) throws {
        guard let method = httpMethod else { throw EncodeError.invalidMethod }
        switch encoding {
        case .url:
            if ["GET", "HEAD", "DELETE"].contains(method) {
                self.url = try self.url?.appending(parameters: parameters)
            } else {
                setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                if let params = parameters {
                    guard let queryString = params.urlQueryString else { throw EncodeError.encodingError }
                    self.httpBody = queryString.data(using: .utf8, allowLossyConversion: false)
                }
            }
            
        case .json:
            self.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let params = parameters {
                self.httpBody = try JSONSerialization.data(withJSONObject: params.jsonValid, options: [])
            }
        }
    }
}

public extension Dictionary where Key: ExpressibleByStringLiteral {
    
    public var urlQueryString: String? {
        let string = self.map({ "\($0)=\(String(describing: $1))" }).joined(separator: "&")
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    public var jsonValid: [Key: Any] {
        var result = [Key: Any]()
        self.forEach({ result[$0] = JSONSerialization.isValidJSONObject($1) ? $1 : String(describing: $1) })
        return result
    }
}

public extension URL {
    func appending(parameters: [String: Any]?) throws -> URL {
        guard let params = parameters else { return self }
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
        guard let queryString = params.urlQueryString else { throw EncodeError.encodingError }
        let percentEncodedQuery = (components.percentEncodedQuery.map { $0 + "&" } ?? "") + queryString
        components.percentEncodedQuery = percentEncodedQuery
        if let url = components.url {
            return url
        }
        throw EncodeError.encodingError
    }
}
