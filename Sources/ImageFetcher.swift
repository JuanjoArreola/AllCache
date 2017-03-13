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


enum ImageFetcherError: Error {
    case filterError
}


public final class ImageFetcher: ObjectFetcher<Image> {
    let url: URL
    
    public init(url: URL) {
        self.url = url
        super.init(identifier: String((url as NSURL).hash))
    }

    public required init(identifier: String) {
        fatalError("init(identifier:) has not been implemented")
    }
    
    public override func fetchAndRespond(in queue: DispatchQueue, completion: @escaping (_ getFetcherResult: () throws -> FetcherResult<Image>) -> Void) -> Request<FetcherResult<Image>> {
        let allRequest = AllCacheURLRequest<FetcherResult<Image>>(completionHandler: completion)
        do {
            allRequest.dataTask = try request(url: url) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                do {
                    if let error = error {
                        throw error
                    }
                    guard let validData = data else {
                        throw FetchError.invalidData
                    }
                    guard let image = Image(data: validData, scale: UIScreen.main.scale) else {
                        throw FetchError.parseError
                    }
                    queue.async {
                        allRequest.complete(withObject: FetcherResult(object: image, data: data))
                    }
                } catch {
                    queue.async {
                        allRequest.complete(withError: error)
                    }
                }
            }
        }
        catch {
            queue.async {
                allRequest.complete(withError: error)
            }
        }
        return allRequest
    }
    
}
