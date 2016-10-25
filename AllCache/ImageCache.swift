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
    
    open static let shared = try! PNGImageCache(identifier: "sharedImage")
    
    required public init(identifier: String, serializer: DataSerializer<Image>, maxCapacity: Int = 0) throws {
        try super.init(identifier: identifier, serializer: serializer, maxCapacity: maxCapacity)
    }
    
    open func imageForURL(_ url: URL, completion: @escaping (_ getImage: () throws -> Image) -> Void) -> Request<UIImage>? {
        let fetcher = ImageFetcher(url: url)
        return object(forKey: url.absoluteString, fetcher: fetcher, completion: completion)
    }
}

public final class PNGImageCache: ImageCache {
    
    convenience public init(identifier: String, maxCapacity: Int = 0) throws {
        try self.init(identifier: identifier, serializer: PNGImageSerializer(), maxCapacity: maxCapacity)
    }
}

public final class JPEGImageCache: ImageCache {
    
    convenience public init(identifier: String, maxCapacity: Int = 0) throws {
        try self.init(identifier: identifier, serializer: JPEGImageSerializer(), maxCapacity: maxCapacity)
    }
}
