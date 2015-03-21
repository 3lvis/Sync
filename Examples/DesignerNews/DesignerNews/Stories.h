#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Stories : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * comment_count;
@property (nonatomic, retain) NSNumber * created_at;
@property (nonatomic, retain) NSString * remoteID;

@end
