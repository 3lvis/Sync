#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Stories : NSManagedObject

@property (nonatomic, retain) NSNumber * numComments;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * remoteID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSArray * comments;

@end
