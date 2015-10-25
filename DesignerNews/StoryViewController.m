#import "StoryViewController.h"

#import "DNStory.h"
#import "DNComment.h"
@import DATAStack;
@import DATASource;

#import "UIFont+DNStyle.h"

static NSString * const CommentTableViewCellIdentifier = @"CommentTableViewCellIdentifier";
static const CGFloat CommentTableViewCellHeight = 50.0;

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
                                [NSSortDescriptor sortDescriptorWithKey:@"body"
                                                              ascending:NO]];
    request.predicate = [NSPredicate predicateWithFormat:@"story = %@", self.story];

    _dataSource = [[DATASource alloc] initWithTableView:self.tableView
                                         cellIdentifier:CommentTableViewCellIdentifier
                                           fetchRequest:request
                                            mainContext:self.dataStack.mainContext
                                            sectionName:nil
                                          configuration:^(UITableViewCell * _Nonnull cell, NSManagedObject * _Nonnull item, NSIndexPath * _Nonnull indexPath) {
                                              DNComment *comment = (DNComment *)item;
                                              cell.textLabel.text = comment.body;
                                              cell.textLabel.font = [UIFont commentFont];
                                              cell.textLabel.numberOfLines = 0;
                                          }];

    return _dataSource;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.story.title;
    self.tableView.dataSource = self.dataSource;
    self.tableView.rowHeight = CommentTableViewCellHeight;
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:CommentTableViewCellIdentifier];
}

@end
