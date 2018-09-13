//
//  PNGImageSerializer.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 5/22/17.
//
//

#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

public final class PNGImageSerializer: AbstractImageSerializer {
    
    override public func serialize(object: Image) throws -> Data {
        if let data = object.pngData() {
            return data
        }
        throw DataSerializerError.serializationError
    }
}

#endif
