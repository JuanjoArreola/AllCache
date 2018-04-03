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
    
let resizeMethods: [UIViewContentMode: (CGSize, CGSize) -> CGRect] = [
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
    
    public var size: CGSize
    public var scale: CGFloat
    
    var mode: UIViewContentMode
    
    public init(size: CGSize, scale: CGFloat, mode: UIViewContentMode) {
        self.size = size
        self.scale = scale
        self.mode = mode
        super.init(identifier: "\(size.width)x\(size.height),\(scale),\(mode.rawValue)")
    }
    
    override public func process(object: Image) throws -> Image {
        var image = object
        if shouldScale(image: image) {
            guard let scaledImage = self.scale(image: object) else {
                throw ImageProcessError.resizeError
            }
            image = scaledImage
        }
        if let nextProcessor = next {
            return try nextProcessor.process(object: image)
        }
        return image
    }
    
    func shouldScale(image: Image) -> Bool {
        let scale = self.scale != 0.0 ? self.scale : UIScreen.main.scale
        return image.size != size || image.scale != scale
    }
    
    public func scale(image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        image.draw(in: drawRect(for: image))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
    open func drawRect(for image: Image) -> CGRect {
        if let method = resizeMethods[mode] {
            return method(size, image.size)
        }
        return CGRect(origin: CGPoint.zero, size: size)
    }
}

#endif
