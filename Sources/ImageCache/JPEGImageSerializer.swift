//
//  JPEGImageSerializer.swift
//  ImageCache
//
//  Created by JuanJo on 31/08/20.
//

#if os(iOS) || os(tvOS) || os(watchOS)
    
import UIKit
import NewCache
    
    public final class JPEGImageSerializer: ImageSerializer {
        
        override public func serialize(_ instance: UIImage) throws -> Data {
            if let data = instance.jpegData(compressionQuality: 0.9) {
                return data
            }
            throw SerializationError.cannotSerialize
        }
    }
    
#endif
