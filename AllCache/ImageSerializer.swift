//
//  ImageSerializer.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/13/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

#if os(OSX)
    import AppKit
#else
    import UIKit
#endif

#if os(OSX)
    
    public final class ImageSerializer: DataSerializer<Image> {
        
        
        override func serializeObject(object: Image) throws -> NSData {
            if let data = object.TIFFRepresentation {
                return data
            }
            throw DataSerializerError.SerializationError
        }
        
        override public func deserializeData(data: NSData) throws -> Image {
            if let image = Image(data: data) {
                return image
            }
            throw DataSerializerError.SerializationError
        }
    }
    
#else
    
    open class AbstractImageSerializer: DataSerializer<UIImage> {
        
        override open func deserializeData(_ data: Data) throws -> Image {
            if let image = Image(data: data) {
                return image
            }
            throw DataSerializerError.serializationError
        }
    }
    
    public final class PNGImageSerializer: AbstractImageSerializer {
        
        override public func serializeObject(_ object: Image) throws -> Data {
            if let data = UIImagePNGRepresentation(object) {
                return data
            }
            throw DataSerializerError.serializationError
        }
    }
    
    public final class JPEGImageSerializer: AbstractImageSerializer {
        
        override public func serializeObject(_ object: UIImage) throws -> Data {
            if let data = UIImagePNGRepresentation(object) {
                return data
            }
            throw DataSerializerError.serializationError
        }
    }
    
#endif
