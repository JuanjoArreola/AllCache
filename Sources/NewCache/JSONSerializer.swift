//
//  JSONSerializer.swift
//  NewCache
//
//  Created by JuanJo on 13/05/20.
//

import Foundation

public class JSONSerializer<T: Codable>: Serializer {
    public typealias T = T
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    public func serialize(_ instance: T) throws -> Data {
        return try encoder.encode(instance)
    }
    
    public func deserialize(_ data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }
    
    public init() {}
    
}
