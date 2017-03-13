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
#elseif os(iOS)
    import UIKit
    public typealias Image = UIImage
    public typealias Color = UIColor
#endif

#if os(OSX) || os(iOS)

open class ImageCache: Cache<Image> {
    
    #if os(iOS)
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

#if os(iOS)

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
    
#elseif os(OSX)
    
    public final class TIFFImageCache: ImageCache {
        
        convenience public init(identifier: String, maxCapacity: Int = 0) throws {
            try self.init(identifier: identifier, serializer: ImageSerializer(), maxCapacity: maxCapacity)
        }
    }

#endif
