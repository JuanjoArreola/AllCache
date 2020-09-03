//
//  UIButton+ImageCache.swift
//  ImageCache
//
//  Created by JuanJo on 31/08/20.
//

#if os(iOS) || os(tvOS)

import UIKit
import ShallowPromises
import AllCache

public extension UIButton {
    
    @discardableResult
    final func requestImage(with url: URL?,
                            for controlState: UIControl.State,
                            placeholder: UIImage? = nil,
                            processor: Processor<UIImage>? = nil) -> Promise<UIImage>? {
        setImage(placeholder ?? image(for: controlState), for: controlState)
        guard let url = url else { return nil }

        let mode = imageView?.contentMode ?? contentMode
        let originalSize = bounds.size
        let resizer = DefaultImageResizer(size: bounds.size, scale: UIScreen.main.scale, mode: mode.resizerMode)
        resizer.next = processor
        let descriptor = ElementDescriptor(key: url.absoluteString, fetcher: ImageFetcher(url: url), processor: resizer)
        
        return ImageCache.shared.instance(for: descriptor).onSuccess { [weak self] image in
            self?.setImage(image, for: controlState)
            if let size = self?.bounds.size, originalSize != size {
                logger.error("Size mismatch, requested: \(originalSize) ≠ bounds: \(size) - \(self!.description)")
            }
        }
    }
}

#endif
