//
//  DataSerializer.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 12/05/17.
//
//

import Foundation

public enum DataSerializerError: Error {
    case notImplemented
    case serializationError
}

/// Abstract class that converts cachable objects of type T into Data and Data into objects of type T
open class DataSerializer<T> {
    
    public init() {}
    
    open func deserialize(data: Data) throws -> T {
        throw DataSerializerError.notImplemented
    }
    
    open func serialize(object: T) throws -> Data {
        throw DataSerializerError.notImplemented
    }
}
