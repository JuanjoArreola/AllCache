//
//  ImageSerializer.swift
//  ImageCache
//
//  Created by JuanJo on 31/08/20.
//

import Foundation
import AllCache

#if os(OSX)
    
public final class ImageSerializer: Serializer {
    
    public func serialize(_ instance: Image) throws -> Data {
        if let data = instance.tiffRepresentation {
            return data
        }
        throw SerializationError.cannotSerialize
    }
    
    public func deserialize(_ data: Data) throws -> Image {
        if let image = Image(data: data) {
            return image
        }
        throw SerializationError.cannotDeserialize
    }
}
    
#elseif os(iOS) || os(tvOS) || os(watchOS)
    
open class ImageSerializer: Serializer {
    
    public func serialize(_ instance: Image) throws -> Data {
        throw SerializationError.notImplemented
    }
        
    open func deserialize(_ data: Data) throws -> Image {
        if let image = Image(data: data) {
            return image
        }
        throw SerializationError.cannotDeserialize
    }
}
    
#endif
