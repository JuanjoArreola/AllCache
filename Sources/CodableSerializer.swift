//
//  CodableSerializer.swift
//  Logg
//
//  Created by Juan Jose Arreola on 22/09/17.
//

import Foundation

class CodableSerializer<T: Codable>: DataSerializer<T> {
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    override func serialize(object: T) throws -> Data {
        return try encoder.encode(object)
    }
    
    override func deserialize(data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }
}
