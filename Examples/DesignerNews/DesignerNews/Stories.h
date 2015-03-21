//
//  Stories.h
//  
//
//  Created by Ramon Gilabert Llop on 3/21/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Stories : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * comment_count;
@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSString * remoteID;

@end
