//
//  Icecream.swift
//  NewCacheTests
//
//  Created by JuanJo on 02/09/20.
//

import Foundation
import NewCache
import ShallowPromises

class Icecream: Codable, Equatable {
    var id: String
    var flavor: String
    var topping: String?
    
    init(id: String, flavor: String) {
        self.id = id
        self.flavor = flavor
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}

struct IcecreamFetcher: Fetcher {
    
    var data = ["1": "Vanilla", "2": "Chocolate", "3": "Mango"]
    static var fetchedCount = 0
    
    var identifier: String
    
    func fetch() -> Promise<FetcherResult<Icecream>> {
        let promise = Promise<FetcherResult<Icecream>>()
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.3) {
            if let flavor = self.data[self.identifier] {
                IcecreamFetcher.fetchedCount += 1
                let result = Icecream(id: self.identifier, flavor: flavor)
                promise.fulfill(with: FetcherResult(instance: result, data: nil))
            } else {
                promise.complete(with: FetchError.notFound)
            }
        }
        return promise
    }
}

class ToppingProcessor: Processor<Icecream> {
    
    static var toppingsAdded = 0
    
    override func process(_ instance: Icecream) throws -> Icecream {
        instance.topping = self.identifier
        ToppingProcessor.toppingsAdded += 1
        return instance
    }
}
