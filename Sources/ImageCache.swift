//
//  ImageCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 2/6/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

#if os(OSX)
    import AppKit
    public typealias Image = NSImage
    public typealias Color = NSColor
#elseif os(iOS) || os(tvOS)
    import UIKit
    public typealias Image = UIImage
    public typealias Color = UIColor
#endif

#if os(OSX) || os(iOS) || os(tvOS)
    
import AsyncRequest

open class ImageCache: Cache<Image> {
    
    #if os(iOS) || os(tvOS)
    open static let shared = try! ImageCache(identifier: "sharedImage", serializer: PNGImageSerializer())
    #else
    open static let shared = try! ImageCache(identifier: "sharedImage", serializer: ImageSerializer())
    #endif
    
    required public init(identifier: String, serializer: DataSerializer<Image>, maxCapacity: Int = 0) throws {
        try super.init(identifier: identifier, serializer: serializer, maxCapacity: maxCapacity)
    }
    
    open func image(for url: URL, completion: @escaping (_ getImage: () throws -> Image) -> Void) -> Request<Image>? {
        let fetcher = ImageFetcher(url: url)
        return object(forKey: url.absoluteString, fetcher: fetcher, processor: nil, completion: completion)
    }
}
    
#endif
