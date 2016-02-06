//
//  ObjectInfo+CoreDataProperties.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/6/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ObjectInfo {

    @NSManaged var path: String!
    @NSManaged var lastAccess: NSDate!
    @NSManaged var size: NSNumber!
    @NSManaged var key: String!
    @NSManaged var cache: String!

}
