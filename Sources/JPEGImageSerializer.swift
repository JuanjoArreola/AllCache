//
//  JPEGImageSerializer.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 5/22/17.
//
//

#if os(iOS) || os(tvOS)
    
    import Foundation
    
    public final class JPEGImageSerializer: AbstractImageSerializer {
        
        override public func serialize(object: UIImage) throws -> Data {
            if let data = UIImagePNGRepresentation(object) {
                return data
            }
            throw DataSerializerError.serializationError
        }
    }
    
#endif
