@import Foundation;
@import DATAStack;

@interface APIClient : NSObject

- (void)fetchStoryUsingDataStack:(DATAStack *)dataStack;

@end
