//
//  JSONSerializer.swift
//  NewCache
//
//  Created by JuanJo on 13/05/20.
//

import Foundation

class JSONSerializer<T: Codable>: Serializer {
    typealias T = T
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    func serialize(_ instance: T) throws -> Data {
        return try encoder.encode(instance)
    }
    
    func deserialize(_ data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }
    
}
