//
//  NSManagedObject+HYPPropertyMapper.m
//
//  Created by Christoffer Winterkvist on 7/2/14.
//  Copyright (c) 2014 Hyper. All rights reserved.
//

@import CoreData;

@interface NSString (PrivateInflections)

- (NSString *)remoteString;
- (NSString *)localString;
- (NSString *)replacementIdentifier:(NSString *)replacementString;
- (NSString *)lowerCaseFirstLetter;
- (BOOL)containsWord:(NSString *)word;

@end

@interface NSManagedObject (HYPPropertyMapper)

- (void)hyp_fillWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)hyp_dictionary;

@end
