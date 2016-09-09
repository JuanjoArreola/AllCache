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
    
    required convenience public init(url: NSURL, size: CGSize, scale: CGFloat, backgroundColor: UIColor, mode: UIViewContentMode, imageProcessor: ImageProcessor? = nil) {
        self.init(key: url.absoluteString, url: url, size: size, scale: scale, backgroundColor: backgroundColor, mode: mode, imageProcessor: imageProcessor)
    }
    
    required public init(key: String, url: NSURL, size: CGSize, scale: CGFloat, backgroundColor: UIColor, mode: UIViewContentMode, imageProcessor: ImageProcessor? = nil) {
        imageFetcher = ImageFetcher(url: url)
        imageResizer = DefaultImageResizer(size: size, scale: scale, backgroundColor: backgroundColor, mode: mode)
        self.imageProcessor = imageProcessor
        var newKey = key + "#\(size.width),\(size.height),\(scale),\(mode.rawValue),\(backgroundColor.hash)"
        if let identifier = imageProcessor?.identifier {
            newKey += identifier
        } else if imageProcessor != nil {
            Log.warn("You should specify an identifier for the imageProcessor: \(imageProcessor)")
        }
        let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
        if let name = components?.path?.componentsSeparatedByString("/").last {
            Log.debug("request: \(name) #\(size.width),\(size.height),\(scale),\(mode.rawValue),\(backgroundColor.hash)", aspect: LogAspect.SizeErrors)
        }
        super.init(key: newKey, originalKey: key)
    }
    
    public override func fetchAndRespondInQueue(queue: dispatch_queue_t, completion: (getFetcherResult: () throws -> FetcherResult<UIImage>) -> Void) -> Request<FetcherResult<UIImage>> {
        return imageFetcher.fetchAndRespondInQueue(queue, completion: completion)
    }
    
    override func processObject(object: UIImage, respondInQueue queue: dispatch_queue_t, completion: (getObject: () throws -> UIImage) -> Void) {
        do {
            var image = object
            let scale = imageResizer.scale != 0.0 ? imageResizer.scale : UIScreen.mainScreen().scale
            if !CGSizeEqualToSize(image.size, imageResizer.size) || image.scale != scale {
                image = imageResizer.scaleImage(object)
            }
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
    public func processImage(image: UIImage) throws -> UIImage { return image }
    
    public init(identifier: String?) {
        self.identifier = identifier
    }
    
    public var description: String {
        return "Processor: \(identifier)"
    }
}