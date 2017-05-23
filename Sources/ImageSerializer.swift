//
//  ImageSerializer.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/13/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

#if os(OSX)
    import AppKit
#elseif os(iOS) || os(tvOS)
    import UIKit
#endif

#if os(OSX)
    
    public final class ImageSerializer: DataSerializer<Image> {
        
        public override func serialize(object: Image) throws -> Data {
            if let data = object.tiffRepresentation {
                return data
            }
            throw DataSerializerError.serializationError
        }
        
        public override func deserialize(data: Data) throws -> Image {
            if let image = Image(data: data) {
                return image
            }
            throw DataSerializerError.serializationError
        }
    }
    
#elseif os(iOS) || os(tvOS)
    
    open class AbstractImageSerializer: DataSerializer<UIImage> {
        
        override open func deserialize(data: Data) throws -> Image {
            if let image = Image(data: data) {
                return image
            }
            throw DataSerializerError.serializationError
        }
    }
    
#endif
