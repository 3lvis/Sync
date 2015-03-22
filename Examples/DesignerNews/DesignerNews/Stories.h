@import Foundation;
@import CoreData;


@interface Stories : NSManagedObject

@property (nonatomic) NSString *title;
@property (nonatomic) NSNumber *commentCount;
@property (nonatomic) NSDate *createdAt;
@property (nonatomic) NSString *remoteID;

@end
