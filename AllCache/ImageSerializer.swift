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
    
    public class AbstractImageSerializer: DataSerializer<UIImage> {
        
        override public func deserializeData(data: NSData) throws -> Image {
            if let image = Image(data: data) {
                return image
            }
            throw DataSerializerError.SerializationError
        }
    }
    
    public final class PNGImageSerializer: AbstractImageSerializer {
        
        override public func serializeObject(object: Image) throws -> NSData {
            if let data = UIImagePNGRepresentation(object) {
                return data
            }
            throw DataSerializerError.SerializationError
        }
    }
    
    public final class JPEGImageSerializer: AbstractImageSerializer {
        
        override public func serializeObject(object: UIImage) throws -> NSData {
            if let data = UIImagePNGRepresentation(object) {
                return data
            }
            throw DataSerializerError.SerializationError
        }
    }
    
#endif