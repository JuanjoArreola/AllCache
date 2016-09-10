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
        let expectation = self.expectation(description: "get image")
        let fetcher = ImageFetcher(url: URL(string: "https://placeholdit.imgix.net/~text?txtsize=33&txt=Placeholder&w=400&h=200&bg=0000ff")!)
        _ = ImageCache.sharedInstance.objectForKey("", objectFetcher: fetcher) { (getObject) -> Void in
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
        _ = ImageCache.sharedInstance.objectForKey(fetcher.identifier, objectFetcher: fetcher) { (getObject) -> Void in
            do {
                _ = try getObject()
                expectation.fulfill()
            } catch {
                Log.error(error)
                XCTFail()
            }
        }
        _ = ImageCache.sharedInstance.objectForKey(fetcher.identifier, objectFetcher: fetcher) { (getObject) -> Void in
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
    
    func testResizeImage() {
        let expectation = self.expectation(description: "resize image")
        
        let descriptor = ImageCachableDescriptor(url: URL(string: "http://img.cinemasapp.co/unsafe/640x360/smart/ia.media-imdb.com/images/M/MV5BMjQ0MTgyNjAxMV5BMl5BanBnXkFtZTgwNjUzMDkyODE@._V1__SX1234_SY660_.jpg")!, size: CGSize(width: 320, height: 180), scale: 0.0, backgroundColor: UIColor.black, mode: UIViewContentMode.scaleAspectFill)
        
        _ = ImageCache.sharedInstance.objectForDescriptor(descriptor) { (getObject) in
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
    
}
