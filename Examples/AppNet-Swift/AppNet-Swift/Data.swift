//
//  Data.swift
//  AppNet-Swift
//
//  Created by Kostiantyn Koval on 04/04/15.
//  Copyright (c) 2015 Ramon Gilabert. All rights reserved.
//

import Foundation
import CoreData

class Data: NSManagedObject {

    @NSManaged var createdAt: NSDate
    @NSManaged var remoteID: String
    @NSManaged var text: String
    @NSManaged var user: User

}
