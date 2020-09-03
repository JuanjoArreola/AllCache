//
//  ImageCache.swift
//  ImageCache
//
//  Created by JuanJo on 31/08/20.
//

import Foundation
import AllCache
import ShallowPromises

#if os(OSX)
    
import AppKit
public typealias Image = NSImage
    
#elseif os(iOS) || os(tvOS) || os(watchOS)
    
import UIKit
public typealias Image = UIImage
    
#endif

open class ImageCache: Cache<Image, ImageSerializer> {
    
    #if os(iOS) || os(tvOS) || os(watchOS)
    public static let shared = try! ImageCache(identifier: "sharedImage", serializer: PNGImageSerializer())
    #else
    public static let shared = try! ImageCache(identifier: "sharedImage", serializer: ImageSerializer())
    #endif
    
    public convenience init(identifier: String, serializer: ImageSerializer, maxCapacity: Int = 0) throws {
        try self.init(identifier: identifier, serializer: serializer)
    }
    
    open func image(for url: URL) -> Promise<Image>? {
        let descriptor = ElementDescriptor(key: url.absoluteString, fetcher: ImageFetcher(url: url), processor: nil)
        return instance(for: descriptor)
    }
}
