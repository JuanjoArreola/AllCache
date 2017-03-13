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
        _ = ImageCache.shared.object(forKey: "", fetcher: fetcher) { (getObject) -> Void in
            do {
                _ = try getObject()
                expectation.fulfill()
            } catch {
                Log.error(error)
                XCTFail()
            }
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    func testGetSameImage() {
        let expectation = self.expectation(description: "get image")
        let expectation2 = self.expectation(description: "get image 2")
        let fetcher = ImageFetcher(url: URL(string: "https://placeholdit.imgix.net/~text?txtsize=33&txt=Placeholder&w=400&h=200&bg=0000ff")!)
        _ = ImageCache.shared.object(forKey: fetcher.identifier, fetcher: fetcher) { (getObject) -> Void in
            do {
                _ = try getObject()
                expectation.fulfill()
            } catch {
                Log.error(error)
                XCTFail()
            }
        }
        _ = ImageCache.shared.object(forKey: fetcher.identifier, fetcher: fetcher) { (getObject) -> Void in
            do {
                _ = try getObject()
                expectation2.fulfill()
            } catch {
                Log.error(error)
                XCTFail()
            }
        }
        
        waitForExpectations(timeout: 60, handler: nil)
    }
    
}
