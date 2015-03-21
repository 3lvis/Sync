#import "DataManager.h"
#import "Sync.h"

static NSString * const URLToManage = @"https://api-news.layervault.com/api/v2/stories";

@interface DataManager ()

@property (nonatomic, weak) DATAStack *dataStack;

@end

@implementation DataManager

- (void)compareAndChangeStoriesWithDataStack:(DATAStack *)dataStack
{
    NSURL *urlFromString = [NSURL URLWithString:URLToManage];
    NSURLRequest *requestFromURL = [NSURLRequest requestWithURL:urlFromString];
    [NSURLConnection sendAsynchronousRequest:requestFromURL queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            NSLog(@"There was an error: %@", [[[connectionError userInfo] objectForKey:@"error"] capitalizedString]);
        } else {
            NSJSONSerialization *JSONFile = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            [Sync processChanges:[JSONFile valueForKey:@"stories"] usingEntityName:@"Stories" dataStack:dataStack completion:nil];
        }
    }];
}

@end
