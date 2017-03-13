//
//  UIButton+ImageCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 4/13/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

#if os(iOS)

import UIKit

public extension UIButton {
    
    final func requestImage(withURL url: URL?, placeholder: UIImage? = nil, imageProcessor: ImageProcessor? = nil, completion: (() -> Void)? = nil, errorHandler: ((_ error: Error) -> Void)? = nil) -> Request<UIImage>? {
        if url == nil {
            self.setImage(placeholder, for: UIControlState())
            return nil
        }
        if let image = placeholder {
            self.setImage(image, for: UIControlState())
        }
        let mode = imageView?.contentMode ?? contentMode
        var color = self.backgroundColor ?? UIColor.clear
        if color != UIColor.clear && (mode == .scaleAspectFill || mode == .scaleToFill) {
            color = UIColor.black
        }
        let descriptor = ImageCachableDescriptor(url: url!, size: bounds.size, scale: UIScreen.main.scale, backgroundColor: color, mode: mode, imageProcessor: imageProcessor)
        return requestImage(withDesciptor: descriptor, placeholder: placeholder, completion: completion, errorHandler: errorHandler)
    }
    
    final func requestImage(withDesciptor descriptor: ImageCachableDescriptor, placeholder: UIImage? = nil, completion: (() -> Void)? = nil, errorHandler: ((_ error: Error) -> Void)? = nil) -> Request<UIImage>? {
        if let image = placeholder {
            self.setImage(image, for: UIControlState())
        }
        var color = self.backgroundColor ?? UIColor.clear
        if color != UIColor.clear && (self.contentMode == .scaleAspectFill || self.contentMode == .scaleToFill) {
            color = UIColor.black
        }
        return ImageCache.shared.objectForDescriptor(descriptor) { (getObject) -> Void in
            do {
                self.setImage(try getObject(), for: UIControlState())
                completion?()
            } catch {
                errorHandler?(error)
            }
        }
    }
}

#endif
