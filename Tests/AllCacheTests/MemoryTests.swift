//
//  MemoryTests.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 17/05/17.
//
//

import XCTest
import AllCache

class MemoryTests: XCTestCase {
    
    var cache = try! Cache<Icecream>(identifier: "icecream")

    override func setUp() {
        super.setUp()
        
        cache.diskCache = nil
    }
    
    override func tearDown() {
        cache.clear()
        
        super.tearDown()
    }

    func testCacheObject() {
        do {
            cache.set(Icecream(id: "1", flavor: "Vanilla"), forKey: "1")
            let vanilla = try cache.object(forKey: "1")
            XCTAssertNotNil(vanilla)
        } catch {
            XCTFail()
        }
    }
    
    func testNotCached() {
        do {
            let vanilla = try cache.object(forKey: "1")
            XCTAssertNil(vanilla)
        } catch {
            XCTFail()
        }
    }
    
    func testFetchObject() {
        let expectation: XCTestExpectation = self.expectation(description: "testFetchObject")
        
        _ = cache.object(forKey: "1", fetcher: IcecreamFetcher(identifier: "1")) { (getIcecream) in
            do {
                let icecream = try getIcecream()
                XCTAssertEqual(icecream.flavor, "Vanilla")
                expectation.fulfill()
            } catch {
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testGetCached() {
        let expectation: XCTestExpectation = self.expectation(description: "testGetCached")
        
        cache.set(Icecream(id: "1", flavor: "Vanilla"), forKey: "1")
        _ = cache.object(forKey: "1", fetcher: IcecreamFetcher(identifier: "1")) { (getIcecream) in
            do {
                let icecream = try getIcecream()
                XCTAssertEqual(icecream.flavor, "Vanilla")
                expectation.fulfill()
            } catch {
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCacheFetchedObject() {
        let expectation: XCTestExpectation = self.expectation(description: "testCacheFetchedObject")
        
        _ = cache.object(forKey: "1", fetcher: IcecreamFetcher(identifier: "1")) { _ in
            DispatchQueue.main.async {
                do {
                    let vanilla = try self.cache.object(forKey: "1")
                    XCTAssertNotNil(vanilla)
                    XCTAssertEqual(vanilla!.flavor, "Vanilla")
                    expectation.fulfill()
                } catch {
                    XCTFail()
                }
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testNotFetch() {
        let expectation: XCTestExpectation = self.expectation(description: "testNotFetch")
        
        _ = cache.object(forKey: "0", fetcher: IcecreamFetcher(identifier: "0")) { (getIcecream) in
            do {
                let _ = try getIcecream()
                XCTFail()
            } catch {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testNotFetchedNotCached() {
        let expectation: XCTestExpectation = self.expectation(description: "testNotFetchedNotCached")
        
        _ = cache.object(forKey: "1", fetcher: IcecreamFetcher(identifier: "0")) { _ in
            DispatchQueue.main.async {
                do {
                    let vanilla = try self.cache.object(forKey: "0")
                    XCTAssertNil(vanilla)
                    expectation.fulfill()
                } catch {
                    XCTFail()
                }
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testGetProcess() {
        let expectation: XCTestExpectation = self.expectation(description: "testGetProcess")
        
        cache.set(Icecream(id: "1", flavor: "Vanilla"), forKey: "1")
        _ = cache.object(forKey: "1", fetcher: IcecreamFetcher(identifier: "0"), processor: ToppingProcessor(identifier: "chocolate syrup")) { (getIcecream) in
            do {
                let vanilla = try getIcecream()
                XCTAssertEqual(vanilla.topping, "chocolate syrup")
                expectation.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testFetchProcess() {
        let expectation: XCTestExpectation = self.expectation(description: "testFetchProcess")
        
        _ = cache.object(forKey: "1", fetcher: IcecreamFetcher(identifier: "1"), processor: ToppingProcessor(identifier: "chocolate syrup")) { (getIcecream) in
            do {
                let vanilla = try getIcecream()
                XCTAssertEqual(vanilla.topping, "chocolate syrup")
                expectation.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

}
