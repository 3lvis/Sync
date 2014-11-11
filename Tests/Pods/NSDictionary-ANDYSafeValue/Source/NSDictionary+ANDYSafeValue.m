//
//  NSDictionary+ANDYSafeValue.m
//
//  Created by Elvis Nunez on 02/11/14.
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

#import "NSDictionary+ANDYSafeValue.h"

@implementation NSDictionary (ANDYSafeValue)

- (id)andy_valueForKey:(id)key
{
    if (!key) return nil;

    id value = [self valueForKeyPath:key];

    if (!value) return nil;

    if (value != [NSNull null] && [value isKindOfClass:[NSString class]] && [value length] == 0) return nil;

    if (value == [NSNull null]) return nil;

    return value;
}

- (void)andy_setValue:(id)value forKey:(id)key
{
    if (value && key && value != [NSNull null]) [self setValue:value forKey:key];
}

@end
