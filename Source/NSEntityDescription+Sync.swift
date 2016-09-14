import CoreData

extension NSEntityDescription {
    /**
     Finds the relationships for the current entity.
     - returns The list of relationships for the current entity.
     */
    func sync_relationships() -> [NSRelationshipDescription] {
        var relationships = [NSRelationshipDescription]()
        for propertyDescription in properties {
            if let relationshipDescription = propertyDescription as? NSRelationshipDescription {
                relationships.append(relationshipDescription)
            }
        }

        return relationships
    }

    /**
     Finds the parent for the current entity, if there are many parents nil will be returned.
     - returns The parent relationship for the current entity
     */
    func sync_parentEntity() -> NSRelationshipDescription? {
        return sync_relationships().filter { $0.destinationEntity?.name == name && !$0.isToMany }.first
    }
}
