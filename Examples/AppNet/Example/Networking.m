#import "Networking.h"

#import "Sync.h"

static NSString * const NetworkingURL = @"https://api.app.net/posts/stream/global";

@interface Networking ()

@property (nonatomic, weak) DATAStack *dataStack;

@end

@implementation Networking

- (instancetype)initWithDataStack:(DATAStack *)dataStack
{
    self = [super init];
    if (!self) return nil;

    _dataStack = dataStack;

    return self;
}

- (void)fetchPosts
{
    NSURL *url = [NSURL URLWithString:NetworkingURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue new];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {

                               if (connectionError) NSLog(@"connectionError: %@", connectionError);

                               if (data) {
                                   NSError *JSONSerializationError = nil;
                                   NSJSONSerialization *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&JSONSerializationError];
                                   if (JSONSerializationError) NSLog(@"JSONSerializationError: %@", JSONSerializationError);
                                   [Sync changes:[JSON valueForKey:@"data"]
                                   inEntityNamed:@"Data"
                                       dataStack:self.dataStack
                                      completion:nil];
                               }
                           }];
}

@end
