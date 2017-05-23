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
    let screenScale = NSScreen.main()?.backingScaleFactor ?? 1.0
    
    extension Image {
        convenience init?(data: Data, scale: CGFloat) {
            self.init(data: data)
        }
    }
    
#elseif os(iOS) || os(tvOS)
    
    import UIKit
    let screenScale = UIScreen.main.scale
    
#elseif os(watchOS)
    
    import WatchKit
    let screenScale = WKInterfaceDevice.current().screenScale
    
#endif


import AsyncRequest

enum ImageFetcherError: Error {
    case filterError
}


public final class ImageFetcher: Fetcher<Image> {
    let url: URL
    
    public init(url: URL) {
        self.url = url
        super.init(identifier: url.absoluteString)
    }

    public required init(identifier: String) {
        fatalError("init(identifier:) has not been implemented")
    }
    
    public override func fetch(respondIn queue: DispatchQueue, completion: @escaping (_ getFetcherResult: () throws -> FetcherResult<Image>) -> Void) -> Request<FetcherResult<Image>> {
        let allRequest = URLSessionRequest<FetcherResult<Image>>(completionHandler: completion)
        allRequest.dataTask = request(url: url) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            do {
                if let error = error {
                    throw error
                }
                guard let validData = data else {
                    throw FetchError.invalidData
                }
                guard let image = Image(data: validData, scale: screenScale) else {
                    throw FetchError.parseError
                }
                queue.async {
                    allRequest.complete(with: FetcherResult(object: image, data: data))
                }
            } catch {
                queue.async {
                    allRequest.complete(with: error)
                }
            }
        }
        return allRequest
    }
}
