//
//  RequestingCacheTests.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 17/05/17.
//
//

import XCTest
import AllCache

class RequestingCacheTests: XCTestCase {
    
    var cache = try! Cache<Icecream>(identifier: "icecream_request")

    override func setUp() {
        super.setUp()
        
        cache.clear()
        IcecreamFetcher.fetchedCount = 0
        ToppingProcessor.toppingsAdded = 0
    }
    
    override func tearDown() {
        
        super.tearDown()
    }

    func testCachedRequest() {
        let request = cache.object(forKey: "1", fetcher: IcecreamFetcher(identifier: "1")) { _ in }
        let request2 = cache.object(forKey: "1", fetcher: IcecreamFetcher(identifier: "1")) { _ in }
        XCTAssertTrue(request === request2)
    }
    
    func testOtherRequest() {
        let request = cache.object(forKey: "1", fetcher: IcecreamFetcher(identifier: "1")) { _ in }
        let request2 = cache.object(forKey: "2", fetcher: IcecreamFetcher(identifier: "2")) { _ in }
        XCTAssertFalse(request === request2)
    }
    
    func testCachedFetchingRequest() {
        let expectation: XCTestExpectation = self.expectation(description: "testCachedFetchingRequest")
        var completed = 0 {
            didSet {
                if completed >= 2 {
                    XCTAssertEqual(IcecreamFetcher.fetchedCount, 1)
                    XCTAssertEqual(ToppingProcessor.toppingsAdded, 2)
                    expectation.fulfill()
                }
            }
        }
        
        let _ = cache.object(forKey: "1", fetcher: IcecreamFetcher(identifier: "1"), processor: ToppingProcessor(identifier: "Oreo")) { getIcecream in
            do {
                let icecream = try getIcecream()
                XCTAssertEqual(icecream.flavor, "Vanilla")
                completed += 1
                
            } catch {
                XCTFail()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { 
            let _ = self.cache.object(forKey: "2", fetcher: IcecreamFetcher(identifier: "1"), processor: ToppingProcessor(identifier: "Oreo")) { getIcecream in
                do {
                    let icecream = try getIcecream()
                    XCTAssertEqual(icecream.flavor, "Vanilla")
                    completed += 1
                } catch {
                    XCTFail()
                }
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCancelRequest() {
        let expectation: XCTestExpectation = self.expectation(description: "testCachedFetchingRequest")
        
        let request = cache.object(forKey: "1", fetcher: IcecreamFetcher(identifier: "1")) { _ in }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
            request.cancel()
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            let _ = self.cache.object(forKey: "1", fetcher: IcecreamFetcher(identifier: "1")) { getIcecream in
                do {
                    let icecream = try getIcecream()
                    XCTAssertEqual(icecream.flavor, "Vanilla")
                    expectation.fulfill()
                } catch {
                    XCTFail()
                }
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

}
