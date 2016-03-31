//
//  DiskCache.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

//private let shrinkQueue: dispatch_queue_t = dispatch_queue_create("com.crayon.allcache.FetchQueue", DISPATCH_QUEUE_SERIAL)

enum DiskCacheError: ErrorType {
    case InvalidPath
    case InvalidData
}

public final class DiskCache<T: AnyObject> {
    
    public let identifier: String
    public internal(set) var size = 0
    public var maxCapacity = 0
    private var shrinking = false
    
    let fileManager = NSFileManager.defaultManager()
    public var cacheDirectory: NSURL
    var dataSerializer: DataSerializer<T>!
    
    required public init(identifier: String, dataSerializer: DataSerializer<T>, maxCapacity: Int = 0) throws {
        self.identifier = identifier
        self.dataSerializer = dataSerializer
        self.maxCapacity = maxCapacity
        let cache = try! fileManager.URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
        cacheDirectory = cache.URLByAppendingPathComponent(identifier, isDirectory: true)
        
        guard let path = cacheDirectory.path else {
            throw DiskCacheError.InvalidPath
        }
        if !fileManager.fileExistsAtPath(path) {
            try fileManager.createDirectoryAtURL(cacheDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        size = getCacheSize()
        restrictSize()
    }
    
    func getCacheSize() -> Int {
        let resourceKeys = [NSURLTotalFileAllocatedSizeKey]
        guard let enumerator = fileManager.enumeratorAtURL(cacheDirectory, includingPropertiesForKeys: resourceKeys, options: [], errorHandler: nil) else {
            return 0
        }
        var total = 0
        for case let fileURL as NSURL in enumerator {
            guard let resourceValues = try? fileURL.resourceValuesForKeys(resourceKeys) else { continue }
            guard let size = resourceValues[NSURLTotalFileAllocatedSizeKey] as? NSNumber else { continue }
            total += size.integerValue
        }
        return total
    }
    
    public func objectForKey(key: String) -> T? {
        let fileName = "c" + String(key.hash)
        let url = cacheDirectory.URLByAppendingPathComponent(fileName)
        if !objectExistsAtURL(url) {
            return nil
        }
        do {
            guard let data = NSData(contentsOfURL: url) else {
                throw DiskCacheError.InvalidData
            }
            return try dataSerializer.deserializeData(data)
        } catch {
            Log.error(error)
            return nil
        }
    }
    
    @inline(__always) private func objectExistsAtURL(url: NSURL) -> Bool {
        if let path = url.path {
            return fileManager.fileExistsAtPath(path)
        }
        return false
    }
    
    public func setObject(object: T, forKey key: String) throws {
        Log.debug("Serializing (\(key))")
        let data = try dataSerializer.serializeObject(object)
        Log.debug("Serialized (\(key)): \(data.length / 1024) Kb")
        let fileName = "c" + String(key.hash)
        let url = cacheDirectory.URLByAppendingPathComponent(fileName)
        try data.writeToURL(url, options: .AtomicWrite)
        size += data.length
        restrictSize()
    }
    
    public func setData(data: NSData, forKey key: String) throws {
        let fileName = "c" + String(key.hash)
        let url = cacheDirectory.URLByAppendingPathComponent(fileName)
        try data.writeToURL(url, options: .AtomicWrite)
        size += data.length
        restrictSize()
    }
    
    func updateLastAccessOfKey(key: String) {
        let fileName = String(abs(key.hash))
        guard let path = cacheDirectory.URLByAppendingPathComponent(fileName).path else {
            return
        }
        _ = try? fileManager.setAttributes([NSURLContentAccessDateKey: NSDate()], ofItemAtPath: path)
    }
    
    public func removeObjectForKey(key: String) throws {
        let fileName = "c" + String(key.hash)
        let url = cacheDirectory.URLByAppendingPathComponent(fileName)
        if let path = url.path {
            let attributes = try? fileManager.attributesOfItemAtPath(path)
            if let fileSize = attributes?[NSFileSize] as? NSNumber {
                size -= fileSize.integerValue
            }
        }
        try fileManager.removeItemAtURL(url)
    }
    
    public func removeOlderThan(date: NSDate) {
        dispatch_async(diskQueue) {
            let resourceKeys = [NSURLContentAccessDateKey, NSURLTotalFileAllocatedSizeKey]
            guard let enumerator = self.fileManager.enumeratorAtURL(self.cacheDirectory, includingPropertiesForKeys: resourceKeys, options: [], errorHandler: nil) else {
                return
            }
            for case let url as NSURL in enumerator {
                guard let resourceValues = try? url.resourceValuesForKeys(resourceKeys) else { continue }
                guard let accessDate = resourceValues[NSURLContentAccessDateKey] as? NSDate else { continue }
                if date.compare(accessDate) == .OrderedDescending {
                    guard let size = resourceValues[NSURLTotalFileAllocatedSizeKey] as? NSNumber else { continue }
                    _ = try? self.fileManager.removeItemAtURL(url)
                    self.size -= size.integerValue
                }
            }
        }
    }
    
    public func clear() {
        guard let enumerator = fileManager.enumeratorAtURL(cacheDirectory, includingPropertiesForKeys: [], options: [], errorHandler: nil) else {
            return
        }
        for case let fileURL as NSURL in enumerator {
            _ = try? fileManager.removeItemAtURL(fileURL)
        }
        size = 0
    }
    
    func restrictSize() {
        if maxCapacity <= 0 { return }
        if size < maxCapacity { return }
        dispatch_async(diskQueue) {
            if self.shrinking { return }
            self.shrinking = true
            do {
                Log.debug("original size: \(self.size)")
                let sizeTarget = Int(Double(self.maxCapacity) * 0.8)
                let resourceKeys = [NSURLContentAccessDateKey, NSURLTotalFileAllocatedSizeKey]
                let dateKeys = [NSURLContentAccessDateKey]
                var urls = try self.fileManager.contentsOfDirectoryAtURL(self.cacheDirectory, includingPropertiesForKeys: resourceKeys, options: [])
                urls.sortInPlace({ (first, second) -> Bool in
                    guard let firstResourceValues = try? first.resourceValuesForKeys(dateKeys) else { return false }
                    guard let firstDate = firstResourceValues[NSURLContentAccessDateKey] as? NSDate else { return false }
                    guard let secondResourceValues = try? second.resourceValuesForKeys(dateKeys) else { return false }
                    guard let secondDate = secondResourceValues[NSURLContentAccessDateKey] as? NSDate else { return false }
                    return firstDate.compare(secondDate) == .OrderedAscending
                })
                for url in urls {
                    do {
                        guard let resourceValues = try? url.resourceValuesForKeys(resourceKeys) else { continue }
                        guard let size = resourceValues[NSURLTotalFileAllocatedSizeKey] as? NSNumber else { continue }
                        try self.fileManager.removeItemAtURL(url)
                        self.size -= size.integerValue
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


public enum DataSerializerError: ErrorType {
    case NotImplemented
    case SerializationError
}

/// Abstract class that converts cachable objects of type T into NSData and NSData into objects of type T
public class DataSerializer<T: AnyObject> {
    
    public init() {}
    
    public func deserializeData(data: NSData) throws -> T {
        if T.self is NSCoding {
            if let object = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? T {
                return object
            }
        }
        throw DataSerializerError.NotImplemented
    }
    
    public func serializeObject(object: T) throws -> NSData {
        if T.self is NSCoding {
            return NSKeyedArchiver.archivedDataWithRootObject(object)
        }
        throw DataSerializerError.NotImplemented
    }
}
