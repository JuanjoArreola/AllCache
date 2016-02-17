//
//  ImageFetcher.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation


enum ImageFetcherError: ErrorType {
    case FilterError
}


public final class ImageFetcher: ObjectFetcher<UIImage> {
    let url: NSURL
    
    init(url: NSURL) {
        self.url = url
    }
    
    override func fetchAndRespondInQueue(queue: dispatch_queue_t, completion: ((getObject: () throws -> UIImage) -> Void)?) -> Request<UIImage>? {
        let request = completion != nil ? URLRequest<UIImage>(completionHandler: completion!) : URLRequest<UIImage>()
        do {
            request.dataTask = try requestURL(url) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                do {
                    if let error = error {
                        throw error
                    }
                    guard let validData = data else {
                        throw FetchError.InvalidData
                    }
                    guard let image = UIImage(data: validData) else {
                        throw FetchError.ParseError
                    }
                    dispatch_async(queue) {
                        request.completeWithObject(image)
                    }
                } catch {
                    dispatch_async(queue) {
                        request.completeWithError(error)
                    }
                }
            }
        }
        catch {
            dispatch_async(queue) {
                request.completeWithError(error)
            }
        }
        return request
    }
    
}