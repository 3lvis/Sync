#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Stories : NSManagedObject

@property (nonatomic, retain) NSString * titleStory;
@property (nonatomic, retain) NSNumber * numberComments;
@property (nonatomic, retain) NSDate * updated_at;

@end
