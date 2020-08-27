//
//  Processor.swift
//  NewCache
//
//  Created by Juan Jose Arreola Simon on 13/05/20.
//

import Foundation

protocol Processor {
    associatedtype T
    
    var key: String { get }
    func process(_ instance: T) throws -> T
}
