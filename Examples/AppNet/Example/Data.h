//
//  Data.h
//  Example
//
//  Created by Elvis Nuñez on 11/12/14.
//  Copyright (c) 2014 Sync. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Data : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * remoteID;
@property (nonatomic, retain) NSString * canonicalURL;
@property (nonatomic, retain) NSString * threadID;
@property (nonatomic, retain) NSString * paginationID;
@property (nonatomic, retain) User *user;

@end
