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
#else
    import UIKit
    public typealias Image = UIImage
#endif



open class ImageCache: Cache<Image> {
    
    open static let sharedInstance = try! PNGImageCache(identifier: "sharedImage")
    
    public init(identifier: String, serializer: DataSerializer<Image>, maxCapacity: Int = 0) throws {
        try super.init(identifier: identifier, dataSerializer: serializer, maxCapacity: maxCapacity)
    }
    
    open func imageForURL(_ url: URL, completion: (_ getImage: () throws -> Image) -> Void) -> Request<UIImage>? {
        let fetcher = ImageFetcher(url: url)
        return objectForKey(url.absoluteString, objectFetcher: fetcher, completion: completion)
    }
}

public final class PNGImageCache: ImageCache {
    
    public init(identifier: String, maxCapacity: Int = 0) throws {
        try super.init(identifier: identifier, serializer: PNGImageSerializer(), maxCapacity: maxCapacity)
    }
}

public final class JPEGImageCache: ImageCache {
    
    public init(identifier: String, maxCapacity: Int = 0) throws {
        try super.init(identifier: identifier, serializer: JPEGImageSerializer(), maxCapacity: maxCapacity)
    }
}
