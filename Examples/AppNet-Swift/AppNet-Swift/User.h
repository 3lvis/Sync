#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * remoteID;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *data;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addDataObject:(NSManagedObject *)value;
- (void)removeDataObject:(NSManagedObject *)value;
- (void)addData:(NSSet *)values;
- (void)removeData:(NSSet *)values;

@end
