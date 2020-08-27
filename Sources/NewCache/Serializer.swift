import Foundation

public protocol Serializer {
    associatedtype T
    
    func serialize(_ instance: T) throws -> Data
    func deserialize(_ data: Data) throws -> T
}
