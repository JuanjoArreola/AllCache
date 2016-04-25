//
//  ImageResizer.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 2/8/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

public protocol ImageResizer {
    func scaleImage(image: UIImage) -> UIImage
}

public final class DefaultImageResizer: ImageResizer {
    
    var size: CGSize
    var scale: CGFloat
    var backgroundColor: UIColor
    var mode: UIViewContentMode
    
    public required init(size: CGSize, scale: CGFloat, backgroundColor: UIColor, mode: UIViewContentMode) {
        self.size = size
        self.scale = scale
        self.backgroundColor = backgroundColor
        self.mode = mode
    }
    
    public func scaleImage(image: UIImage) -> UIImage {
        var rect = CGRect(origin: CGPointZero, size: size)
        
        switch mode {
        case .ScaleAspectFit:
            rect = aspectFit(size: size, imageSize: image.size)
        case .ScaleAspectFill:
            rect = aspectFill(size: size, imageSize: image.size)
        default:
            break
        }
        var alpha: CGFloat = 0.0
        var white: CGFloat = 0.0
        backgroundColor.getWhite(&white, alpha: &alpha)
        let hasAlpha = alpha < 1.0
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        
        if backgroundColor != UIColor.clearColor() && mode != .ScaleAspectFill && mode != .ScaleToFill {
            backgroundColor.set()
            UIRectFill(CGRectMake(0, 0, size.width, size.height))
        }
        
        image.drawInRect(rect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
    final func aspectFit(size size: CGSize, imageSize: CGSize) -> CGRect {
        let ratio = size.width / size.height
        let imageRatio = imageSize.width / imageSize.height
        
        let newSize = ratio > imageRatio ? CGSizeMake(imageSize.width * (size.height / imageSize.height), size.height) :
            CGSizeMake(size.width, imageSize.height * (size.width / imageSize.width))
        let origin = CGPointMake((size.width - newSize.width) / 2.0, (size.height - newSize.height) / 2.0)
        
        return CGRect(origin: origin, size: newSize)
    }
    
    final func aspectFill(size size: CGSize, imageSize: CGSize) -> CGRect {
        let ratio = size.width / size.height
        let imageRatio = imageSize.width / imageSize.height
        
        let newSize = ratio > imageRatio ? CGSizeMake(size.width, imageSize.height * (size.width / imageSize.width)) :
            CGSizeMake(imageSize.width * (size.height / imageSize.height), size.height)
        let origin = CGPointMake((size.width - newSize.width) / 2.0, (size.height - newSize.height) / 2.0)
        
        return CGRect(origin: origin, size: newSize)
    }
}

public final class AdaptiveImageResizer: ImageResizer {
    
    var width: CGFloat?
    var height: CGFloat?
    var scale: CGFloat
    
    public required init(width: CGFloat, scale: CGFloat) {
        self.width = width
        self.scale = scale
    }
    
    public required init(height: CGFloat, scale: CGFloat) {
        self.height = height
        self.scale = scale
    }
    
    public func scaleImage(image: UIImage) -> UIImage {
        let rect = CGRect(origin: CGPointZero, size: getSizeForImageSize(image.size))
        UIGraphicsBeginImageContextWithOptions(rect.size, true, scale)
        
        image.drawInRect(rect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
    private func getSizeForImageSize(imageSize: CGSize) -> CGSize {
        if let width = width {
            return CGSize(width: width, height: (width * imageSize.height) / imageSize.width)
        }
        return CGSize(width: (height! * imageSize.width) / imageSize.height, height: height!)
    }
}
