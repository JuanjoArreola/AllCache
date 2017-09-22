//
//  DiskTests.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 19/05/17.
//
//

import XCTest
import AllCache

class DiskTests: XCTestCase {
    
    var cache = try! Cache<Icecream>(identifier: "icecream_disk")

    override func setUp() {
        super.setUp()
        
        cache.clear()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCacheObject() {
        let expectation: XCTestExpectation = self.expectation(description: "testFetchObject")
        
        cache.set(Icecream(id: "1", flavor: "Vanilla"), forKey: "1", errorHandler: { error in
            XCTFail()
        })
        cache.memoryCache.removeObject(forKey: "1")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            do {
                let vanilla = try self.cache.object(forKey: "1")
                XCTAssertNotNil(vanilla)
                expectation.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testGetCached() {
        let expectation: XCTestExpectation = self.expectation(description: "testFetchObject")
        
        cache.set(Icecream(id: "1", flavor: "Vanilla"), forKey: "1", errorHandler: { error in
            XCTFail()
        })
        cache.memoryCache.removeObject(forKey: "1")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            _ = self.cache.object(forKey: "1", fetcher: Fetcher<Icecream>(identifier: "1"), completion: { icecream in
                XCTAssertEqual(icecream.flavor, "Vanilla")
            }).fail(handler: { error in
                XCTFail()
            }).finished(handler: { 
                expectation.fulfill()
            })
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCachedOriginal() {
        let expectation: XCTestExpectation = self.expectation(description: "testCachedOriginal")
        
        cache.set(Icecream(id: "1", flavor: "Vanilla"), forKey: "1", errorHandler: { error in
            XCTFail()
        })
        cache.memoryCache.removeObject(forKey: "1")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            let fetcher = Fetcher<Icecream>(identifier: "2")
            let processor = ToppingProcessor(identifier: "Oreo")
            _ = self.cache.object(forKey: "1", fetcher: fetcher, processor: processor, completion: { icecream in
                XCTAssertEqual(icecream.flavor, "Vanilla")
            }).fail(handler: { error in
                XCTFail()
            }).finished {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchProcessCache() {
        let expectation: XCTestExpectation = self.expectation(description: "testFetchProcessCache")
        let processor = ToppingProcessor(identifier: "Oreo")
        let descriptor = CachableDescriptor(key: "1", fetcher: IcecreamFetcher(identifier: "1"), processor: processor)
        _ = cache.object(for: descriptor, completion: { _ in
            self.cache.memoryCache.removeObject(forKey: descriptor.resultKey!)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
                do {
                    let result = try self.cache.diskCache.object(forKey: descriptor.resultKey!)
                    XCTAssertEqual(result?.topping, "Oreo")
                } catch {
                    Log.error(error)
                    XCTFail()
                }
                expectation.fulfill()
            }
        }).fail(handler: { error in
            Log.error(error)
            XCTFail()
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 11.0)
    }
    
    func testInvalidSerializer() {
        let expectation: XCTestExpectation = self.expectation(description: "testInvalidSerializer")
        
        let cache = try! Cache<Icecream>(identifier: "icecream", serializer: InvalidSerializer())
        cache.set(Icecream(id: "1", flavor: "Vanilla"), forKey: "1", errorHandler: { error in
            XCTFail()
        })
        cache.memoryCache.removeObject(forKey: "1")
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            do {
                let _ = try cache.object(forKey: "1")
                XCTFail()
            } catch {
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

enum IcecreamError: Error {
    case test
}

class InvalidSerializer: CodableSerializer<Icecream> {
    
    override func deserialize(data: Data) throws -> Icecream {
        throw IcecreamError.test
    }
}
