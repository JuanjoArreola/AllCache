//
//  UIButton+ImageCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 4/13/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit

public extension UIButton {
    
    final func requestImage(with url: URL?,
                            for controlState: UIControlState,
                            placeholder: UIImage? = nil,
                            processor: Processor<UIImage>? = nil,
                            completion: ((_ image: UIImage) -> Void)? = nil,
                            errorHandler: ((_ error: Error) -> Void)? = nil) -> Request<UIImage>? {
        self.setImage(placeholder, for: controlState)
        guard let url = url else { return nil }

        let mode = imageView?.contentMode ?? contentMode
        let descriptor = ImageCachableDescriptor(url: url, size: bounds.size, scale: UIScreen.main.scale, backgroundColor: hintColor, mode: mode, imageProcessor: processor)
        return requestImage(with: descriptor, for: controlState, placeholder: placeholder, completion: completion, errorHandler: errorHandler)
    }
    
    final func requestImage(with descriptor: ImageCachableDescriptor,
                            for controlState: UIControlState,
                            placeholder: UIImage? = nil,
                            completion: ((_ image: UIImage) -> Void)? = nil,
                            errorHandler: ((_ error: Error) -> Void)? = nil) -> Request<UIImage> {
        self.setImage(placeholder, for: controlState)
        return ImageCache.shared.object(for: descriptor) { [weak self] getImage in
            do {
                let image = try getImage()
                self?.setImage(image, for: controlState)
                if let size = self?.bounds.size, descriptor.size != size {
                    Log.warn("Size mismatch, requested: \(descriptor.size) ≠ bounds: \(size) - \(self!.description)")
                }
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
