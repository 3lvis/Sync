import Foundation

extension NSManagedObject {

  public func processRelationshipsUsingDictionary(
    objectDictionary dictionary: [NSObject : AnyObject],
    parent: NSManagedObject?,
    dataStack: DATAStack) {

      let relationships = self.relationships()
      for relationship in relationships {
        if relationship.toMany {
          self.processToManyRelationship(
            relationship,
            usingDictionary: dictionary,
            parent: parent,
            dataStack: dataStack)
        } else if parent != nil && relationship.destinationEntity?.name == parent?.entity.name! {
          self.setValue(parent!, forKey: relationship.name)
        } else {
          self.processToOneRelationship(
            relationship,
            usingDictionary: dictionary)
        }
      }
  }

  private func relationshipName(relationship: NSRelationshipDescription) -> String {
    var relationshipName = relationship.name

    if let
      userInfo = relationship.userInfo,
      relationshipKey = userInfo[SyncConstants.CustomRemoteKey] as? String {
        relationshipName = relationshipKey
    }

    return relationshipName
  }

  func copyInContext(context: NSManagedObjectContext) -> NSManagedObject? {
    let entity = NSEntityDescription.entityForName(
      self.entity.name!,
      inManagedObjectContext: context)

    let localKey = entity!.localKey()
    let remoteID: AnyObject? = valueForKey(localKey)

    return Sync.safeObjectInContext(
      context,
      entityName: self.entity.name!,
      remoteID: remoteID!)
  }

  private func relationships() -> [NSRelationshipDescription] {
    var relationships = [NSRelationshipDescription]()

    for property in self.entity.properties {
      if let property = property as? NSRelationshipDescription {
        relationships.append(property)
      }
    }

    return relationships
  }

  private func processToManyRelationship(
    relationship: NSRelationshipDescription, usingDictionary
    dictionary: [NSObject : AnyObject],
    parent: NSManagedObject?,
    dataStack: DATAStack) {

      let relationshipName = self.relationshipName(relationship)
      let childEntityName: String = relationship.destinationEntity!.name!
      let parentEntityName: String? = parent?.entity.name
      let inverseEntityName: String = relationship.inverseRelationship!.name
      let inverseIsToMany: Bool = relationship.inverseRelationship!.toMany
      let hasValidManyToManyRelationship = (parent != nil && inverseIsToMany && parentEntityName == childEntityName)

      var children: NSArray?
      if let keyExists: AnyObject? = dictionary[relationshipName] {
        children = dictionary[relationshipName] as? NSArray
      }

      if children != nil {
        var childPredicate = NSPredicate()
        let entity = NSEntityDescription.entityForName(
          childEntityName,
          inManagedObjectContext: self.managedObjectContext!)

        if inverseIsToMany {
          if let destinationRemoteKey = entity?.remoteKey() {
            let childsIDs: AnyObject? = children!.valueForKey(destinationRemoteKey)
            let destinationLocalKey = entity?.localKey()

            if childsIDs!.count == 1 {
              let childKey: Int = children!.valueForKey(destinationRemoteKey)!.firstObject!!.integerValue
              childPredicate = NSPredicate(
                format: "%K = \(childKey)",
                destinationLocalKey!)
            } else {
              childPredicate = NSPredicate(
                format: "ANY %K.%K = %@",
                relationshipName,
                destinationLocalKey!,
                children!.valueForKey(destinationRemoteKey) as! NSArray)
            }
          }
        } else {
          childPredicate = NSPredicate(format: "%K = %@", inverseEntityName, self)
        }

        Sync.changes(
          children! as Array,
          entityName: childEntityName,
          predicate: childPredicate,
          parent: self,
          context: self.managedObjectContext!,
          dataStack: dataStack,
          completion: nil)

      } else if hasValidManyToManyRelationship {
        let relatedObjects = mutableSetValueForKey(relationshipName)
        relatedObjects.addObject(parent!)
        self.setValue(relatedObjects, forKey: relationshipName)
      }
  }

  private func processToOneRelationship(
    relationship: NSRelationshipDescription,
    usingDictionary dictionary: [NSObject : AnyObject]) {

      let relationshipName = self.relationshipName(relationship)
      let entityName = relationship.destinationEntity?.name
      let entity = NSEntityDescription.entityForName(entityName!, inManagedObjectContext: self.managedObjectContext!)

      if let filteredObjectDictionary = dictionary[relationshipName] as? [NSObject : AnyObject] {
        if let
          remoteKey: String = entity?.remoteKey(),
          remoteID: AnyObject = filteredObjectDictionary[remoteKey] {
            if let
              updatedObject = Sync.safeObjectInContext(self.managedObjectContext!,
                entityName: entityName!,
                remoteID: remoteID) {
                  updatedObject.hyp_fillWithDictionary(filteredObjectDictionary)
                  self.setValue(updatedObject, forKey: relationship.name)
            } else if let newObject = NSEntityDescription.insertNewObjectForEntityForName(entityName!,
              inManagedObjectContext: self.managedObjectContext!) as? NSManagedObject {
                newObject.hyp_fillWithDictionary(filteredObjectDictionary)
                self.setValue(newObject, forKey: relationship.name)
            }
        }
      }
  }

}
