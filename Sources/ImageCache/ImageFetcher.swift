//
//  ImageFetcher.swift
//  ImageCache
//
//  Created by JuanJo on 31/08/20.
//

import Foundation
import NewCache
import ShallowPromises

#if os(OSX)
    
import AppKit

let screenScale = NSScreen.main?.backingScaleFactor ?? 1.0

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

public final class ImageFetcher: Fetcher {
    
    public typealias T = Image
    
    let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public func fetch() -> Promise<FetcherResult<Image>> {
        let promise = Promise<FetcherResult<Image>>()
        promise.littlePromise = request(url: url, completion: { (data: Data?, _, error: Error?) in
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
                promise.fulfill(with: FetcherResult(instance: image, data: data))
            } catch {
                promise.complete(with: error)
            }
        })
        
        return promise
    }
}

extension URLSessionTask: Cancellable {}
