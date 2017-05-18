//
//  ImageCachableDescriptor.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/8/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

#if os(iOS) || os(tvOS)
    
import UIKit

let fileNameRegex = try! NSRegularExpression(pattern: "[/:;?*|']", options: [])

/// Convenience class to encapsulate the steps 
open class ImageCachableDescriptor: CachableDescriptor<Image> {
    
//    var imageFetcher: ImageFetcher
//    var imageResizer: ImageResizer
//    var imageProcessor: Processor<Image>?
    public var size: CGSize
    
    convenience public init(url: URL, size: CGSize, scale: CGFloat, backgroundColor: UIColor, mode: UIViewContentMode, imageProcessor: Processor<Image>? = nil) {
        self.init(key: url.path, url: url, size: size, scale: scale, backgroundColor: backgroundColor, mode: mode, imageProcessor: imageProcessor)
    }
    
    required public init(key: String, url: URL, size: CGSize, scale: CGFloat, backgroundColor: UIColor, mode: UIViewContentMode, imageProcessor: Processor<Image>? = nil) {
        self.size = size
        
//        imageFetcher = ImageFetcher(url: url)
        let resizer = DefaultImageResizer(size: size, scale: scale, backgroundColor: backgroundColor, mode: mode)
        resizer.next = imageProcessor
//        self.imageProcessor = imageProcessor
        let validKey = fileNameRegex.stringByReplacingMatches(in: key, options: [], range: key.wholeNSRange, withTemplate: "")
//        let newKey: String
//        if let identifier = imageProcessor?.identifier {
//            newKey = "i\(identifier),\(size.width)x\(size.height),\(scale),\(mode.rawValue),\(backgroundColor.hash)_\(validKey)"
//        } else {
//            newKey = "i\(size.width)x\(size.height),\(scale),\(mode.rawValue),\(backgroundColor.hash)_\(validKey)"
//        }
        super.init(key: "\(resizer.key)_\(key)", fetcher: ImageFetcher(url: url), processor: resizer)
    }

//    required public init(key: String, originalKey: String) {
//        fatalError("init(key:originalKey:) has not been implemented")
//    }
    
    public required init(key: String, fetcher: Fetcher<Image>, processor: Processor<Image>?) {
        fatalError("Not implemented")
    }
    
//    open override func fetchAndRespond(in queue: DispatchQueue, completion: @escaping (_ getFetcherResult: () throws -> FetcherResult<UIImage>) -> Void) -> Request<FetcherResult<UIImage>> {
//        return imageFetcher.fetch(respondIn: queue, completion: completion)
//    }
    
//    override open func process(object: UIImage, respondIn queue: DispatchQueue, completion: @escaping (_ getObject: () throws -> UIImage) -> Void) {
//        do {
//            var image = object
//            let scale = imageResizer.scale != 0.0 ? imageResizer.scale : UIScreen.main.scale
//            if image.size != imageResizer.size || image.scale != scale {
//                if let scaledImage = imageResizer.scaleImage(object) {
//                    image = scaledImage
//                } else {
//                    throw ImageProcessError.resizeError
//                }
//            }
//            if let processor = imageProcessor {
//                image = try processor.processImage(image)
//            }
//            queue.async { completion({ return image }) }
//        } catch {
//            queue.async { completion({ throw error }) }
//        }
//    }
}

//open class ImageProcessor: Processor<UIImage> {
//        
//    open func processImage(_ image: UIImage) throws -> UIImage { return image }
//}

#endif
