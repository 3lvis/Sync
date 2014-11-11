//
//  NSJSONSerialization+ANDYJSONFile.m
//
//  Created by Elvis Nunez on 4/29/14.
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

@import Foundation;

@interface NSJSONSerialization (ANDYJSONFile)

+ (id)JSONObjectWithContentsOfFile:(NSString*)fileName inBundle:(NSBundle *)bundle;

+ (id)JSONObjectWithContentsOfFile:(NSString*)fileName;

@end
