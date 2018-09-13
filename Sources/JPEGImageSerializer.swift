//
//  JPEGImageSerializer.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 5/22/17.
//
//

#if os(iOS) || os(tvOS) || os(watchOS)
    
    import UIKit
    
    public final class JPEGImageSerializer: AbstractImageSerializer {
        
        override public func serialize(object: UIImage) throws -> Data {
            if let data = object.jpegData(compressionQuality: 0.9) {
                return data
            }
            throw DataSerializerError.serializationError
        }
    }
    
#endif
