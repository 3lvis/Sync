// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DNComment.h instead.

#import <CoreData/CoreData.h>

extern const struct DNCommentAttributes {
	__unsafe_unretained NSString *body;
	__unsafe_unretained NSString *depth;
	__unsafe_unretained NSString *upvotesCount;
	__unsafe_unretained NSString *userDisplayName;
} DNCommentAttributes;

extern const struct DNCommentRelationships {
	__unsafe_unretained NSString *comments;
	__unsafe_unretained NSString *story;
} DNCommentRelationships;

@class DNComment;
@class DNStory;

@interface DNCommentID : NSManagedObjectID {}
@end

@interface _DNComment : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly) DNCommentID* objectID;

@property (nonatomic) NSString* body;

//- (BOOL)validateBody:(id*)value_ error:(NSError**)error_;

@property (nonatomic) NSNumber* depth;

@property (atomic) int16_t depthValue;
- (int16_t)depthValue;
- (void)setDepthValue:(int16_t)value_;

//- (BOOL)validateDepth:(id*)value_ error:(NSError**)error_;

@property (nonatomic) NSNumber* upvotesCount;

@property (atomic) int32_t upvotesCountValue;
- (int32_t)upvotesCountValue;
- (void)setUpvotesCountValue:(int32_t)value_;

//- (BOOL)validateUpvotesCount:(id*)value_ error:(NSError**)error_;

@property (nonatomic) NSString* userDisplayName;

//- (BOOL)validateUserDisplayName:(id*)value_ error:(NSError**)error_;

@property (nonatomic) NSSet *comments;

- (NSMutableSet*)commentsSet;

@property (nonatomic) DNStory *story;

//- (BOOL)validateStory:(id*)value_ error:(NSError**)error_;

@end

@interface _DNComment (CommentsCoreDataGeneratedAccessors)
- (void)addComments:(NSSet*)value_;
- (void)removeComments:(NSSet*)value_;
- (void)addCommentsObject:(DNComment*)value_;
- (void)removeCommentsObject:(DNComment*)value_;

@end

@interface _DNComment (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveBody;
- (void)setPrimitiveBody:(NSString*)value;

- (NSNumber*)primitiveDepth;
- (void)setPrimitiveDepth:(NSNumber*)value;

- (int16_t)primitiveDepthValue;
- (void)setPrimitiveDepthValue:(int16_t)value_;

- (NSNumber*)primitiveUpvotesCount;
- (void)setPrimitiveUpvotesCount:(NSNumber*)value;

- (int32_t)primitiveUpvotesCountValue;
- (void)setPrimitiveUpvotesCountValue:(int32_t)value_;

- (NSString*)primitiveUserDisplayName;
- (void)setPrimitiveUserDisplayName:(NSString*)value;

- (NSMutableSet*)primitiveComments;
- (void)setPrimitiveComments:(NSMutableSet*)value;

- (DNStory*)primitiveStory;
- (void)setPrimitiveStory:(DNStory*)value;

@end
