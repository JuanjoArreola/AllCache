//
//  File.swift
//  
//
//  Created by Juan Jose Arreola Simon on 06/10/21.
//

import Foundation

actor DiskAccess {
    public let directory: URL
    private let fileManager = FileManager.default
    
    init(directory: URL) {
        self.directory = directory
    }
    
    func updateLastAccess(ofKey key: String) {
        let path = directory.appendingPathComponent(validkey(from: key)).path
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: path)
    }
}

public final class AsyncDiskCache<T, S: Serializer> where S.T == T {
    
    public let identifier: String
    public let serializer: S
    public let cacheDirectory: URL
    
    private let fileManager = FileManager.default
    public var maxCapacity = 0
    public private(set) var size = 0
    private var shrinking = false
    
    private let diskAccess: DiskAccess
    
    required public init(identifier: String, serializer: S, directory: FileManager.SearchPathDirectory = .cachesDirectory) throws {
        self.identifier = identifier
        self.serializer = serializer
        
        let cacheURL = try fileManager.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: false)
        cacheDirectory = cacheURL.appendingPathComponent(identifier, isDirectory: true)
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        diskAccess = DiskAccess(directory: cacheDirectory)
    }
    
    public func instance(forKey key: String) async throws -> T? {
        let url = cacheDirectory.appendingPathComponent(validkey(from: key))
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        Task.detached {
            await self.diskAccess.updateLastAccess(ofKey: key)
        }
        return try serializer.deserialize(Data(contentsOf: url))
    }
    
    public func removeInstance(forKey key: String) throws {
        diskQueue.async(flags: .barrier) {
            let url = self.cacheDirectory.appendingPathComponent(validkey(from: key))
            let attributes = try? self.fileManager.attributesOfItem(atPath: url.path)
            try? self.fileManager.removeItem(at: url)
            if let fileSize = attributes?[.size] as? NSNumber {
                self.size -= fileSize.intValue
            }
        }
    }
    
    public func remove(olderThan limit: Date) {
        diskQueue.async(flags: .barrier) {
            let resourceKeys: [URLResourceKey] = [.contentAccessDateKey, .totalFileAllocatedSizeKey]
            guard let enumerator = self.cacheDirectory.enumerator(includingPropertiesForKeys: resourceKeys) else {
                return
            }
            let urls = enumerator.compactMap({ $0 as? URL }).filter({ ($0.contentAccessDate ?? limit) < limit })
            urls.forEach({ self.removeIfPossible(url: $0) })
        }
    }
    
    public func allKeys() -> [String] {
        guard let enumerator = cacheDirectory.enumerator(includingPropertiesForKeys: nil) else { return [] }
        return enumerator.compactMap({
            guard let name = ($0 as? URL)?.lastPathComponent else { return nil }
            return String(name[name.index(name.startIndex, offsetBy: 1)...])
        })
    }
    
    public func set(_ instance: T, forKey key: String) throws {
        try set(data: try serializer.serialize(instance), forKey: key)
    }
    
    public func set(data: Data, forKey key: String) throws {
        diskQueue.async(flags: .barrier) {
            let url = self.cacheDirectory.appendingPathComponent(validkey(from: key))
            try? data.write(to: url, options: .atomicWrite)
            self.size += data.count
            self.restrictSize()
        }
    }
    
    public func clear() {
        diskQueue.async(flags: .barrier) {
            guard let enumerator = self.cacheDirectory.enumerator(includingPropertiesForKeys: nil) else { return }
            for case let url as URL in enumerator {
                self.removeIfPossible(url: url)
            }
            self.size = 0
        }
    }
    
    func getCacheSize() -> Int {
        guard let enumerator = cacheDirectory.enumerator(includingPropertiesForKeys: [.totalFileAllocatedSizeKey]) else {
            return 0
        }
        return enumerator.compactMap { ($0 as? URL)?.totalFileAllocatedSize }.reduce(0, +)
    }
    
    func updateLastAccess(ofKey key: String) {
        let path = cacheDirectory.appendingPathComponent(validkey(from: key)).path
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: path)
    }
    
    func restrictSize() {
        guard maxCapacity > 0, size > maxCapacity else {
            return
        }
        diskQueue.async {
            if self.shrinking { return }
            self.shrinking = true
            do {
                try self.restrictSize(percent: 0.8)
                self.shrinking = false
            } catch {
                self.shrinking = false
            }
        }
    }
    
    private func removeIfPossible(url: URL) {
        do {
            try fileManager.removeItem(at: url)
            size -= url.totalFileAllocatedSize ?? 0
        } catch {}
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

@inline(__always)
private func validkey(from key: String) -> String {
    let range = NSRange(location: 0, length: key.count)
    return "_" + fileNameRegex.stringByReplacingMatches(in: key, options: [], range: range, withTemplate: "")
}

private extension URL {
    func enumerator(includingPropertiesForKeys keys: [URLResourceKey]?) -> FileManager.DirectoryEnumerator? {
        return FileManager.default.enumerator(at: self, includingPropertiesForKeys: keys)
    }
}
