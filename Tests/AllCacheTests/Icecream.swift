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

class Icecream: NSObject, NSCoding {
    
    var id: String
    var flavor: String
    var topping: String?
    
    init(id: String, flavor: String) {
        self.id = id
        self.flavor = flavor
    }
    
    // MARK: - NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObject(forKey: "id") as? String,
            let flavor = aDecoder.decodeObject(forKey: "flavor") as? String else {
            return nil
        }
        self.id = id
        self.flavor = flavor
        self.topping = aDecoder.decodeObject(forKey: "topping") as? String
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(flavor, forKey: "flavor")
        if let topping = self.topping {
            aCoder.encode(topping, forKey: "topping")
        }
    }
    
}

class IcecreamFetcher: Fetcher<Icecream> {
    
    var data = ["1": "Vanilla", "2": "Chocolate", "3": "Mango"]
    static var fetchedCount = 0
    
    override func fetch(respondIn queue: DispatchQueue, completion: @escaping (() throws -> FetcherResult<Icecream>) -> Void) -> Request<FetcherResult<Icecream>> {
        let request = Request<FetcherResult<Icecream>>(completionHandler: completion)
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
    
    override open func process(object: Icecream, respondIn queue: DispatchQueue, completion: @escaping (_ getObject: () throws -> Icecream) -> Void) {
        queue.async {
            object.topping = self.identifier
            ToppingProcessor.toppingsAdded += 1
            completion({ return object })
        }
    }
}
