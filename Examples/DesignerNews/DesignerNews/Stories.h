@import Foundation;
@import CoreData;


@interface Stories : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * commentCount;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * remoteID;

@end
