//
//  UIImageView+ImageCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 2/8/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation


public extension UIImageView {
    
    final func requestImageWithURL(url: NSURL?, placeholder: UIImage? = nil, imageProcessor: ImageProcessor? = nil, completion: (() -> Void)? = nil, errorHandler: ((error: ErrorType) -> Void)? = nil) -> Request<UIImage>? {
        if url == nil {
            self.image = placeholder
            return nil
        }
        if let image = placeholder {
            self.image = image
        }
        var color = self.backgroundColor ?? UIColor.clearColor()
        if color != UIColor.clearColor() && (self.contentMode == .ScaleAspectFill || self.contentMode == .ScaleToFill) {
            color = UIColor.blackColor()
        }
        let descriptor = ImageCachableDescriptor(url: url!, size: self.bounds.size, scale: UIScreen.mainScreen().scale, backgroundColor: color, mode: self.contentMode, imageProcessor: imageProcessor)
        return requestImageWithDesciptor(descriptor, placeholder: placeholder, completion: completion, errorHandler: errorHandler)
    }
    
    final func requestImageWithKey(key: String, url: NSURL?, placeholder: UIImage? = nil, imageProcessor: ImageProcessor? = nil, errorHandler: ((error: ErrorType) -> Void)? = nil) -> Request<UIImage>? {
        if url == nil {
            self.image = placeholder
            return nil
        }
        if let image = placeholder {
            self.image = image
        }
        var color = self.backgroundColor ?? UIColor.clearColor()
        if color != UIColor.clearColor() && (self.contentMode == .ScaleAspectFill || self.contentMode == .ScaleToFill) {
            color = UIColor.blackColor()
        }
        let descriptor = ImageCachableDescriptor(key: key, url: url!, size: self.bounds.size, scale: UIScreen.mainScreen().scale, backgroundColor: color, mode: self.contentMode, imageProcessor: imageProcessor)
        return requestImageWithDesciptor(descriptor, placeholder: placeholder, errorHandler: errorHandler)
    }
    
    final func requestImageWithDesciptor(descriptor: ImageCachableDescriptor, placeholder: UIImage? = nil, completion: (() -> Void)? = nil, errorHandler: ((error: ErrorType) -> Void)? = nil) -> Request<UIImage>? {
        if let image = placeholder {
            self.image = image
        }
        var color = self.backgroundColor ?? UIColor.clearColor()
        if color != UIColor.clearColor() && (self.contentMode == .ScaleAspectFill || self.contentMode == .ScaleToFill) {
            color = UIColor.blackColor()
        }
        return ImageCache.sharedInstance.objectForDescriptor(descriptor) { (getObject) -> Void in
            do {
                self.image = try getObject()
                completion?()
            } catch {
                errorHandler?(error: error)
            }
        }
    }
}