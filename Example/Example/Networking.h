@import Foundation;

@class DATAStack;

@interface Networking : NSObject

- (instancetype)initWithDataStack:(DATAStack *)dataStack;

- (void)fetchPosts;

@end
