@import Foundation;
@import CoreData;

@class User;

@interface Data : NSManagedObject

@property (nonatomic) NSDate * createdAt;
@property (nonatomic) NSString * text;
@property (nonatomic) NSString * remoteID;
@property (nonatomic) NSString * canonicalURL;
@property (nonatomic) NSString * threadID;
@property (nonatomic) NSString * paginationID;
@property (nonatomic) User *user;

@end
