//
//  ImageResizer.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 2/8/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import CoreGraphics

public enum ImageProcessError: Error {
    case resizeError
}

func aspectFit(size: CGSize, imageSize: CGSize) -> CGRect {
    let newSize = size.ratio > imageSize.ratio ?
        CGSize(width: imageSize.width * (size.height / imageSize.height), height: size.height) :
        CGSize(width: size.width, height: imageSize.height * (size.width / imageSize.width))
    
    return CGRect(origin: (size - newSize).mid, size: newSize)
}

func aspectFill(size: CGSize, imageSize: CGSize) -> CGRect {
    let newSize = size.ratio > imageSize.ratio ?
        CGSize(width: size.width, height: imageSize.height * (size.width / imageSize.width)) :
        CGSize(width: imageSize.width * (size.height / imageSize.height), height: size.height)
    
    return CGRect(origin: (size - newSize).mid, size: newSize)
}


#if os(iOS) || os(tvOS)
    
    import UIKit

public final class DefaultImageResizer: Processor<Image> {
    
    public var size: CGSize
    public var scale: CGFloat
    
    var backgroundColor: UIColor
    var mode: UIViewContentMode
    
    public init(size: CGSize, scale: CGFloat, backgroundColor: UIColor, mode: UIViewContentMode) {
        self.size = size
        self.scale = scale
        self.backgroundColor = backgroundColor
        self.mode = mode
        super.init(identifier: "\(size.width)x\(size.height),\(scale),\(mode.rawValue),\(backgroundColor.hash)")
    }
    
    override public func process(object: Image, respondIn queue: DispatchQueue, completion: @escaping (() throws -> Image) -> Void) {
        var image = object
        if shouldScale(image: image) {
            if let scaledImage = self.scale(image: object) {
                image = scaledImage
            } else {
                queue.async { completion({ throw ImageProcessError.resizeError }) }
            }
        }
        if let nextProcessor = next {
            nextProcessor.process(object: image, respondIn: queue, completion: completion)
        } else {
            queue.async { completion({ return image }) }
        }
    }
    
    func shouldScale(image: Image) -> Bool {
        let scale = self.scale != 0.0 ? self.scale : UIScreen.main.scale
        return image.size != size || image.scale != scale
    }
    
    public func scale(image: UIImage) -> UIImage? {
        let rect = drawRect(for: image)
        var alpha: CGFloat = 0.0
        var white: CGFloat = 0.0
        backgroundColor.getWhite(&white, alpha: &alpha)
        let hasAlpha = alpha < 1.0
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        
        if backgroundColor != UIColor.clear && mode != .scaleAspectFill && mode != .scaleToFill {
            backgroundColor.set()
            UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        }
        
        image.draw(in: rect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
    open func drawRect(for image: Image) -> CGRect {
        switch mode {
        case .scaleAspectFit:
            return aspectFit(size: size, imageSize: image.size)
        case .scaleAspectFill:
            return aspectFill(size: size, imageSize: image.size)
        default:
            return CGRect(origin: CGPoint.zero, size: size)
        }
    }
}

#endif
