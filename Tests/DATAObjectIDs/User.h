@import Foundation;
@import CoreData;

@interface User : NSManagedObject

@property (nonatomic) NSNumber * remoteID;
@property (nonatomic) NSString * localID;
@property (nonatomic) NSString * name;

@end
