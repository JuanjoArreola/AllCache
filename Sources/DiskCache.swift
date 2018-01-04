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

public final class DiskCache<T> {
    
    public let identifier: String
    public let serializer: DataSerializer<T>
    public let cacheDirectory: URL
    
    public var maxCapacity = 0
    public internal(set) var size = 0
    
    private var shrinking = false
    private let fileManager = FileManager.default
    
    required public init(identifier: String, serializer: DataSerializer<T>, directory: FileManager.SearchPathDirectory = .cachesDirectory) throws {
        self.identifier = identifier
        self.serializer = serializer
        
        let cacheURL = try fileManager.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: false)
        cacheDirectory = cacheURL.appendingPathComponent(identifier, isDirectory: true)
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        size = getCacheSize()
        restrictSize()
    }
    
    func getCacheSize() -> Int {
        guard let enumerator = cacheDirectory.enumerator(includingPropertiesForKeys: [.totalFileAllocatedSizeKey]) else {
            return 0
        }
        return enumerator.flatMap { ($0 as? URL)?.totalFileAllocatedSize }.reduce(0, +)
    }
    
    public func object(forKey key: String) throws -> T? {
        let url = cacheDirectory.appendingPathComponent(validkey(from: key))
        if !fileManager.fileExists(at: url) {
            return nil
        }
        Log.debug("🔑(\(key)) found on disk")
        diskQueue.async { self.updateLastAccess(ofKey: key) }
        
        return try serializer.deserialize(data: Data(contentsOf: url))
    }
    
    public func fileURL(forKey key: String) -> URL? {
        let url = cacheDirectory.appendingPathComponent(validkey(from: key))
        if fileManager.fileExists(at: url) {
            return url
        }
        return nil
    }
    
    public func allKeys() -> [String] {
        guard let enumerator = cacheDirectory.enumerator(includingPropertiesForKeys: nil) else { return [] }
        return enumerator.flatMap({
            guard let name = ($0 as? URL)?.lastPathComponent else { return nil }
            return String(name[name.index(name.startIndex, offsetBy: 1)...])
        })
    }
    
    public func set(object: T, forKey key: String) throws {
        let data = try serializer.serialize(object: object)
        try set(data: data, forKey: key)
    }
    
    public func set(data: Data, forKey key: String) throws {
        let url = cacheDirectory.appendingPathComponent(validkey(from: key))
        try data.write(to: url, options: .atomicWrite)
        Log.debug("💽 Saved (\(key)): \(data.formattedSize)")
        size += data.count
        restrictSize()
    }
    
    func updateLastAccess(ofKey key: String) {
        let path = cacheDirectory.appendingPathComponent(validkey(from: key)).path
        do {
            try fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: path)
        } catch {
            Log.error(error)
        }
    }
    
    public func removeObject(forKey key: String) throws {
        let url = cacheDirectory.appendingPathComponent(validkey(from: key))
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        if let fileSize = attributes?[.size] as? NSNumber {
            size -= fileSize.intValue
        }
        try fileManager.removeItem(at: url)
    }
    
    public func remove(olderThan limit: Date) {
        diskQueue.async {
            let resourceKeys: [URLResourceKey] = [.contentAccessDateKey, .totalFileAllocatedSizeKey]
            guard let enumerator = self.cacheDirectory.enumerator(includingPropertiesForKeys: resourceKeys) else {
                Log.error(DiskCacheError.enumeratorError)
                return
            }
            for case let url as URL in enumerator {
                guard let lastAccess = url.contentAccessDate, lastAccess < limit else { continue }
                self.removeIfPossible(url: url)
            }
        }
    }
    
    public func clear() {
        guard let enumerator = cacheDirectory.enumerator(includingPropertiesForKeys: nil) else { return }
        for case let url as URL in enumerator {
            removeIfPossible(url: url)
        }
        size = 0
    }
    
    @inline(__always)
    private func removeIfPossible(url: URL) {
        do {
            Log.debug("💽 Deleting (\(url.lastPathComponent))")
            try fileManager.removeItem(at: url)
            size -= url.totalFileAllocatedSize ?? 0
        } catch {
            Log.error(error)
        }
    }
    
    func restrictSize() {
        if maxCapacity <= 0 { return }
        if size < maxCapacity { return }
        diskQueue.async {
            if self.shrinking { return }
            self.shrinking = true
            do {
                Log.debug("💽 Original size: \(self.size)")
                try self.restrictSize(percent: 0.8)
                Log.debug("💽 Final size: \(self.size)")
                self.shrinking = false
            } catch {
                Log.error(error)
                self.shrinking = false
            }
        }
    }
    
    private func restrictSize(percent: Double) throws {
        let target = Int(Double(maxCapacity) * 0.8)
        let keys: [URLResourceKey] = [.contentAccessDateKey, .totalFileAllocatedSizeKey]
        var urls = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: keys, options: [])
        urls.sort(by: {
            guard let first = $0.contentAccessDate, let second = $1.contentAccessDate else { return false }
            return first < second
        })
        for url in urls {
            removeIfPossible(url: url)
            if self.size <= target {
                break
            }
        }
    }
}

private let fileNameRegex = try! NSRegularExpression(pattern: "[/:;?*|']", options: [])

private func validkey(from key: String) -> String {
    return "c" + fileNameRegex.stringByReplacingMatches(in: key, options: [], range: key.wholeNSRange, withTemplate: "")
}

private extension URL {
    func enumerator(includingPropertiesForKeys keys: [URLResourceKey]?) -> FileManager.DirectoryEnumerator? {
        return FileManager.default.enumerator(at: self, includingPropertiesForKeys: keys, options: [], errorHandler: {
            (_, error) -> Bool in
            Log.error(error)
            return true
        })
    }
}

extension Data {
    var formattedSize: String {
        switch count {
        case ..<1024:
            return "\(count) bytes"
        case ..<(1024 * 1024):
            return "\(Double(count) / 1024.0) Kb"
        default:
            return "\(Double(count) / (1024 * 1024)) Mb"
        }
    }
}

extension FileManager {
    func fileExists(at url: URL) -> Bool {
        return fileExists(atPath: url.path)
    }
}
