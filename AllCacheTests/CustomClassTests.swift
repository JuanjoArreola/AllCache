//
//  CustomClassTests.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 16/03/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import XCTest
@testable import AllCache

class CustomClassTests: XCTestCase {
    
    var userCache: Cache<UserInfo>!
    
    override func setUp() {
        super.setUp()
        
        userCache = try! Cache<UserInfo>(identifier: "user_info", dataSerializer: DataSerializer<UserInfo>())
    }
    
    override func tearDown() {
        userCache.clear()
        
        super.tearDown()
    }
    
    func testCacheCreation() {
        do {
            _ = try Cache<UserInfo>(identifier: "user_info", dataSerializer: DataSerializer<UserInfo>())
        } catch {
            XCTFail()
        }
    }
    
    func testSaveObject() {
        let userInfo = UserInfo(id: "1", name: "Juanjo")
        userCache.setObject(userInfo, forKey: "user_1")
        
        let expectation: XCTestExpectation = expectationWithDescription("get user")
        
        userCache.objectForKey("user_1", objectFetcher: ObjectFetcher<UserInfo>(identifier: "user_1")) { (getObject) -> Void in
            do {
                try getObject()
                expectation.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testDeleteObject() {
        let userInfo = UserInfo(id: "1", name: "Juanjo")
        userCache.setObject(userInfo, forKey: "user_1")
        userCache.removeObjectForKey("user_1")
        
        let expectation: XCTestExpectation = expectationWithDescription("get user")
        
        userCache.objectForKey("user_1", objectFetcher: ObjectFetcher<UserInfo>(identifier: "user_1")) { (getObject) -> Void in
            do {
                try getObject()
                XCTFail()
            } catch {
                expectation.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
}

class UserInfo: NSObject, NSCoding {
    var name: String!
    var id: String!
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObjectForKey("id") as? String else { return nil }
        guard let name = aDecoder.decodeObjectForKey("name") as? String else { return nil }
        self.init(id: id, name: name)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(id, forKey: "id")
        aCoder.encodeObject(name, forKey: "name")
    }
}
