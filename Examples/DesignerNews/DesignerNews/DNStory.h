@import Foundation;
@import CoreData;

@class DNComment;

@interface DNStory : NSManagedObject

@property (nonatomic) NSDate *createdAt;
@property (nonatomic) NSNumber *commentsCount;
@property (nonatomic) NSString *remoteID;
@property (nonatomic) NSString *title;
@property (nonatomic) NSSet *comments;
@end

@interface DNStory (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(DNComment *)value;
- (void)removeCommentsObject:(DNComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end
