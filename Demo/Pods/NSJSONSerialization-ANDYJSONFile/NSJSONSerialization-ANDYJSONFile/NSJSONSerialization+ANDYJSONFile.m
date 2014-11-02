//
//  NSJSONSerialization+ANDYJSONFile.m
//
//  Created by Elvis Nunez on 4/29/14.
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

#import "NSJSONSerialization+ANDYJSONFile.h"

@implementation NSJSONSerialization (ANDYJSONFile)

+ (id)JSONObjectWithContentsOfFile:(NSString*)fileName
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:[fileName stringByDeletingPathExtension]
                                                         ofType:[fileName pathExtension]];

    NSData *data = [NSData dataWithContentsOfFile:filePath];

    NSError *error = nil;

    id result = [NSJSONSerialization JSONObjectWithData:data
                                                options:NSJSONReadingMutableContainers
                                                  error:&error];
    if (error != nil) return nil;

    return result;
}

@end
