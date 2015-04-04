@import Foundation;
@import CoreData;

@class User;

@interface Data : NSManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * remoteID;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) User *user;

@end
