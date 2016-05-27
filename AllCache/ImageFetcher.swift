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
    
    public override func fetchAndRespondInQueue(queue: dispatch_queue_t, completion: (getFetcherResult: () throws -> FetcherResult<Image>) -> Void) -> Request<FetcherResult<Image>> {
        let request = URLRequest<FetcherResult<Image>>(completionHandler: completion)
        do {
            request.dataTask = try requestURL(url) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                do {
                    if let error = error {
                        throw error
                    }
                    guard let validData = data else {
                        throw FetchError.InvalidData
                    }
                    guard let image = Image(data: validData, scale: UIScreen.mainScreen().scale) else {
                        throw FetchError.ParseError
                    }
                    dispatch_async(queue) {
                        request.completeWithObject(FetcherResult(object: image, data: data))
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