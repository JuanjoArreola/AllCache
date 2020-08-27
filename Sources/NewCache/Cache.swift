import Foundation
import ShallowPromises

internal let workingQueue = DispatchQueue(label: "com.allcache.WorkingQueue", attributes: .concurrent)

public class Cache<T, S: Serializer> where S.T == T {
    public let memoryCache = MemoryCache<T>()
    public let diskCache: DiskCache<T, S>
    
    open var responseQueue = DispatchQueue.main
    
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
    
    func instance<F: Fetcher, P: Processor>(forKey key: String, fetcher: F?, processor: P? = nil) -> Promise<T> where F.T == T, P.T == T {
        let descriptor = ElementDescriptor(key: key, fetcher: fetcher, processor: processor)
        return instance(descriptor: descriptor)
    }
    
    func instance<F: Fetcher, P: Processor>(descriptor: ElementDescriptor<T, F, P>) -> Promise<T> where F.T == T {
        if let result = memoryCache.instance(forKey: descriptor.descriptorKey) {
            return Promise().fulfill(with: result)
        }
        // TODO: fetching
        let promise = Promise<T>()
        workingQueue.async {
            self.searchOnDisk(descriptor: descriptor, promise: promise)
        }
        
        return promise
    }
    
    private func searchOnDisk<F: Fetcher, P: Processor>(descriptor: ElementDescriptor<T, F, P>, promise: Promise<T>) {
        do {
            if let result = try diskCache.instance(forKey: descriptor.descriptorKey) {
                promise.fulfill(with: result, in: responseQueue)
                memoryCache.set(result, forKey: descriptor.descriptorKey)
            } else if let _ = descriptor.processor {
                searchOriginal(descriptor: descriptor, promise: promise)
            } else {
                fetchObject(descriptor: descriptor, promise: promise)
            }
        } catch {
            promise.complete(with: error, in: responseQueue)
        }
    }
    
    private func searchOriginal<F: Fetcher, P: Processor>(descriptor: ElementDescriptor<T, F, P>, promise: Promise<T>) {
        if let rawInstance = memoryCache.instance(forKey: descriptor.key) {
            process(rawInstance: rawInstance, with: descriptor, promise: promise)
            return
        }
        diskQueue.async {
            do {
                if let rawInstance = try self.diskCache.instance(forKey: descriptor.key) {
                    self.process(rawInstance: rawInstance, with: descriptor, promise: promise)
                    self.memoryCache.set(rawInstance, forKey: descriptor.key)
                } else {
                    self.fetchObject(descriptor: descriptor, promise: promise)
                }
            } catch {
                promise.complete(with: error, in: self.responseQueue)
            }
        }
    }
    
    private func process<F: Fetcher, P: Processor>(rawInstance: T, with descriptor: ElementDescriptor<T, F, P>, promise: Promise<T>) {
        workingQueue.async {
            do {
                let instance = try descriptor.processor!.process(rawInstance)
                promise.fulfill(with: instance, in: self.responseQueue)
                self.memoryCache.set(instance, forKey: descriptor.descriptorKey)
                try? self.diskCache.set(instance, forKey: descriptor.descriptorKey)
            } catch {
                promise.complete(with: error, in: self.responseQueue)
            }
        }
    }
    
    private func fetchObject<F: Fetcher, P: Processor>(descriptor: ElementDescriptor<T, F, P>, promise: Promise<T>) {
        guard let fetcher = descriptor.fetcher else {
            promise.complete(with: CacheError.notFound, in: self.responseQueue)
            return
        }
        promise.littlePromise = fetcher.fetch().onSuccess({ result in
            if let _ = descriptor.processor {
                self.process(rawInstance: result.instance, with: descriptor, promise: promise)
            } else {
                promise.fulfill(with: result.instance, in: self.responseQueue)
            }
            self.memoryCache.set(result.instance, forKey: descriptor.key)
            if let data = result.data {
                try? self.diskCache.set(data: data, forKey: descriptor.key)
            } else {
                try? self.diskCache.set(result.instance, forKey: descriptor.key)
            }
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

public enum CacheError: Error {
    case notFound
}

