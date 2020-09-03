//
//  DiskTests.swift
//  AllCache
//
//  Created by JuanJo on 30/08/20.
//

import XCTest
import NewCache

private let concurrentQueue = DispatchQueue(label: "com.allcache.TestConcurrentQueue", attributes: .concurrent)

class DiskTests: XCTestCase {
    
    var cache = try! DiskCache(identifier: "new_icecream_disk", serializer: JSONSerializer<Icecream>())

    override func setUpWithError() throws {
        cache.clear()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCacheObject() throws {
        let expectation: XCTestExpectation = self.expectation(description: "testFetch")
        
        try cache.set(Icecream(id: "1", flavor: "Vanilla"), forKey: "1")
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            do {
                let vanilla = try self.cache.instance(forKey: "1")
                XCTAssertNotNil(vanilla)
                expectation.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testConcurrentRead() throws {
        let expectation = self.expectation(description: "concurrentRead")
        
        var result1: Icecream?
        var result2: Icecream?
        
        try! cache.set(Icecream(id: "1", flavor: "vanilla"), forKey: "default")
        
        print("write:  \(DispatchTime.now())")
        concurrentQueue.async {
            result1 = try? self.cache.instance(forKey: "default")
            print("read 1: \(DispatchTime.now())")
            if let result = result2 {
                XCTAssertEqual(result1, result)
                print("equal 1")
                expectation.fulfill()
            }
        }
        concurrentQueue.async {
            result2 = try? self.cache.instance(forKey: "default")
            print("read 2: \(DispatchTime.now())")
            if let result = result1 {
                XCTAssertEqual(result2, result)
                print("equal 2")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    func testPerformanceRead() throws {
        self.measure {
            _ = try? self.cache.instance(forKey: "default")
        }
    }

}
