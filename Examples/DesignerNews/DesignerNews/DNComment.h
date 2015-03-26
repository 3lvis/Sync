@import Foundation;
@import CoreData;

@class DNComment, DNStory;

@interface DNComment : NSManagedObject

@property (nonatomic) NSString *body;
@property (nonatomic) NSString *remoteID;
@property (nonatomic) NSNumber *depth;
@property (nonatomic) NSString *userDisplayName;
@property (nonatomic) NSNumber *upvotesCount;
@property (nonatomic) DNStory *story;
@property (nonatomic) NSSet *comments;
@end

@interface DNComment (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(DNComment *)value;
- (void)removeCommentsObject:(DNComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end
