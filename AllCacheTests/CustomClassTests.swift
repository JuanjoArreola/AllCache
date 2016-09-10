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
        
        let exp: XCTestExpectation = expectation(description: "get user")
        
        _ = userCache.objectForKey("user_1", objectFetcher: ObjectFetcher<UserInfo>(identifier: "user_1")) { (getObject) -> Void in
            do {
                _ = try getObject()
                exp.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testDeleteObject() {
        let userInfo = UserInfo(id: "1", name: "Juanjo")
        userCache.setObject(userInfo, forKey: "user_2")
        userCache.removeObjectForKey("user_2")
        
        let expectation: XCTestExpectation = self.expectation(description: "get user")
        
        _ = userCache.objectForKey("user_2", objectFetcher: ObjectFetcher<UserInfo>(identifier: "user_2")) { (getObject) -> Void in
            do {
                _ = try getObject()
                XCTFail()
            } catch {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testFetchObject() {
        let expectation: XCTestExpectation = self.expectation(description: "get user")
        _ = userCache.objectForKey("user_1", objectFetcher: UserFetcher(userName: "Juanjo")) { (getObject) -> Void in
            do {
                _ = try getObject()
                expectation.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
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
        guard let id = aDecoder.decodeObject(forKey: "id") as? String else { return nil }
        guard let name = aDecoder.decodeObject(forKey: "name") as? String else { return nil }
        self.init(id: id, name: name)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
    }
}

class UserFetcher: ObjectFetcher<UserInfo> {
    
    var name: String!
    
    convenience init(userName: String) {
        self.init(identifier: userName)
        self.name = userName
    }
    
    override func fetchAndRespond(inQueue queue: DispatchQueue, completion: @escaping (_ getFetcherResult: () throws -> FetcherResult<UserInfo>) -> Void) -> Request<FetcherResult<UserInfo>> {
        let request = Request<FetcherResult<UserInfo>>(completionHandler: completion)
        let userInfo = UserInfo(id: "1", name: self.name)
        queue.async {
            request.completeWithObject(FetcherResult(object: userInfo, data: nil))
        }
        return request
    }

}
