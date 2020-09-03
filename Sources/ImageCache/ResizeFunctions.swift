//
//  ResizeFunctions.swift
//  ImageCache
//
//  Created by Juan Jose Arreola Simon on 02/09/20.
//

import Foundation
import CoreGraphics

func -(first: CGSize, second: CGSize) -> CGSize {
    return CGSize(width: first.width - second.width, height: first.height - second.height)
}

extension CGSize {
    var mid: CGPoint {
        return CGPoint(x: width / 2.0, y: height / 2.0)
    }
    
    var ratio: CGFloat {
        return width / height
    }
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
