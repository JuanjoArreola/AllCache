//
//  CustomClassTests.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 16/03/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import XCTest
import AllCache

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
        userCache.setObject(userInfo, forKey: "user_2")
        userCache.removeObjectForKey("user_2")
        
        let expectation: XCTestExpectation = expectationWithDescription("get user")
        
        userCache.objectForKey("user_2", objectFetcher: ObjectFetcher<UserInfo>(identifier: "user_2")) { (getObject) -> Void in
            do {
                try getObject()
                XCTFail()
            } catch {
                expectation.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testFetchObject() {
        let expectation: XCTestExpectation = expectationWithDescription("get user")
        userCache.objectForKey("user_1", objectFetcher: UserFetcher(userName: "Juanjo")) { (getObject) -> Void in
            do {
                try getObject()
                expectation.fulfill()
            } catch {
                XCTFail()
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

class UserFetcher: ObjectFetcher<UserInfo> {
    
    var name: String
    
    init(userName: String) {
        self.name = userName
        super.init(identifier: userName)
    }
    
    override func fetchAndRespondInQueue(queue: dispatch_queue_t, completion: (getObject: () throws -> UserInfo) -> Void) -> Request<UserInfo> {
        let request = Request<UserInfo>(completionHandler: completion)
        let userInfo = UserInfo(id: "1", name: self.name)
        dispatch_async(queue) {
            request.completeWithObject(userInfo)
        }
        return request
    }
}
