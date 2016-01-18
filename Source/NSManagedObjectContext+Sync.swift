import CoreData
import NSEntityDescription_SYNCPrimaryKey
import NSString_HYPNetworking

public extension NSManagedObjectContext {
    /**
     Safely fetches a NSManagedObject in the current context.
     - parameter entityName: The name of the Core Data entity.
     - parameter remoteID: The primary key.
     - parameter parent: The parent of the object.
     - parameter parentRelationshipName: The name of the relationship with the parent.
     - returns: A NSManagedObject contained in the provided context.
     */
    public func sync_safeObject(entityName: String, remoteID: AnyObject?, parent: NSManagedObject?, parentRelationshipName: String?) -> NSManagedObject {
        if let remoteID = remoteID {
            let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self)!
            let request = NSFetchRequest(entityName: entityName)
            let localKey = entity.sync_localKey()
            request.predicate = NSPredicate(format: "%K = %@", localKey, (remoteID as! NSObject))
            let objects = try! self.executeFetchRequest(request)
            return objects.first! as! NSManagedObject
        } else {
            return parent!.valueForKey(parentRelationshipName!) as! NSManagedObject
        }
    }

    func sync_processToManyRelationship(relationship: NSRelationshipDescription, usingDictionary dictionary: NSDictionary, andParent parent: NSManagedObject, dataStack: DATAStack) {
        let relationshipKey = relationship.userInfo![SYNCCustomRemoteKey]
        let name = relationship.name as NSString
        let relationshipName = (relationshipKey == nil) ? relationshipKey : name.hyp_remoteString()
        let childEntityName = relationship.destinationEntity!.name
        let parentEntityName = parent.entity.name
        let inverseEntityName = relationship.inverseRelationship!.name
        let inverseIsToMany = relationship.inverseRelationship!.isToMany
    }
}

/*
- (void)sync_processToManyRelationship:(NSRelationshipDescription *)relationship
usingDictionary:(NSDictionary *)objectDictionary
andParent:(NSManagedObject *)parent
dataStack:(DATAStack *)dataStack {
    NSString *relationshipKey = relationship.userInfo[SYNCCustomRemoteKey];
    NSString *relationshipName = (relationshipKey) ?: [relationship.name hyp_remoteString];
    NSString *childEntityName = relationship.destinationEntity.name;
    NSString *parentEntityName = parent.entity.name;
    NSString *inverseEntityName = relationship.inverseRelationship.name;
    BOOL inverseIsToMany = relationship.inverseRelationship.isToMany;
    BOOL hasValidManyToManyRelationship = (parent &&
    inverseIsToMany &&
    [parentEntityName isEqualToString:childEntityName]);
    NSArray *children = [objectDictionary andy_valueForKey:relationshipName];

    if (children) {
        NSPredicate *childPredicate;
        NSEntityDescription *entity = [NSEntityDescription entityForName:childEntityName
            inManagedObjectContext:self.managedObjectContext];

        if (inverseIsToMany) {
            NSString *destinationRemoteKey = [entity sync_remoteKey];
            NSArray *childIDs = [children valueForKey:destinationRemoteKey];
            NSString *destinationLocalKey = [entity sync_localKey];
            if (childIDs.count > 0) {
                childPredicate = [NSPredicate predicateWithFormat:@"ANY %K IN %@", destinationLocalKey, [children valueForKey:destinationRemoteKey]];
            }
        } else {
            childPredicate = [NSPredicate predicateWithFormat:@"%K = %@", inverseEntityName, self];
        }

        [Sync changes:children
            inEntityNamed:childEntityName
            predicate:childPredicate
            parent:self
            inContext:self.managedObjectContext
            dataStack:dataStack
            completion:nil];
    } else if (hasValidManyToManyRelationship) {
        NSMutableSet *relatedObjects = [self mutableSetValueForKey:relationship.name];
        if (![relatedObjects containsObject:parent]) {
            [relatedObjects addObject:parent];
            [self setValue:relatedObjects
                forKey:relationship.name];
        }
    }
}

- (void)sync_processToOneRelationship:(NSRelationshipDescription *)relationship
usingDictionary:(NSDictionary *)objectDictionary
andParent:(NSManagedObject *)parent
dataStack:(DATAStack *)dataStack
error:(NSError **)error {
    NSString *relationshipKey = [[relationship userInfo] valueForKey:SYNCCustomRemoteKey];
    NSString *relationshipName = (relationshipKey) ?: [relationship.name hyp_remoteString];
    NSString *entityName = relationship.destinationEntity.name;
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
    inManagedObjectContext:self.managedObjectContext];
    NSDictionary *filteredObjectDictionary = [objectDictionary andy_valueForKey:relationshipName];
    if (filteredObjectDictionary) {
        NSError *error = nil;
        NSString *remoteKey = [entity sync_remoteKey];
        NSManagedObject *object = [NSManagedObject sync_safeObjectInContext:self.managedObjectContext
            entityName:entityName
            remoteID:[filteredObjectDictionary andy_valueForKey:remoteKey]
            parent:self
            parentRelationshipName:relationship.name
            error:&error];

        if (!object) {
            object = [NSEntityDescription insertNewObjectForEntityForName:entityName
                inManagedObjectContext:self.managedObjectContext];
        }

        [object hyp_fillWithDictionary:filteredObjectDictionary];
        [object sync_processRelationshipsUsingDictionary:filteredObjectDictionary
            andParent:self
            dataStack:dataStack
            error:&error];
        id currentRelationship = [self valueForKey:relationship.name];
        if (![currentRelationship isEqual:object]) {
            [self setValue:object
                forKey:relationship.name];
        }
    }
    }

    - (void)sync_processIDRelationship:(NSRelationshipDescription *)relationship
remoteID:(NSNumber *)remoteID
andParent:(NSManagedObject *)parent
dataStack:(DATAStack *)dataStack
error:(NSError **)error {
    NSString *entityName = relationship.destinationEntity.name;

    NSError *errors = nil;
    NSManagedObject *object = [NSManagedObject sync_safeObjectInContext:self.managedObjectContext
        entityName:entityName
        remoteID:remoteID
        parent:self
        parentRelationshipName:relationship.name
        error:&errors];
    if (object) {
        id currentRelationship = [self valueForKey:relationship.name];
        if (![currentRelationship isEqual:object]) {
            [self setValue:object
                forKey:relationship.name];
        }
    }
}

*/
