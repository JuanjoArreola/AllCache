//
//  PNGImageSerializer.swift
//  ImageCache
//
//  Created by JuanJo on 31/08/20.
//

#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit
import AllCache

public final class PNGImageSerializer: ImageSerializer {
    
    override public func serialize(_ instance: Image) throws -> Data {
        if let data = instance.pngData() {
            return data
        }
        throw SerializationError.cannotSerialize
    }
}

#endif
