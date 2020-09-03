//
//  ImageResizer.swift
//  ImageCache
//
//  Created by JuanJo on 31/08/20.
//

import Foundation
import AllCache

#if os(OSX)

import AppKit

#elseif os(iOS) || os(tvOS) || os(watchOS)

import UIKit

#endif

public enum ImageProcessError: Error {
    case resizeError
}

private let resizeFunctions: [DefaultImageResizer.ContentMode: (CGSize, CGSize) -> CGRect] = [
    .scaleAspectFit: aspectFit,
    .scaleAspectFill: aspectFill,
    .center: center,
    .top: top,
    .bottom: bottom,
    .left: left,
    .right: right,
    .topLeft: topLeft,
    .topRight: topRight,
    .bottomLeft: bottomLeft,
    .bottomRight: bottomRight,
]

public final class DefaultImageResizer: Processor<Image> {
    
    public enum ContentMode: Int {
        case scaleToFill, scaleAspectFit, scaleAspectFill
        case redraw
        case center, top, bottom, left, right
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    public var size: CGSize
    public var scale: CGFloat
    
    public var mode: ContentMode
    
    public init(size: CGSize, scale: CGFloat, mode: ContentMode) {
        self.size = size
        self.scale = scale
        self.mode = mode
        super.init(identifier: "\(size.width)x\(size.height),\(scale),\(mode.rawValue)")
    }
    
    public override func process(_ instance: Image) throws -> Image {
        var image = instance
        if shouldScale(image: image) {
            guard let scaledImage = self.scale(image: instance) else {
                throw ImageProcessError.resizeError
            }
            image = scaledImage
        }
        if let nextProcessor = next {
            return try nextProcessor.process(image)
        }
        return image
    }
    
    func shouldScale(image: Image) -> Bool {
        #if os(OSX)
            
        return image.size != size
            
        #elseif os(iOS) || os(tvOS) || os(watchOS)
        
        let scale = self.scale != 0.0 ? self.scale : UIScreen.main.scale
        return image.size != size || image.scale != scale
        
        #endif
    }
    
    #if os(iOS) || os(tvOS) || os(watchOS)
    public func scale(image: Image) -> Image? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        image.draw(in: drawRect(for: image))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
        
    #else
    public func scale(image: Image) -> Image? {
        let scaledImage = Image(size: size)
        scaledImage.lockFocus()
        guard let context = NSGraphicsContext.current else {
            return nil
        }
        context.imageInterpolation = .high
        image.draw(in: drawRect(for: image), from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1)
        scaledImage.unlockFocus()
        return scaledImage
    }
    #endif
    
    public func drawRect(for image: Image) -> CGRect {
        if let method = resizeFunctions[mode] {
            return method(size, image.size)
        }
        return CGRect(origin: CGPoint.zero, size: size)
    }
}
