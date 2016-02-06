//
//  ManagedObjectRepository.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/6/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation
import CoreData

class ManagedObjectRepository<ManagedObject: NSManagedObject>: NSObject {
    
    var entityDescription: NSEntityDescription!
    var moc: NSManagedObjectContext!
    
    required init?(entityDescription: NSEntityDescription, managedObjectContext: NSManagedObjectContext) {
        super.init()
        self.entityDescription = entityDescription
        self.moc = managedObjectContext
        if self.entityDescription.name == nil {
            return nil
        }
    }
    
    required init?(entityName: String, managedObjectContext: NSManagedObjectContext) {
        super.init()
        if let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedObjectContext) {
            self.entityDescription = entityDescription
            self.moc = managedObjectContext
            if self.entityDescription.name == nil {
                return nil
            }
        } else {
            return nil
        }
    }
    
    //    MARK: - Create
    
    func create() -> ManagedObject? {
        return NSEntityDescription.insertNewObjectForEntityForName(entityDescription.name!, inManagedObjectContext: moc) as? ManagedObject
    }
    
    func save(object: ManagedObject) throws -> ManagedObject {
        if moc.hasChanges {
            try moc.save()
        }
        return object
    }
    
    //    MARK: - Fetch
    
    func all() -> [ManagedObject] {
        let request = NSFetchRequest()
        request.entity = entityDescription
        if let result = (try? moc.executeFetchRequest(request)) as? [ManagedObject] {
            return result
        }
        return []
    }
    
    func getWithPredicate(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [ManagedObject] {
        let fetchRequest = NSFetchRequest(entityName: entityDescription.name!)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        return try moc.executeFetchRequest(fetchRequest) as! [ManagedObject]
    }
    
}