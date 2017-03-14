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
    
    final func requestImage(with url: URL?,
                            placeholder: UIImage? = nil,
                            processor: ImageProcessor? = nil,
                            completion: ((_ image: UIImage) -> Void)? = nil,
                            errorHandler: ((_ error: Error) -> Void)? = nil) -> Request<UIImage>? {
        self.setImage(placeholder, for: UIControlState())
        guard let url = url else { return nil }

        let mode = imageView?.contentMode ?? contentMode
        let descriptor = ImageCachableDescriptor(url: url, size: bounds.size, scale: UIScreen.main.scale, backgroundColor: hintColor, mode: mode, imageProcessor: processor)
        return requestImage(with: descriptor, placeholder: placeholder, completion: completion, errorHandler: errorHandler)
    }
    
    final func requestImage(with descriptor: ImageCachableDescriptor,
                            placeholder: UIImage? = nil,
                            completion: ((_ image: UIImage) -> Void)? = nil,
                            errorHandler: ((_ error: Error) -> Void)? = nil) -> Request<UIImage> {
        self.setImage(placeholder, for: UIControlState())
        return ImageCache.shared.object(for: descriptor) { [weak self] (getObject) -> Void in
            do {
                let image = try getObject()
                self?.setImage(image, for: UIControlState())
                completion?(image)
            } catch {
                errorHandler?(error)
            }
        }
    }
    
    var hintColor: UIColor {
        var color = backgroundColor ?? UIColor.clear
        if color != UIColor.clear && (contentMode == .scaleAspectFill || contentMode == .scaleToFill) {
            color = UIColor.black
        }
        return color
    }
}

#endif
