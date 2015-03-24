#import "CommentsViewController.h"
#import "CommentsTableViewCell.h"
#import "DATAStack.h"
#import "DATASource.h"

@interface CommentsViewController ()

@property (nonatomic) DATAStack *dataStack;
@property (nonatomic) DATASource *dataSource;

@end

@implementation CommentsViewController

#pragma mark - Getters

- (DATASource *)dataSource
{
    if (_dataSource) return _dataSource;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Comments"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]];

    _dataSource = [[DATASource alloc] initWithTableView:self.tableView
                                           fetchRequest:request
                                         cellIdentifier:CellIdentifier
                                            mainContext:self.dataStack.mainContext];

    _dataSource.configureCellBlock = ^(CommentsTableViewCell *cell, Stories *story, NSIndexPath *indexPath) {
        [cell updateWithComment:story];
    };

    return _dataSource;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[CommentsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.tableView.dataSource = self.dataSource;
    self.tableView.rowHeight = 65.0f;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.title = self.story.title;
}

@end
