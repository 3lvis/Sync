#import "APIClient.h"
#import "Sync.h"

static NSString * const HYPBaseURL = @"https://news.layervault.com/?format=json";

@interface APIClient ()

@property (nonatomic, weak) DATAStack *dataStack;

@end

@implementation APIClient

- (void)fetchStoryUsingDataStack:(DATAStack *)dataStack
{
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:HYPBaseURL]];
    NSOperationQueue *queue = [NSOperationQueue new];
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (connectionError) {
                                   NSLog(@"There was an error: %@", [[[connectionError userInfo] objectForKey:@"error"] capitalizedString]);
                               } else {
                                   NSError *serializationError = nil;
                                   NSJSONSerialization *JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                               options:NSJSONReadingMutableContainers
                                                                                                 error:&serializationError];

                                   if (serializationError) {
                                       NSLog(@"Error serializing JSON: %@", serializationError);
                                   } else {
                                       [Sync processChanges:[JSON valueForKey:@"stories"]
                                            usingEntityName:@"Story"
                                                  dataStack:dataStack
                                                 completion:nil];
                                   }
                               }
                           }];
}

@end
