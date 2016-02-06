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


public class ImageFetcher: ObjectFetcher<UIImage> {
    let url: NSURL
    
    init(url: NSURL) {
        self.url = url
    }
    
    override func fetchAndRespondInQueue(queue: dispatch_queue_t, completion: ((getObject: () throws -> UIImage) -> Void)?) -> Request<UIImage>? {
        let request = completion != nil ? URLRequest<UIImage>(completionHandler: completion!) : Request<UIImage>()
        do {
            try requestURL(url) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                if let error = error {
                    request.completeWithError(error)
                    return
                }
                guard let validData = data else {
                    request.completeWithError(FetchError.InvalidData)
                    return
                }
                guard let rawImage = UIImage(data: validData) else {
                    request.completeWithError(FetchError.ParseError)
                    return
                }
                guard let image = self.filterImage(rawImage) else {
                    request.completeWithError(ImageFetcherError.FilterError)
                    return
                }
                dispatch_async(queue) {
                    request.completeWithObject(image)
                }
            }
        }
        catch {
            request.completeWithError(error)
        }
        return request
    }
    
    func filterImage(image: UIImage) -> UIImage? {
        return image
    }
    
}