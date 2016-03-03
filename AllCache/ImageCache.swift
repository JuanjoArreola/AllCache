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

public final class ImageCache: Cache<Image> {
    
    public static let sharedInstance = try! ImageCache(identifier: "sharedImage")
    
    public required init(identifier: String, maxCapacity: Int = 0) throws {
        try super.init(identifier: identifier, dataSerializer: ImageSerializer(), maxCapacity: maxCapacity)
    }
}
