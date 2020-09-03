//
//  UIImageView+ImageCache.swift
//  ImageCache
//
//  Created by JuanJo on 31/08/20.
//

#if os(iOS) || os(tvOS)

import UIKit
import ShallowPromises
import AllCache

public extension UIImageView {
    
    @discardableResult
    final func requestImage(with url: URL?,
                            placeholder: UIImage? = nil,
                            processor: Processor<Image>? = nil) -> Promise<UIImage>? {
        image = placeholder ?? image
        guard let url = url else { return nil }
        
        let originalSize = bounds.size
        let resizer = DefaultImageResizer(size: bounds.size, scale: UIScreen.main.scale, mode: contentMode.resizerMode)
        resizer.next = processor
        let descriptor = ElementDescriptor(key: url.absoluteString, fetcher: ImageFetcher(url: url), processor: resizer)
        
        return ImageCache.shared.instance(for: descriptor).onSuccess { [weak self] image in
            self?.image = image
            if let size = self?.bounds.size, originalSize != size {
                logger.error("Size mismatch, requested: \(originalSize) ≠ bounds: \(size) - \(descriptor.key)")
            }
        }
    }
}

#endif
