//
//  Icecream.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 17/05/17.
//
//

import Foundation
import AllCache
import AsyncRequest

class Icecream: Codable {
    
    var id: String
    var flavor: String
    var topping: String?
    
    init(id: String, flavor: String) {
        self.id = id
        self.flavor = flavor
    }
}

class IcecreamFetcher: Fetcher<Icecream> {
    
    var data = ["1": "Vanilla", "2": "Chocolate", "3": "Mango"]
    static var fetchedCount = 0
    
    override func fetch(respondIn queue: DispatchQueue, completion: @escaping (FetcherResult<Icecream>) -> Void) -> Request<FetcherResult<Icecream>> {
        let request = Request<FetcherResult<Icecream>>(successHandler: completion)
        queue.asyncAfter(deadline: DispatchTime.now() + 0.3) {
            if let flavor = self.data[self.identifier] {
                IcecreamFetcher.fetchedCount += 1
                request.complete(with: FetcherResult<Icecream>(object: Icecream(id: self.identifier, flavor: flavor), data: nil))
            } else {
                request.complete(with: FetchError.notFound)
            }
        }
        return request
    }
}

class ToppingProcessor: Processor<Icecream> {
    
    static var toppingsAdded = 0
    
    override open func process(object: Icecream) throws -> Icecream {
        object.topping = self.identifier
        ToppingProcessor.toppingsAdded += 1
        return object
    }
}
