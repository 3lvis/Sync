import CoreData

extension NSEntityDescription {
    func sync_relationships() -> [NSRelationshipDescription] {
        var relationships = [NSRelationshipDescription]()
        for propertyDescription in self.properties {
            if propertyDescription.isKindOfClass(NSRelationshipDescription.self), let relationshipDescription = propertyDescription as? NSRelationshipDescription {
                relationships.append(relationshipDescription)
            }
        }

        return relationships
    }

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
