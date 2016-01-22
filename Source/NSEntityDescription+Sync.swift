import CoreData

extension NSEntityDescription {
    /**
     Finds the relationships for the current entity.
     - returns The list of relationships for the current entity.
     */
    func sync_relationships() -> [NSRelationshipDescription] {
        var relationships = [NSRelationshipDescription]()
        for propertyDescription in self.properties {
            if propertyDescription.isKindOfClass(NSRelationshipDescription.self), let relationshipDescription = propertyDescription as? NSRelationshipDescription {
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
        let relationships = self.sync_relationships()
        var foundParentEntity: NSRelationshipDescription? = nil
        for relationship in relationships {
            let isParent = relationship.destinationEntity?.name == self.name && !relationship.toMany
            if isParent {
                foundParentEntity = relationship
            }
        }

        return foundParentEntity
    }
}
