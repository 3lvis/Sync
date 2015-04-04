//
//  User.swift
//  AppNet-Swift
//
//  Created by Kostiantyn Koval on 04/04/15.
//  Copyright (c) 2015 Ramon Gilabert. All rights reserved.
//

import Foundation
import CoreData

class User: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var remoteID: String
    @NSManaged var username: String
    @NSManaged var data: NSSet

}
