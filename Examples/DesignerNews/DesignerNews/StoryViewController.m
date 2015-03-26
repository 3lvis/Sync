#import "StoryViewController.h"

#import "DNStory.h"
#import "DNComment.h"
#import "DATAStack.h"
#import "DATASource.h"
#import "CommentTableViewCell.h"

@interface StoryViewController ()

@property (nonatomic, weak) DNStory *story;
@property (nonatomic, weak) DATAStack *dataStack;
@property (nonatomic) DATASource *dataSource;

@end

@implementation StoryViewController

#pragma mark - Initializers

- (instancetype)initWithStory:(DNStory *)story
                 andDataStack:(DATAStack *)dataStack
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (!self) return nil;

    _story = story;
    _dataStack = dataStack;

    return self;
}

#pragma mark - Getters

- (DATASource *)dataSource
{
    if (_dataSource) return _dataSource;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Comment"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"upvotesCount"
                                                              ascending:NO],
                                [NSSortDescriptor sortDescriptorWithKey:@"remoteID"
                                                              ascending:NO]];

    _dataSource = [[DATASource alloc] initWithTableView:self.tableView
                                           fetchRequest:request
                                         cellIdentifier:CommentTableViewCellIdentifier
                                            mainContext:self.dataStack.mainContext];

    _dataSource.configureCellBlock = ^(CommentTableViewCell *cell,
                                       DNComment *comment,
                                       NSIndexPath *indexPath) {
        cell.textLabel.text = comment.body;
    };

    return _dataSource;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.story.title;
    self.tableView.dataSource = self.dataSource;
    [self.tableView registerClass:[CommentTableViewCell class] forCellReuseIdentifier:CommentTableViewCellIdentifier];
}

@end
