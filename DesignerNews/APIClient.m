#import "APIClient.h"
#import "Sync.h"
@import UIKit;

static NSString * const HYPBaseURL = @"https://www.designernews.co/?format=json";

@interface APIClient ()

@property (nonatomic, weak) DATAStack *dataStack;

@end

@implementation APIClient

- (void)fetchStoryUsingDataStack:(DATAStack *)dataStack
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:HYPBaseURL]];
    NSOperationQueue *queue = [NSOperationQueue new];
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (connectionError) {
                                   NSLog(@"There was an error: %@", connectionError);
                               } else {
                                   NSError *serializationError = nil;
                                   NSJSONSerialization *JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                               options:NSJSONReadingMutableContainers
                                                                                                 error:&serializationError];

                                   if (serializationError) {
                                       NSLog(@"Error serializing JSON: %@", serializationError);
                                   } else {
                                       [Sync changes:[JSON valueForKey:@"stories"]
                                       inEntityNamed:@"Story"
                                           dataStack:dataStack
                                          completion:^(NSError *error) {
                                              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                          }];
                                   }
                               }
                           }];
}

@end
