//
//  Networking.swift
//  ImageCache
//
//  Created by JuanJo on 31/08/20.
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
