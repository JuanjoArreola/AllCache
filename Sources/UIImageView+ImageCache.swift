//
//  UIImageView+ImageCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 2/8/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import AsyncRequest

public extension UIImageView {
    
    final func requestImage(with url: URL?,
                            placeholder: UIImage? = nil,
                            processor: Processor<Image>? = nil,
                            completion: ((_ getImage: () throws -> UIImage) -> Void)? = nil) -> Request<UIImage>? {
        image = placeholder ?? image
        guard let url = url else { return nil }
        
        let originalSize = bounds.size
        let resizer = DefaultImageResizer(size: bounds.size, scale: UIScreen.main.scale, backgroundColor: hintColor, mode: contentMode)
        resizer.next = processor
        let descriptor = CachableDescriptor<Image>(key: url.absoluteString, fetcher: ImageFetcher(url: url), processor: resizer)
        
        return ImageCache.shared.object(for: descriptor, completion: { [weak self] getImage in
            do {
                let image = try getImage()
                self?.image = image
                if let size = self?.bounds.size, originalSize != size {
                    Log.warn("Size mismatch, requested: \(originalSize) ≠ bounds: \(size) - \(descriptor.key)")
                }
            } catch {}
            completion?(getImage)
        })
    }
}
    
    extension UIView {
        var hintColor: UIColor {
            var color = self.backgroundColor ?? UIColor.clear
            if color != UIColor.clear && (self.contentMode == .scaleAspectFill || self.contentMode == .scaleToFill) {
                color = UIColor.black
            }
            return color
        }
    }

#endif
