//
//  NSDictionary+ANDYSafeValue.h
//
//  Created by Elvis Nunez on 02/11/14.
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

@import Foundation;

@interface NSDictionary (ANDYSafeValue)

- (id)andy_valueForKey:(id)key;

- (void)andy_setValue:(id)value forKey:(id)key;

@end
