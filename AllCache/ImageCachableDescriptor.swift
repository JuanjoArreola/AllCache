//
//  ImageCachableDescriptor.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/8/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import UIKit

/// Convenience class to encapsulate the steps 
open class ImageCachableDescriptor: CachableDescriptor<UIImage> {
    
    var imageFetcher: ImageFetcher
    var imageResizer: ImageResizer
    var imageProcessor: ImageProcessor?
    
    required convenience public init(url: URL, size: CGSize, scale: CGFloat, backgroundColor: UIColor, mode: UIViewContentMode, imageProcessor: ImageProcessor? = nil) {
        self.init(key: url.absoluteString, url: url, size: size, scale: scale, backgroundColor: backgroundColor, mode: mode, imageProcessor: imageProcessor)
    }
    
    required public init(key: String, url: URL, size: CGSize, scale: CGFloat, backgroundColor: UIColor, mode: UIViewContentMode, imageProcessor: ImageProcessor? = nil) {
        imageFetcher = ImageFetcher(url: url)
        imageResizer = DefaultImageResizer(size: size, scale: scale, backgroundColor: backgroundColor, mode: mode)
        self.imageProcessor = imageProcessor
        var newKey = key + "#\(size.width),\(size.height),\(scale),\(mode.rawValue),\(backgroundColor.hash)"
        if let identifier = imageProcessor?.identifier {
            newKey += identifier
        } else if imageProcessor != nil {
            Log.warn("You should specify an identifier for the imageProcessor: \(imageProcessor)")
        }
        super.init(key: newKey, originalKey: key)
    }

    required public init(key: String, originalKey: String) {
        fatalError("init(key:originalKey:) has not been implemented")
    }
    
    open override func fetchAndRespond(in queue: DispatchQueue, completion: @escaping (_ getFetcherResult: () throws -> FetcherResult<UIImage>) -> Void) -> Request<FetcherResult<UIImage>> {
        return imageFetcher.fetchAndRespond(inQueue: queue, completion: completion)
    }
    
    override func process(object: UIImage, respondIn queue: DispatchQueue, completion: @escaping (_ getObject: () throws -> UIImage) -> Void) {
        do {
            var image = object
            let scale = imageResizer.scale != 0.0 ? imageResizer.scale : UIScreen.main.scale
            if image.size != imageResizer.size || image.scale != scale {
                image = imageResizer.scaleImage(object)
            }
            if let processor = imageProcessor {
                image = try processor.processImage(image)
            }
            queue.async { completion({ return image }) }
        } catch {
            queue.async { completion({ throw error }) }
        }
    }
}

open class ImageProcessor {
    var identifier: String?
    open func processImage(_ image: UIImage) throws -> UIImage { return image }
    
    public init(identifier: String?) {
        self.identifier = identifier
    }
    
    open var description: String {
        return "Processor: \(identifier)"
    }
}
