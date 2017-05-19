//
//  DiskCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

enum DiskCacheError: Error {
    case invalidPath
    case invalidData
    case enumeratorError
}

public final class DiskCache<T: AnyObject> {
    
    public let identifier: String
    public let serializer: DataSerializer<T>
    public var maxCapacity = 0
    
    public internal(set) var size = 0
    private var shrinking = false
    
    let fileManager = FileManager.default
    public var cacheDirectory: URL
    
    
    required public init(identifier: String, serializer: DataSerializer<T>, maxCapacity: Int = 0) throws {
        self.identifier = identifier
        self.serializer = serializer
        self.maxCapacity = maxCapacity
        
        let cacheURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        cacheDirectory = cacheURL.appendingPathComponent(identifier, isDirectory: true)
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        size = getCacheSize()
        restrictSize()
    }
    
    func getCacheSize() -> Int {
        guard let enumerator = cacheEnumerator(includingPropertiesForKeys: [.totalFileAllocatedSizeKey]) else { return 0 }
        return enumerator.flatMap { ($0 as? URL)?.totalFileAllocatedSize }.reduce(0, +)
    }
    
    public func object(forKey key: String) throws -> T? {
        let url = cacheDirectory.appendingPathComponent("c\(key)")
        if !objectExists(at: url) {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            throw DiskCacheError.invalidData
        }
        return try serializer.deserialize(data: data)
    }
    
    public func fileURL(forKey key: String) -> URL? {
        let url = cacheDirectory.appendingPathComponent("c\(key)")
        if objectExists(at: url) {
            return url
        }
        return nil
    }
    
    @inline(__always) private func objectExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    public func set(object: T, forKey key: String) throws {
        let data = try serializer.serialize(object: object)
        try set(data: data, forKey: key)
    }
    
    public func set(data: Data, forKey key: String) throws {
        let url = cacheDirectory.appendingPathComponent("c\(key)")
        try data.write(to: url, options: .atomicWrite)
        Log.debug("Saved (\(key)): \(data.formattedSize)")
        size += data.count
        restrictSize()
    }
    
    func updateLastAccess(ofKey key: String) {
        let path = cacheDirectory.appendingPathComponent("c\(key)").path
        do {
            try fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: path)
        } catch {
            Log.error(error)
        }
    }
    
    public func removeObject(forKey key: String) throws {
        let url = cacheDirectory.appendingPathComponent("c\(key)")
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        if let fileSize = attributes?[FileAttributeKey.size] as? NSNumber {
            size -= fileSize.intValue
        }
        try fileManager.removeItem(at: url)
    }
    
    public func remove(olderThan limit: Date) {
        diskQueue.async {
            let resourceKeys: [URLResourceKey] = [.contentAccessDateKey, .totalFileAllocatedSizeKey]
            guard let enumerator = self.cacheEnumerator(includingPropertiesForKeys: resourceKeys) else {
                Log.error(DiskCacheError.enumeratorError)
                return
            }
            for case let url as URL in enumerator {
                guard let lastAccess = url.contentAccessDate, lastAccess < limit else { continue }
                guard let size = url.totalFileAllocatedSize else { continue }
                do {
                    try self.fileManager.removeItem(at: url)
                    self.size -= size
                }
                catch {
                    Log.error(error)
                }
            }
        }
    }
    
    public func clear() {
        guard let enumerator = cacheEnumerator(includingPropertiesForKeys: nil) else { return }
        for case let fileURL as URL in enumerator {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                Log.error(error)
            }
        }
        size = 0
    }
    
    private func cacheEnumerator(includingPropertiesForKeys keys: [URLResourceKey]?) -> FileManager.DirectoryEnumerator? {
        return fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: keys, options: [], errorHandler: { (url, error) -> Bool in
            Log.error(error)
            return true
        })
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
                let resourceKeys: [URLResourceKey] = [.contentAccessDateKey, .totalFileAllocatedSizeKey]
                var urls = try self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: resourceKeys, options: [])
                urls.sort(by: {
                    guard let first = $0.contentAccessDate, let second = $1.contentAccessDate else { return false }
                    return first < second
                })
                for url in urls {
                    do {
                        guard let size = url.totalFileAllocatedSize else { continue }
                        try self.fileManager.removeItem(at: url)
                        self.size -= size
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

extension Data {
    var formattedSize: String {
        if count < 1024 {
            return "\(count) bytes"
        }
        if count < 1024 * 1024 {
            return "\(Double(count) / 1024.0) Kb"
        }
        return "\(Double(count) / (1024 * 1024)) Mb"
    }
}
