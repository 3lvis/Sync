#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Stories;

@interface Comments : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * remoteID;
@property (nonatomic, retain) Stories *stories;

@end
