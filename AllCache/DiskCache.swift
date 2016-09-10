//
//  DiskCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

//private let shrinkQueue: dispatch_queue_t = dispatch_queue_create("com.crayon.allcache.FetchQueue", DISPATCH_QUEUE_SERIAL)

enum DiskCacheError: Error {
    case invalidPath
    case invalidData
}

public final class DiskCache<T: AnyObject> {
    
    public let identifier: String
    public internal(set) var size = 0
    public var maxCapacity = 0
    fileprivate var shrinking = false
    
    let fileManager = FileManager.default
    public var cacheDirectory: URL
    var dataSerializer: DataSerializer<T>!
    
    required public init(identifier: String, dataSerializer: DataSerializer<T>, maxCapacity: Int = 0) throws {
        self.identifier = identifier
        self.dataSerializer = dataSerializer
        self.maxCapacity = maxCapacity
        let cache = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        cacheDirectory = cache.appendingPathComponent(identifier, isDirectory: true)
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        size = getCacheSize()
        restrictSize()
    }
    
    func getCacheSize() -> Int {
        let resourceKeys = [URLResourceKey.totalFileAllocatedSizeKey]
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: resourceKeys, options: [], errorHandler: nil) else {
            return 0
        }
        var total = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? (fileURL as NSURL).resourceValues(forKeys: resourceKeys) else { continue }
            guard let size = resourceValues[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber else { continue }
            total += size.intValue
        }
        return total
    }
    
    public func objectForKey(_ key: String) -> T? {
        let fileName = "c" + String(key.hash)
        let url = cacheDirectory.appendingPathComponent(fileName)
        if !objectExists(atURL: url) {
            return nil
        }
        do {
            guard let data = try? Data(contentsOf: url) else {
                throw DiskCacheError.invalidData
            }
            return try dataSerializer.deserializeData(data)
        } catch {
            Log.error(error)
            return nil
        }
    }
    
    @inline(__always) fileprivate func objectExists(atURL url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    public func setObject(_ object: T, forKey key: String) throws {
        Log.debug("Serializing (\(key))")
        let data = try dataSerializer.serializeObject(object)
        Log.debug("Serialized (\(key)): \(data.count / 1024) Kb")
        let fileName = "c" + String(key.hash)
        let url = cacheDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomicWrite)
        size += data.count
        restrictSize()
    }
    
    public func setData(_ data: Data, forKey key: String) throws {
        let fileName = "c" + String(key.hash)
        let url = cacheDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomicWrite)
        size += data.count
        restrictSize()
    }
    
    func updateLastAccessOfKey(_ key: String) {
        let fileName = String(abs(key.hash))
        let path = cacheDirectory.appendingPathComponent(fileName).path
        _ = try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: path)
    }
    
    public func removeObjectForKey(_ key: String) throws {
        let fileName = "c" + String(key.hash)
        let url = cacheDirectory.appendingPathComponent(fileName)
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        if let fileSize = attributes?[FileAttributeKey.size] as? NSNumber {
            size -= fileSize.intValue
        }
        try fileManager.removeItem(at: url)
    }
    
    public func removeOlderThan(_ date: Date) {
        diskQueue.async {
            let resourceKeys = [URLResourceKey.contentAccessDateKey, URLResourceKey.totalFileAllocatedSizeKey]
            guard let enumerator = self.fileManager.enumerator(at: self.cacheDirectory, includingPropertiesForKeys: resourceKeys, options: [], errorHandler: nil) else {
                return
            }
            for case let url as URL in enumerator {
                guard let resourceValues = try? (url as NSURL).resourceValues(forKeys: resourceKeys) else { continue }
                guard let accessDate = resourceValues[URLResourceKey.contentAccessDateKey] as? Date else { continue }
                if date.compare(accessDate) == .orderedDescending {
                    guard let size = resourceValues[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber else { continue }
                    _ = try? self.fileManager.removeItem(at: url)
                    self.size -= size.intValue
                }
            }
        }
    }
    
    public func clear() {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [], options: [], errorHandler: nil) else {
            return
        }
        for case let fileURL as URL in enumerator {
            _ = try? fileManager.removeItem(at: fileURL)
        }
        size = 0
    }
    
    func restrictSize() {
        if maxCapacity <= 0 { return }
        if size < maxCapacity { return }
        diskQueue.async {
            if self.shrinking { return }
            self.shrinking = true
            do {
                Log.debug("original size: \(self.size)")
                let sizeTarget = Int(Double(self.maxCapacity) * 0.8)
                let resourceKeys = [URLResourceKey.contentAccessDateKey, URLResourceKey.totalFileAllocatedSizeKey]
                let dateKeys = [URLResourceKey.contentAccessDateKey]
                var urls = try self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: resourceKeys, options: [])
                urls.sort(by: { (first, second) -> Bool in
                    guard let firstResourceValues = try? (first as NSURL).resourceValues(forKeys: dateKeys) else { return false }
                    guard let firstDate = firstResourceValues[URLResourceKey.contentAccessDateKey] as? Date else { return false }
                    guard let secondResourceValues = try? (second as NSURL).resourceValues(forKeys: dateKeys) else { return false }
                    guard let secondDate = secondResourceValues[URLResourceKey.contentAccessDateKey] as? Date else { return false }
                    return firstDate.compare(secondDate) == .orderedAscending
                })
                for url in urls {
                    do {
                        guard let resourceValues = try? (url as NSURL).resourceValues(forKeys: resourceKeys) else { continue }
                        guard let size = resourceValues[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber else { continue }
                        try self.fileManager.removeItem(at: url)
                        self.size -= size.intValue
                        if self.size <= sizeTarget {
                            break
                        }
                    } catch {
                        Log.error(error)
                    }
                }
                Log.debug("final size: \(self.size)")
                self.shrinking = false
            } catch {
                Log.error(error)
                self.shrinking = false
            }
        }
    }
}


public enum DataSerializerError: Error {
    case notImplemented
    case serializationError
}

/// Abstract class that converts cachable objects of type T into NSData and NSData into objects of type T
open class DataSerializer<T: AnyObject> {
    
    public init() {}
    
    open func deserializeData(_ data: Data) throws -> T {
        if T.self is NSCoding {
            if let object = NSKeyedUnarchiver.unarchiveObject(with: data) as? T {
                return object
            }
        }
        throw DataSerializerError.notImplemented
    }
    
    open func serializeObject(_ object: T) throws -> Data {
        if T.self is NSCoding {
            return NSKeyedArchiver.archivedData(withRootObject: object)
        }
        throw DataSerializerError.notImplemented
    }
}
