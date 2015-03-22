#import "ViewController.h"
#import "DesignerNewsTableViewCell.h"
#import "DATAStack.h"
#import "DataManager.h"
#import "DATASource.h"
#import "Stories.h"

static NSString * const CellIdentifier = @"Cell";

@interface ViewController ()

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) DATAStack *dataStack;
@property (strong, nonatomic) DATASource *dataSource;
@property CGFloat deviceWidth;
@property CGFloat deviceHeight;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self preferredStatusBarStyle];

    self.deviceWidth = [UIScreen mainScreen].bounds.size.width;
    self.deviceHeight = [UIScreen mainScreen].bounds.size.height;

    [self setAllViewsInPlace];

    self.dataStack = [[DATAStack alloc] initWithModelName:@"DesignerNews"];

    DataManager *dataManager = [DataManager new];
    [dataManager fetchStoriesUsingDataStack:self.dataStack];

    [self.tableView registerClass:[DesignerNewsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.tableView.dataSource = self.dataSource;

    [self.view addSubview:self.tableView];
}

#pragma mark - DataSource

- (DATASource *)dataSource
{
    if (_dataSource) return _dataSource;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Stories"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:NO]];

    _dataSource = [[DATASource alloc] initWithTableView:self.tableView
                                           fetchRequest:request
                                         cellIdentifier:CellIdentifier
                                            mainContext:self.dataStack.mainContext];

    _dataSource.configureCellBlock = ^(DesignerNewsTableViewCell *cell, Stories *story, NSIndexPath *indexPath) {
        if (cell.labelTitle) {
            [cell.labelTitle removeFromSuperview];
            [cell.labelComments removeFromSuperview];
            [cell.labelUpdated removeFromSuperview];
        }

        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"dd-MMM-yyyy";

        cell.labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, cell.frame.size.width - 50, cell.frame.size.height - cell.frame.size.height/2.5)];
        cell.labelTitle.numberOfLines = 10;
        cell.labelTitle.adjustsFontSizeToFitWidth = YES;
        cell.labelTitle.font = [UIFont fontWithName:@"Avenir-Medium" size:18];
        cell.labelTitle.text = story.title;

        cell.labelComments = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, cell.frame.size.width - 50, cell.frame.size.height - 100)];
        cell.labelComments.font = [UIFont fontWithName:@"Avenir-Medium" size:14];
        cell.labelComments.text = [NSString stringWithFormat:@"%d comments", story.commentCount.intValue];
        [cell.labelComments sizeToFit];
        cell.labelComments.frame = CGRectMake(cell.frame.size.width - cell.labelComments.frame.size.width - 20, cell.frame.size.height - cell.labelComments.frame.size.height - 7.5, cell.labelComments.frame.size.width, cell.labelComments.frame.size.height);

        cell.labelUpdated = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, cell.frame.size.width - 50, cell.frame.size.height - 50)];
        cell.labelUpdated.numberOfLines = 10;
        cell.labelUpdated.adjustsFontSizeToFitWidth = YES;
        cell.labelUpdated.font = [UIFont fontWithName:@"Avenir-Medium" size:14];
        cell.labelUpdated.text = [dateFormatter stringFromDate:story.createdDate];
        [cell.labelUpdated sizeToFit];
        cell.labelUpdated.frame = CGRectMake(25, cell.frame.size.height - cell.labelUpdated.frame.size.height - 10, cell.labelUpdated.frame.size.width, cell.labelUpdated.frame.size.height);
        
        [cell addSubview:cell.labelTitle];
        [cell addSubview:cell.labelComments];
        [cell addSubview:cell.labelUpdated];
    };

    return _dataSource;
}

#pragma mark - Helper methods

- (void)setAllViewsInPlace
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.deviceWidth, 90)];
    headerView.backgroundColor = [UIColor colorWithRed:0.2 green:0.46 blue:0.84 alpha:1];
    [self.view addSubview:headerView];

    UILabel *labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, self.deviceWidth, headerView.frame.size.height - 15)];
    labelTitle.text = @"Designer News";
    labelTitle.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:34];
    labelTitle.textColor = [UIColor whiteColor];
    labelTitle.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:labelTitle];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 90, self.deviceWidth, self.deviceHeight - 90) style:UITableViewStylePlain];
    self.tableView.rowHeight = 100;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - UIStatusBar methods

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
