//
//  UIImageView+ImageCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 2/8/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation


public extension UIImageView {
    
    final func requestImage(withURL url: URL?, placeholder: UIImage? = nil, imageProcessor: ImageProcessor? = nil, completion: (() -> Void)? = nil, errorHandler: ((_ error: Error) -> Void)? = nil) -> Request<UIImage>? {
        image = placeholder
        if url == nil {
            return nil
        }
        let descriptor = ImageCachableDescriptor(url: url!, size: self.bounds.size, scale: UIScreen.main.scale, backgroundColor: hintColor, mode: contentMode, imageProcessor: imageProcessor)
        return requestImage(withDesciptor: descriptor, placeholder: placeholder, completion: completion, errorHandler: errorHandler)
    }
    
    final func requestImageWithKey(_ key: String, url: URL?, placeholder: UIImage? = nil, imageProcessor: ImageProcessor? = nil, errorHandler: ((_ error: Error) -> Void)? = nil) -> Request<UIImage>? {
        image = placeholder
        if url == nil {
            return nil
        }
        let descriptor = ImageCachableDescriptor(key: key, url: url!, size: self.bounds.size, scale: UIScreen.main.scale, backgroundColor: hintColor, mode: self.contentMode, imageProcessor: imageProcessor)
        return requestImage(withDesciptor: descriptor, placeholder: placeholder, errorHandler: errorHandler)
    }
    
    final func requestImage(withDesciptor descriptor: ImageCachableDescriptor, placeholder: UIImage? = nil, completion: (() -> Void)? = nil, errorHandler: ((_ error: Error) -> Void)? = nil) -> Request<UIImage>? {
        return ImageCache.shared.objectForDescriptor(descriptor) { (getObject) -> Void in
            do {
                self.image = try getObject()
                completion?()
            } catch {
                errorHandler?(error)
            }
        }
    }
    
    var hintColor: UIColor {
        var color = self.backgroundColor ?? UIColor.clear
        if color != UIColor.clear && (self.contentMode == .scaleAspectFill || self.contentMode == .scaleToFill) {
            color = UIColor.black
        }
        return color
    }
}
