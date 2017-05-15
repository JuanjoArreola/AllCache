//
//  CGSize+Util.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 5/13/17.
//
//

#if os(iOS) || os(OSX) || os(tvOS)
    
    import CoreGraphics
    
    public func -(first: CGSize, second: CGSize) -> CGSize {
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
    
#endif
