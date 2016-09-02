//
//  ObjectProcessor.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation


open class ObjectProcessor<T: AnyObject> {
    
    var identifier: String?
    
    func processObject(_ object: T, respondInQueue queue: DispatchQueue, completion: (_ getObject: () throws -> T) -> Void) {}
}
