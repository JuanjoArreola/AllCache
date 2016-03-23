//
//  ImageCachableDescriptor.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/8/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import UIKit

/// Convenience class to encapsulate the steps 
public class ImageCachableDescriptor: CachableDescriptor<UIImage> {
    
    var imageFetcher: ImageFetcher
    var imageResizer: ImageResizer
    var imageProcessor: ImageProcessor?
    
    required public init(url: NSURL, size: CGSize, scale: CGFloat, backgroundColor: UIColor, mode: UIViewContentMode, imageProcessor: ImageProcessor? = nil) {
        imageFetcher = ImageFetcher(url: url)
        imageResizer = ImageResizer(size: size, scale: scale, backgroundColor: backgroundColor, mode: mode)
        self.imageProcessor = imageProcessor
        var key = url.absoluteString + "#\(size.width),\(size.height),\(scale),\(mode.rawValue),\(backgroundColor.hash)"
        if let identifier = imageProcessor?.identifier {
            key += identifier
        } else if imageProcessor != nil {
            Log.warn("You should specify an identifier for the imageProcessor: \(imageProcessor)")
        }
        super.init(key: key, originalKey: url.absoluteString)
    }
    
    override func fetchAndRespondInQueue(queue: dispatch_queue_t, completion: (getObject: () throws -> UIImage) -> Void) -> Request<UIImage>? {
        return imageFetcher.fetchAndRespondInQueue(queue, completion: completion)
    }
    
    override func processObject(object: UIImage, respondInQueue queue: dispatch_queue_t, completion: (getObject: () throws -> UIImage) -> Void) {
        do {
            var image = imageResizer.scaleImage(object)
            if let processor = imageProcessor {
                image = try processor.processImage(image)
            }
            dispatch_async(queue) { completion(getObject: { return image }) }
        } catch {
            dispatch_async(queue) { completion(getObject: { throw error }) }
        }
    }
}

public class ImageProcessor {
    var identifier: String?
    func processImage(image: UIImage) throws -> UIImage { return image }
}