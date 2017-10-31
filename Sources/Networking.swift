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

func request(url: URL, method: HTTPMethod = .GET, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
    
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    
    let task = URLSession.shared.dataTask(with: request, completionHandler: completion)
    task.resume()
    return task
}
