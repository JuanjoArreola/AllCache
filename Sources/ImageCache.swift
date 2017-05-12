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

open class ImageCache: Cache<Image> {
    
    #if os(iOS) || os(tvOS)
    open static let shared = try! PNGImageCache(identifier: "sharedImage")
    #else
    open static let shared = try! TIFFImageCache(identifier: "sharedImage")
    #endif
    
    required public init(identifier: String, serializer: DataSerializer<Image>, maxCapacity: Int = 0) throws {
        try super.init(identifier: identifier, serializer: serializer, maxCapacity: maxCapacity)
    }
    
    open func image(for url: URL, completion: @escaping (_ getImage: () throws -> Image) -> Void) -> Request<Image>? {
        let fetcher = ImageFetcher(url: url)
        return object(forKey: url.absoluteString, fetcher: fetcher, completion: completion)
    }
}
    
#endif

#if os(iOS) || os(tvOS)

public final class PNGImageCache: ImageCache {
    
    convenience public init(identifier: String) throws {
        try self.init(identifier: identifier, serializer: PNGImageSerializer(), maxCapacity: 0)
    }
}

public final class JPEGImageCache: ImageCache {
    
    convenience public init(identifier: String) throws {
        try self.init(identifier: identifier, serializer: JPEGImageSerializer(), maxCapacity: 0)
    }
}
    
#elseif os(OSX)
    
    public final class TIFFImageCache: ImageCache {
        
        convenience public init(identifier: String, maxCapacity: Int = 0) throws {
            try self.init(identifier: identifier, serializer: ImageSerializer(), maxCapacity: maxCapacity)
        }
    }

#endif
