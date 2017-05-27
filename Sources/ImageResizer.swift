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

func center(size: CGSize, imageSize: CGSize) -> CGRect {
    let origin = CGPoint(x: (size.width - imageSize.width) / 2.0,
                         y: (size.height - imageSize.height) / 2.0)
    return CGRect(origin: origin, size: imageSize)
}

func top(size: CGSize, imageSize: CGSize) -> CGRect {
    let origin = CGPoint(x: (size.width - imageSize.width) / 2.0, y: 0.0)
    return CGRect(origin: origin, size: imageSize)
}

func bottom(size: CGSize, imageSize: CGSize) -> CGRect {
    let origin = CGPoint(x: (size.width - imageSize.width) / 2.0,
                         y: size.height - imageSize.height)
    return CGRect(origin: origin, size: imageSize)
}

func left(size: CGSize, imageSize: CGSize) -> CGRect {
    let origin = CGPoint(x: 0, y: (size.height - imageSize.height) / 2.0)
    return CGRect(origin: origin, size: imageSize)
}

func right(size: CGSize, imageSize: CGSize) -> CGRect {
    let origin = CGPoint(x: size.width - imageSize.width,
                         y: (size.height - imageSize.height) / 2.0)
    return CGRect(origin: origin, size: imageSize)
}

func topLeft(size: CGSize, imageSize: CGSize) -> CGRect {
    return CGRect(origin: CGPoint.zero, size: imageSize)
}

func topRight(size: CGSize, imageSize: CGSize) -> CGRect {
    let origin = CGPoint(x: size.width - imageSize.width, y: 0)
    return CGRect(origin: origin, size: imageSize)
}

func bottomLeft(size: CGSize, imageSize: CGSize) -> CGRect {
    let origin = CGPoint(x: 0, y: size.height - imageSize.height)
    return CGRect(origin: origin, size: imageSize)
}

func bottomRight(size: CGSize, imageSize: CGSize) -> CGRect {
    let origin = CGPoint(x: size.width - imageSize.width,
                         y: size.height - imageSize.height)
    return CGRect(origin: origin, size: imageSize)
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
        var alpha: CGFloat = 0.0
        var white: CGFloat = 0.0
        backgroundColor.getWhite(&white, alpha: &alpha)
        let hasAlpha = alpha < 1.0
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        
        if backgroundColor != UIColor.clear && mode != .scaleAspectFill && mode != .scaleToFill {
            backgroundColor.set()
            UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        }
        
        image.draw(in: drawRect(for: image))
        
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
        case .scaleToFill:
            return CGRect(origin: CGPoint.zero, size: size)
        case .redraw:
            return CGRect(origin: CGPoint.zero, size: size)
        case .center:
            return center(size: size, imageSize: image.size)
        case .top:
            return top(size: size, imageSize: image.size)
        case .bottom:
            return bottom(size: size, imageSize: image.size)
        case .left:
            return left(size: size, imageSize: image.size)
        case .right:
            return right(size: size, imageSize: image.size)
        case .topLeft:
            return topLeft(size: size, imageSize: image.size)
        case .topRight:
            return topRight(size: size, imageSize: image.size)
        case .bottomLeft:
            return bottomLeft(size: size, imageSize: image.size)
        case .bottomRight:
            return bottomRight(size: size, imageSize: image.size)
        }
    }
}

#endif
