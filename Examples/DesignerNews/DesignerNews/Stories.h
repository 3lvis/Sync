#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Stories : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * commentCount;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * remoteID;

@end
