import Foundation
import ShallowPromises

//private let workingQueue = DispatchQueue(label: "com.allcache.WorkingQueue", attributes: .concurrent)

public enum CacheError: Error {
    case notFound
}

open class Cache<T, S: Serializer> where S.T == T {
    public let memoryCache = MemoryCache<T>()
    public let diskCache: DiskCache<T, S>
    
    public var saveOriginalInMemory = false
    
    private let promiseCache = MemoryCache<Promise<T>>()
    
    public init(diskCache: DiskCache<T, S>) {
        self.diskCache = diskCache
    }
    
    public convenience init(identifier: String, serializer: S) throws {
        self.init(diskCache: try DiskCache<T, S>(identifier: identifier, serializer: serializer))
    }
    
    /// Search an object in caches, does not try to fetch it if not found
    public func instance(forKey key: String) throws -> T? {
        if let result = memoryCache.instance(forKey: key) {
            return result
        }
        if let result = try diskCache.instance(forKey: key) {
            memoryCache.set(result, forKey: key)
            return result
        }
        return nil
    }
    
    public func instance<F: Fetcher>(forKey key: String, fetcher: F? = nil, processor: Processor<T>? = nil) async throws -> T? where F.T == T {
        let descriptor = ElementDescriptor(key: key, fetcher: fetcher, processor: processor)
        return try await instance(for: descriptor)
    }
    
    public func instance<F: Fetcher>(for descriptor: ElementDescriptor<T, F>) async throws -> T? where F.T == T {
        if let result = memoryCache.instance(forKey: descriptor.descriptorKey) {
            return result
        }
        return try await searchOnDisk(descriptor: descriptor)
    }
    
    private func searchOnDisk<F: Fetcher>(descriptor: ElementDescriptor<T, F>) async throws -> T? {
        if let result = try diskCache.instance(forKey: descriptor.descriptorKey) {
            defer {
                memoryCache.set(result, forKey: descriptor.descriptorKey)
            }
            return result
        } else if let _ = descriptor.processor {
            return try await searchOriginal(descriptor: descriptor)
        } else {
            return try await fetchInstance(descriptor: descriptor)
        }
    }
    
    private func searchOriginal<F: Fetcher>(descriptor: ElementDescriptor<T, F>) async throws -> T? {
        if let originalInstance = memoryCache.instance(forKey: descriptor.key) {
            return try await process(originalInstance, with: descriptor)
        }
        if let originalInstance = try diskCache.instance(forKey: descriptor.key) {
            defer {
                if saveOriginalInMemory {
                    memoryCache.set(originalInstance, forKey: descriptor.key)
                }
            }
            return try await process(originalInstance, with: descriptor)
        } else {
            return try await fetchInstance(descriptor: descriptor)
        }
    }
    
    private func process<F: Fetcher>(_ instance: T, with descriptor: ElementDescriptor<T, F>) async throws -> T {
        let result: T
        if let processor = descriptor.processor {
            result = try processor.process(instance)
        } else {
            result = instance
        }
        defer {
            memoryCache.set(result, forKey: descriptor.descriptorKey)
            try? diskCache.set(result, forKey: descriptor.descriptorKey)
        }
        return result
    }
    
    private func fetchInstance<F: Fetcher>(descriptor: ElementDescriptor<T, F>) async throws -> T? {
        guard let fetcher = descriptor.fetcher else {
            return nil
        }
        let result = try await fetcher.fetch()
        defer {
            if descriptor.processor == nil || self.saveOriginalInMemory {
                self.memoryCache.set(result.instance, forKey: descriptor.key)
            }
            if let data = result.data {
                try? self.diskCache.set(data: data, forKey: descriptor.key)
            } else {
                try? self.diskCache.set(result.instance, forKey: descriptor.key)
            }
        }
        return try await process(result.instance, with: descriptor)
    }
    
    // MARK: - Set
    
    open func set(_ instance: T, forKey key: String) {
        memoryCache.set(instance, forKey: key)
        workingQueue.async {
            try? self.diskCache.set(instance, forKey: key)
        }
    }
    
    // MARK: - Delete
    
    open func removeInstance(forKey key: String) {
        memoryCache.removeInstance(forKey: key)
        workingQueue.async {
            try? self.diskCache.removeInstance(forKey: key)
        }
    }
    
    open func clear() {
        memoryCache.clear()
        workingQueue.async {
            self.diskCache.clear()
        }
    }
    
}
