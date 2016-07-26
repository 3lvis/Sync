//
//  Comment+CoreDataProperties.swift
//  
//
//  Created by Elvis Nuñez on 26/07/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Comment {

    @NSManaged var body: String?
    @NSManaged var comments: NSOrderedSet?

}
