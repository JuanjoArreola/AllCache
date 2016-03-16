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

public final class ImageSerializer: DataSerializer<Image> {
    
    #if os(OSX)
    override func serializeObject(object: Image) throws -> NSData {
        if let data = object.TIFFRepresentation {
            return data
        }
        throw DataSerializerError.SerializationError
    }
    #else
    override public func serializeObject(object: Image) throws -> NSData {
        if let data = UIImagePNGRepresentation(object) {
            return data
        }
        throw DataSerializerError.SerializationError
    }
    #endif
    
    override public func deserializeData(data: NSData) throws -> Image {
        if let image = Image(data: data) {
            return image
        }
        throw DataSerializerError.SerializationError
    }
}