//
//  ImageSerializer.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/13/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import UIKit

public final class ImageSerializer: DataSerializer<UIImage> {
    
    override func serializeObject(object: UIImage) throws -> NSData {
        if let data = UIImagePNGRepresentation(object) {
            return data
        }
        throw DataSerializerError.SerializationError
    }
    
    override func deserializeData(data: NSData) throws -> UIImage {
        if let image = UIImage(data: data) {
            return image
        }
        throw DataSerializerError.SerializationError
    }
}