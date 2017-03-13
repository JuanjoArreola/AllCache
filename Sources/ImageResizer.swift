//
//  ImageResizer.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 2/8/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

#if os(iOS) || os(OSX)
    
    import CoreGraphics
    
    public enum ImageProcessError: Error {
        case resizeError
    }

    public protocol ImageResizer {
        func scaleImage(_ image: Image) -> Image?
        var size: CGSize { get }
        var scale: CGFloat { get }
    }

    public class ImageContentModeConverter {
        
        final func aspectFit(size: CGSize, imageSize: CGSize) -> CGRect {
            let ratio = size.width / size.height
            let imageRatio = imageSize.width / imageSize.height
            
            let newSize = ratio > imageRatio ? CGSize(width: imageSize.width * (size.height / imageSize.height), height: size.height) :
                CGSize(width: size.width, height: imageSize.height * (size.width / imageSize.width))
            let origin = CGPoint(x: (size.width - newSize.width) / 2.0, y: (size.height - newSize.height) / 2.0)
            
            return CGRect(origin: origin, size: newSize)
        }
        
        final func aspectFill(size: CGSize, imageSize: CGSize) -> CGRect {
            let ratio = size.width / size.height
            let imageRatio = imageSize.width / imageSize.height
            
            let newSize = ratio > imageRatio ? CGSize(width: size.width, height: imageSize.height * (size.width / imageSize.width)) :
                CGSize(width: imageSize.width * (size.height / imageSize.height), height: size.height)
            let origin = CGPoint(x: (size.width - newSize.width) / 2.0, y: (size.height - newSize.height) / 2.0)
            
            return CGRect(origin: origin, size: newSize)
        }
    }
    
#endif


#if os(iOS)
    
    import UIKit

public final class DefaultImageResizer: ImageContentModeConverter, ImageResizer {
    
    public var size: CGSize
    public var scale: CGFloat
    var backgroundColor: UIColor
    var mode: UIViewContentMode
    
    public required init(size: CGSize, scale: CGFloat, backgroundColor: UIColor, mode: UIViewContentMode) {
        self.size = size
        self.scale = scale
        self.backgroundColor = backgroundColor
        self.mode = mode
    }
    
    public func scaleImage(_ image: UIImage) -> UIImage? {
        var rect = CGRect(origin: CGPoint.zero, size: size)
        
        switch mode {
        case .scaleAspectFit:
            rect = aspectFit(size: size, imageSize: image.size)
        case .scaleAspectFill:
            rect = aspectFill(size: size, imageSize: image.size)
        default:
            break
        }
        var alpha: CGFloat = 0.0
        var white: CGFloat = 0.0
        backgroundColor.getWhite(&white, alpha: &alpha)
        let hasAlpha = alpha < 1.0
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        
        if backgroundColor != UIColor.clear && mode != .scaleAspectFill && mode != .scaleToFill {
            backgroundColor.set()
            UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        image.draw(in: rect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
}

public final class AdaptiveImageResizer: ImageResizer {
    
    var width: CGFloat?
    var height: CGFloat?
    public var size: CGSize {
        return CGSize(width: width ?? 0, height: height ?? 0)
    }
    public var scale: CGFloat
    
    public required init(width: CGFloat, scale: CGFloat) {
        self.width = width
        self.scale = scale
    }
    
    public required init(height: CGFloat, scale: CGFloat) {
        self.height = height
        self.scale = scale
    }
    
    public func scaleImage(_ image: UIImage) -> UIImage? {
        let rect = CGRect(origin: CGPoint.zero, size: getSizeForImageSize(image.size))
        UIGraphicsBeginImageContextWithOptions(rect.size, true, scale)
        
        image.draw(in: rect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
    
    fileprivate func getSizeForImageSize(_ imageSize: CGSize) -> CGSize {
        if let width = width {
            return CGSize(width: width, height: (width * imageSize.height) / imageSize.width)
        }
        return CGSize(width: (height! * imageSize.width) / imageSize.height, height: height!)
    }
}

#endif
