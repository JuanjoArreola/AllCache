import Foundation
import ShallowPromises

private let workingQueue = DispatchQueue(label: "com.allcache.WorkingQueue", attributes: .concurrent)

public enum CacheError: Error {
    case notFound
}

open class Cache<T, S: Serializer> where S.T == T {
    public let memoryCache = MemoryCache<T>()
    public let diskCache: DiskCache<T, S>
    
    open var responseQueue = DispatchQueue.main
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
    
    public func instance<F: Fetcher>(forKey key: String, fetcher: F?, processor: Processor<T>? = nil) -> Promise<T> where F.T == T {
        let descriptor = ElementDescriptor(key: key, fetcher: fetcher, processor: processor)
        return instance(for: descriptor)
    }
    
    public func instance<F: Fetcher>(for descriptor: ElementDescriptor<T, F>) -> Promise<T> where F.T == T {
        if let result = memoryCache.instance(forKey: descriptor.descriptorKey) {
            return Promise().fulfill(with: result)
        } else if let promise = promiseCache.instance(forKey: descriptor.descriptorKey) {
            return promise.proxy()
        }
        let promise = createPromise(for: descriptor)
        workingQueue.async {
            self.searchOnDisk(descriptor: descriptor, promise: promise)
        }
        
        return promise
    }
    
    private func createPromise<F: Fetcher>(for descriptor: ElementDescriptor<T, F>) -> Promise<T> {
        let promise = Promise<T>().finally(in: workingQueue) {
            self.promiseCache.removeInstance(forKey: descriptor.descriptorKey)
        }
        promiseCache.set(promise, forKey: descriptor.descriptorKey)
        
        return promise
    }
    
    private func searchOnDisk<F: Fetcher>(descriptor: ElementDescriptor<T, F>, promise: Promise<T>) {
        do {
            if let result = try diskCache.instance(forKey: descriptor.descriptorKey) {
                promise.fulfill(with: result, in: responseQueue)
                memoryCache.set(result, forKey: descriptor.descriptorKey)
            } else if let _ = descriptor.processor {
                searchOriginal(descriptor: descriptor, promise: promise)
            } else {
                fetchInstance(descriptor: descriptor, promise: promise)
            }
        } catch {
            promise.complete(with: error, in: responseQueue)
        }
    }
    
    private func searchOriginal<F: Fetcher>(descriptor: ElementDescriptor<T, F>, promise: Promise<T>) {
        if let originalInstance = memoryCache.instance(forKey: descriptor.key) {
            process(originalInstance, with: descriptor, promise: promise)
            return
        }
        do {
            if let originalInstance = try diskCache.instance(forKey: descriptor.key) {
                process(originalInstance, with: descriptor, promise: promise)
                if saveOriginalInMemory {
                    memoryCache.set(originalInstance, forKey: descriptor.key)
                }
            } else {
                fetchInstance(descriptor: descriptor, promise: promise)
            }
        } catch {
            promise.complete(with: error, in: responseQueue)
        }
    }
    
    private func process<F: Fetcher>(_ instance: T, with descriptor: ElementDescriptor<T, F>, promise: Promise<T>) {
        do {
            let result = try descriptor.processor!.process(instance)
            promise.fulfill(with: result, in: responseQueue)
            memoryCache.set(result, forKey: descriptor.descriptorKey)
            try? diskCache.set(result, forKey: descriptor.descriptorKey)
        } catch {
            promise.complete(with: error, in: responseQueue)
        }
    }
    
    private func fetchInstance<F: Fetcher>(descriptor: ElementDescriptor<T, F>, promise: Promise<T>) {
        guard let fetcher = descriptor.fetcher else {
            promise.complete(with: CacheError.notFound, in: responseQueue)
            return
        }
        promise.littlePromise = fetcher.fetch().onSuccess(in: workingQueue) { result in
            if let _ = descriptor.processor {
                self.process(result.instance, with: descriptor, promise: promise)
            } else {
                promise.fulfill(with: result.instance, in: self.responseQueue)
            }
            if descriptor.processor == nil || self.saveOriginalInMemory {
                self.memoryCache.set(result.instance, forKey: descriptor.key)
            }
            if let data = result.data {
                try? self.diskCache.set(data: data, forKey: descriptor.key)
            } else {
                try? self.diskCache.set(result.instance, forKey: descriptor.key)
            }
        }.onError({ error in
            promise.complete(with: error, in: self.responseQueue)
        })
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
