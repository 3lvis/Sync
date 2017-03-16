//
//  User+CoreDataProperties.swift
//  Demo
//
//  Created by Elvis Nuñez on 2/11/17.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User");
    }

    @NSManaged public var id: String?

}
