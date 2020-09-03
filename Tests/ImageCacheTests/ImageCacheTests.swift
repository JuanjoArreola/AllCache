//
//  ImageCacheTests.swift
//  NewCacheTests
//
//  Created by JuanJo on 02/09/20.
//

import XCTest
import ImageCache

class ImageCacheTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGetImage() {
        let expectation = self.expectation(description: "get_image")
        
        let url = URL(string: "https://picsum.photos/200/300")!
        let fetcher = ImageFetcher(url: url)
        ImageCache.shared.instance(forKey: "test", fetcher: fetcher).onError { error in
            print(error)
            XCTFail()
        }.finally {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testGetSameImage() {
        let expectation = self.expectation(description: "get image")
        let expectation2 = self.expectation(description: "get image 2")
        let fetcher = ImageFetcher(url: URL(string: "https://picsum.photos/300/300")!)
        _ = ImageCache.shared.instance(forKey: "other_image", fetcher: fetcher).onError({ error in
            print(error)
            XCTFail()
        }).finally {
            expectation.fulfill()
        }
        _ = ImageCache.shared.instance(forKey: "other_image", fetcher: fetcher).onError({ error in
            print(error)
            XCTFail()
        }).finally {
            expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 4, handler: nil)
    }

}
