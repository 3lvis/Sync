//
//  User.h
//  Example
//
//  Created by Elvis Nuñez on 11/12/14.
//  Copyright (c) 2014 Sync. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Data;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * canonicalURL;
@property (nonatomic, retain) NSString * remoteID;
@property (nonatomic, retain) NSString * userType;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *datas;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addDatasObject:(Data *)value;
- (void)removeDatasObject:(Data *)value;
- (void)addDatas:(NSSet *)values;
- (void)removeDatas:(NSSet *)values;

@end
