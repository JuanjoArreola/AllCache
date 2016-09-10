//
//  ObjectProcessor.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation


open class ObjectProcessor<T: Any> {
    
    var identifier: String?
    
    func process(object: T, respondIn queue: DispatchQueue, completion: @escaping (_ getObject: () throws -> T) -> Void) {}
}
