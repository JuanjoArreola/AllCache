//
//  DataStack.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation
import CoreData

enum DataStackError: ErrorType {
    case PathError
    case InvalidManagedObjectModel
}

class DataStack {
    
    private(set) var managedObjectModel: NSManagedObjectModel!
    private(set) var managedObjectContext: NSManagedObjectContext!
    
    convenience init(modelName: String, dataStoreName: String, options: [String: AnyObject]? = nil, concurrencyType: NSManagedObjectContextConcurrencyType = .MainQueueConcurrencyType) throws {
        let fileManager = NSFileManager.defaultManager()
        let documents = try fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
        let dataStoreURL = documents.URLByAppendingPathComponent("\(dataStoreName).sqlite")
        guard let momURL = NSBundle.mainBundle().URLForResource(modelName, withExtension: "momd") else {
            throw DataStackError.PathError
        }
        try self.init(managedObjectModelURL: momURL, dataStoreURL: dataStoreURL, options: options, concurrencyType: concurrencyType)
    }
    
    required init(managedObjectModelURL momURL: NSURL, dataStoreURL: NSURL, options: [String: AnyObject]?, concurrencyType: NSManagedObjectContextConcurrencyType) throws {
        managedObjectModel = NSManagedObjectModel(contentsOfURL: momURL)
        if managedObjectModel == nil {
            throw DataStackError.InvalidManagedObjectModel
        }
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: dataStoreURL, options: options)
        managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
    }
    
}
