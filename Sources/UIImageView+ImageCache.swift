//
//  UIImageView+ImageCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 2/8/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

#if os(iOS)

import UIKit

public extension UIImageView {
    
    final func requestImage(with url: URL?,
                            placeholder: UIImage? = nil,
                            imageProcessor: ImageProcessor? = nil,
                            completion: ((_ image: UIImage) -> Void)? = nil,
                            errorHandler: ((_ error: Error) -> Void)? = nil) -> Request<UIImage>? {
        image = placeholder
        guard let url = url else { return nil }
        let descriptor = ImageCachableDescriptor(url: url, size: self.bounds.size, scale: UIScreen.main.scale, backgroundColor: hintColor, mode: contentMode, imageProcessor: imageProcessor)
        return requestImage(with: descriptor, placeholder: placeholder, completion: completion, errorHandler: errorHandler)
    }
    
    final func requestImage(withKey key: String,
                            url: URL?,
                            placeholder: UIImage? = nil,
                            imageProcessor: ImageProcessor? = nil,
                            errorHandler: ((_ error: Error) -> Void)? = nil) -> Request<UIImage>? {
        image = placeholder
        guard let url = url else { return nil }
        let descriptor = ImageCachableDescriptor(key: key, url: url, size: self.bounds.size, scale: UIScreen.main.scale, backgroundColor: hintColor, mode: self.contentMode, imageProcessor: imageProcessor)
        return requestImage(with: descriptor, placeholder: placeholder, errorHandler: errorHandler)
    }
    
    final func requestImage(with descriptor: ImageCachableDescriptor,
                            placeholder: UIImage? = nil,
                            completion: ((_ image: UIImage) -> Void)? = nil,
                            errorHandler: ((_ error: Error) -> Void)? = nil) -> Request<UIImage> {
        return ImageCache.shared.object(for: descriptor) { [weak self] (getObject) -> Void in
            do {
                let image = try getObject()
                self?.image = image
                completion?(image)
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

#endif
