@import Foundation;
@import CoreData;


@interface Stories : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSNumber * numComments;
@property (nonatomic, retain) NSString * remoteID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSData * comments;

@end
