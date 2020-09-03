import Foundation

public protocol Serializer {
    associatedtype T
    
    func serialize(_ instance: T) throws -> Data
    func deserialize(_ data: Data) throws -> T
}

public enum SerializationError: Error {
    case cannotSerialize
    case cannotDeserialize
    case notImplemented
}
