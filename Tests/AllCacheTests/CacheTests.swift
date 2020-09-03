//
//  CacheTests.swift
//  AllCache
//
//  Created by JuanJo on 30/08/20.
//

import XCTest
import AllCache

class CacheTests: XCTestCase {
    
    var cache = try! Cache(identifier: "test", serializer: JSONSerializer<Icecream>())

    override func setUpWithError() throws {
        cache.clear()
        cache.set(Icecream(id: "1", flavor: "Vanilla"), forKey: "1")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGetCached() throws {
        let expectation: XCTestExpectation = self.expectation(description: "testFetch")
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            let promise = self.cache.instance(forKey: "1", fetcher: IcecreamFetcher(identifier: "1"))
            promise.onSuccess { icecream in
                XCTAssertEqual(icecream.flavor, "Vanilla")
            }.onError { error in
                XCTFail()
            }.finally {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCachedOriginal() {
        let expectation: XCTestExpectation = self.expectation(description: "testCachedOriginal")
        
        cache.memoryCache.removeInstance(forKey: "1")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            let fetcher = IcecreamFetcher(identifier: "2")
            let processor = ToppingProcessor(identifier: "Oreo")
            
            _ = self.cache.instance(forKey: "1", fetcher: fetcher, processor: processor).onSuccess { icecream in
                XCTAssertEqual(icecream.flavor, "Vanilla")
                XCTAssertEqual(icecream.topping, "Oreo")
            }.onError { error in
                XCTFail()
            }.finally {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchProcessCache() {
        let expectation: XCTestExpectation = self.expectation(description: "testFetchProcessCache")
        let processor = ToppingProcessor(identifier: "Oreo")
        let descriptor = ElementDescriptor(key: "1", fetcher: IcecreamFetcher(identifier: "1"), processor: processor)
        
        _ = cache.instance(for: descriptor).onSuccess { _ in
            self.cache.memoryCache.removeInstance(forKey: descriptor.descriptorKey)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
                do {
                    let result = try self.cache.diskCache.instance(forKey: descriptor.descriptorKey)
                    XCTAssertEqual(result?.topping, "Oreo")
                } catch {
                    print(error)
                    XCTFail()
                }
                expectation.fulfill()
            }
        }.onError { error in
            print(error)
            XCTFail()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 11.0)
    }

    func testPerformanceRead() throws {
        // This is an example of a performance test case.
        self.measure {
            _ = try? self.cache.instance(forKey: "1")
        }
    }

}
