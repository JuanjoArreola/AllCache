//
//  UIButton+ImageCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 4/13/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import AsyncRequest

public extension UIButton {
    
    final func requestImage(with url: URL?,
                            for controlState: UIControlState,
                            placeholder: UIImage? = nil,
                            processor: Processor<UIImage>? = nil) -> Request<UIImage>? {
        setImage(placeholder ?? image(for: controlState), for: controlState)
        guard let url = url else { return nil }

        let mode = imageView?.contentMode ?? contentMode
        let originalSize = bounds.size
        let resizer = DefaultImageResizer(size: bounds.size, scale: UIScreen.main.scale, backgroundColor: hintColor, mode: mode)
        resizer.next = processor
        let descriptor = CachableDescriptor<Image>(key: url.path, fetcher: ImageFetcher(url: url), processor: resizer)
        
        return ImageCache.shared.object(for: descriptor, completion: { [weak self] image in
            self?.setImage(image, for: controlState)
            if let size = self?.bounds.size, originalSize != size {
                Log.warn("Size mismatch, requested: \(originalSize) ≠ bounds: \(size) - \(self!.description)")
            }
        })
    }
}

#endif
