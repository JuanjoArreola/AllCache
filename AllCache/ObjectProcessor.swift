//
//  ObjectProcessor.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation


public class ObjectProcessor<T: AnyObject> {
    
    var identifier: String?
    
    func processObject(object: T, respondInQueue queue: dispatch_queue_t, completion: (getObject: () throws -> T) -> Void) {}
}