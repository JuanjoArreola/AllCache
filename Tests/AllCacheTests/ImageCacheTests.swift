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
        ImageCache.shared.diskCache.clear()
        super.tearDown()
    }
    
    func testGetImage() {
        let expectation = self.expectation(description: "get image")
        let fetcher = ImageFetcher(url: URL(string: "https://placeholdit.imgix.net/~text?txtsize=33&txt=Placeholder&w=400&h=200&bg=0000ff")!)
        _ = ImageCache.shared.object(forKey: "test", fetcher: fetcher, completion: { _ in
        }).fail(handler: { error in
            log.error(error)
            XCTFail()
        }).finished {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testGetSameImage() {
        let expectation = self.expectation(description: "get image")
        let expectation2 = self.expectation(description: "get image 2")
        let fetcher = ImageFetcher(url: URL(string: "https://placeholdit.imgix.net/~text?txtsize=33&txt=Placeholder&w=400&h=200&bg=0000ff")!)
        _ = ImageCache.shared.object(forKey: fetcher.identifier, fetcher: fetcher) { _ in
        }.fail(handler: { error in
            log.error(error)
            XCTFail()
        }).finished {
            expectation.fulfill()
        }
        _ = ImageCache.shared.object(forKey: fetcher.identifier, fetcher: fetcher) { (getObject) -> Void in
        }.fail(handler: { error in
            log.error(error)
            XCTFail()
        }).finished {
            expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
}
