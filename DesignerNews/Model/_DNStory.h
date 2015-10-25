// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DNStory.h instead.

#import <CoreData/CoreData.h>

extern const struct DNStoryAttributes {
	__unsafe_unretained NSString *commentsCount;
	__unsafe_unretained NSString *createdAt;
	__unsafe_unretained NSString *remoteID;
	__unsafe_unretained NSString *title;
} DNStoryAttributes;

extern const struct DNStoryRelationships {
	__unsafe_unretained NSString *comments;
} DNStoryRelationships;

@class DNComment;

@interface DNStoryID : NSManagedObjectID {}
@end

@interface _DNStory : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly) DNStoryID* objectID;

@property (nonatomic) NSNumber* commentsCount;

@property (atomic) int32_t commentsCountValue;
- (int32_t)commentsCountValue;
- (void)setCommentsCountValue:(int32_t)value_;

//- (BOOL)validateCommentsCount:(id*)value_ error:(NSError**)error_;

@property (nonatomic) NSDate* createdAt;

//- (BOOL)validateCreatedAt:(id*)value_ error:(NSError**)error_;

@property (nonatomic) NSNumber* remoteID;

@property (atomic) int32_t remoteIDValue;
- (int32_t)remoteIDValue;
- (void)setRemoteIDValue:(int32_t)value_;

//- (BOOL)validateRemoteID:(id*)value_ error:(NSError**)error_;

@property (nonatomic) NSString* title;

//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;

@property (nonatomic) NSSet *comments;

- (NSMutableSet*)commentsSet;

@end

@interface _DNStory (CommentsCoreDataGeneratedAccessors)
- (void)addComments:(NSSet*)value_;
- (void)removeComments:(NSSet*)value_;
- (void)addCommentsObject:(DNComment*)value_;
- (void)removeCommentsObject:(DNComment*)value_;

@end

@interface _DNStory (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveCommentsCount;
- (void)setPrimitiveCommentsCount:(NSNumber*)value;

- (int32_t)primitiveCommentsCountValue;
- (void)setPrimitiveCommentsCountValue:(int32_t)value_;

- (NSDate*)primitiveCreatedAt;
- (void)setPrimitiveCreatedAt:(NSDate*)value;

- (NSNumber*)primitiveRemoteID;
- (void)setPrimitiveRemoteID:(NSNumber*)value;

- (int32_t)primitiveRemoteIDValue;
- (void)setPrimitiveRemoteIDValue:(int32_t)value_;

- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;

- (NSMutableSet*)primitiveComments;
- (void)setPrimitiveComments:(NSMutableSet*)value;

@end
