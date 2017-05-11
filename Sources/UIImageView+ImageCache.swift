//
//  UIImageView+ImageCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 2/8/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit

public extension UIImageView {
    
    final func requestImage(with url: URL?,
                            placeholder: UIImage? = nil,
                            imageProcessor: ImageProcessor? = nil,
                            completion: ((_ getImage: () throws -> UIImage) -> Void)? = nil) -> Request<UIImage>? {
        image = placeholder
        guard let url = url else { return nil }
        let descriptor = ImageCachableDescriptor(url: url, size: bounds.size, scale: UIScreen.main.scale, backgroundColor: hintColor, mode: contentMode, imageProcessor: imageProcessor)
        return requestImage(with: descriptor, placeholder: placeholder, completion: completion)
    }
    
    final func requestImage(withKey key: String,
                            url: URL?,
                            placeholder: UIImage? = nil,
                            imageProcessor: ImageProcessor? = nil,
                            completion: ((_ getImage: () throws -> UIImage) -> Void)? = nil) -> Request<UIImage>? {
        image = placeholder
        guard let url = url else { return nil }
        let descriptor = ImageCachableDescriptor(key: key, url: url, size: bounds.size, scale: UIScreen.main.scale, backgroundColor: hintColor, mode: contentMode, imageProcessor: imageProcessor)
        return requestImage(with: descriptor, placeholder: placeholder, completion: completion)
    }
    
    final func requestImage(with descriptor: ImageCachableDescriptor,
                            placeholder: UIImage? = nil,
                            completion: ((_ getImage: () throws -> UIImage) -> Void)? = nil) -> Request<UIImage> {
        image = placeholder
        return ImageCache.shared.object(for: descriptor) { [weak self] getImage in
            do {
                let image = try getImage()
                self?.image = image
                if let size = self?.bounds.size, descriptor.size != size {
                    Log.warn("Size mismatch, requested: \(descriptor.size) ≠ bounds: \(size) - \(descriptor.key)")
                }
            } catch { }
            completion?(getImage)
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
