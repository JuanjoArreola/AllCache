//
//  ImageFetcher.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

#if os(OSX)
    import AppKit
#else
    import UIKit
#endif


enum ImageFetcherError: ErrorType {
    case FilterError
}


public final class ImageFetcher: ObjectFetcher<Image> {
    let url: NSURL
    
    public init(url: NSURL) {
        self.url = url
        super.init(identifier: String(url.hash))
    }
    
    override func fetchAndRespondInQueue(queue: dispatch_queue_t, completion: ((getObject: () throws -> Image) -> Void)?) -> Request<Image>? {
        let request = completion != nil ? URLRequest<Image>(completionHandler: completion!) : URLRequest<Image>()
        do {
            request.dataTask = try requestURL(url) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                do {
                    if let error = error {
                        throw error
                    }
                    guard let validData = data else {
                        throw FetchError.InvalidData
                    }
                    guard let image = Image(data: validData) else {
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