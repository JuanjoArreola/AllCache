//
//  ImageCacheTests.swift
//  AllCache
//
//  Created by Juan Jose Arreola Simon on 2/22/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import XCTest
import AllCache

class ImageCacheTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        ImageCache.sharedInstance.diskCache.clear()
        super.tearDown()
    }
    
    func testGetImage() {
        let expectation = expectationWithDescription("get image")
        let fetcher = ImageFetcher(url: NSURL(string: "https://placeholdit.imgix.net/~text?txtsize=33&txt=Placeholder&w=400&h=200&bg=0000ff")!)
        ImageCache.sharedInstance.getObjectForKey("", objectFetcher: fetcher) { (getObject) -> Void in
            do {
                try getObject()
                expectation.fulfill()
            } catch {
                Log.error(error)
                XCTFail()
            }
        }
        waitForExpectationsWithTimeout(60, handler: nil)
    }
    
    func testGetSameImage() {
        let expectation = expectationWithDescription("get image")
        let expectation2 = expectationWithDescription("get image 2")
        let fetcher = ImageFetcher(url: NSURL(string: "https://placeholdit.imgix.net/~text?txtsize=33&txt=Placeholder&w=400&h=200&bg=0000ff")!)
        ImageCache.sharedInstance.getObjectForKey(fetcher.identifier, objectFetcher: fetcher) { (getObject) -> Void in
            do {
                try getObject()
                expectation.fulfill()
            } catch {
                Log.error(error)
                XCTFail()
            }
        }
        ImageCache.sharedInstance.getObjectForKey(fetcher.identifier, objectFetcher: fetcher) { (getObject) -> Void in
            do {
                try getObject()
                expectation2.fulfill()
            } catch {
                Log.error(error)
                XCTFail()
            }
        }
        
        waitForExpectationsWithTimeout(60, handler: nil)
    }
    
}

func dispatch_after(seconds seconds: Double, queue: dispatch_queue_t, closure: () -> Void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * 1000) * Int64(NSEC_PER_MSEC)), queue, closure)
}

func dispatch_after(milliseconds milliseconds: Int64, queue: dispatch_queue_t, closure: () -> Void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, milliseconds * Int64(NSEC_PER_MSEC)), queue, closure)
}

func dispatch_after(nanoseconds nanoseconds: Int64, queue: dispatch_queue_t, closure: () -> Void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nanoseconds), queue, closure)
}

