#import "ViewController.h"
#import "DesignerNewsTableViewCell.h"
#import "DATAStack.h"
#import "DataManager.h"
#import "DATASource.h"
#import "Stories.h"

static NSString * const CellIdentifier = @"Cell";

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) DATAStack *dataStack;
@property (strong, nonatomic) DATASource *dataSource;
@property (strong, nonatomic) NSMutableArray *arrayWithStories;
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

    self.arrayWithStories = [NSMutableArray new];

    [self setAllViewsInPlace];

    self.dataStack = [[DATAStack alloc] initWithModelName:@"DesignerNews"];

    DataManager *dataManager = [DataManager new];
    [dataManager compareAndChangeStoriesWithDataStack:self.dataStack];

    [self.tableView registerClass:[DesignerNewsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.tableView.dataSource = self.dataSource;
    self.tableView.delegate = self;

    [self.view addSubview:self.tableView];
}

#pragma mark - DataSource

- (DATASource *)dataSource
{
    if (_dataSource) return _dataSource;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Stories"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"created_at" ascending:YES]];
    self.arrayWithStories = [NSMutableArray arrayWithArray:[self.dataStack.mainContext executeFetchRequest:request error:nil]];
    [self.tableView reloadData];

    _dataSource = [[DATASource alloc] initWithTableView:self.tableView
                                           fetchRequest:request
                                         cellIdentifier:CellIdentifier
                                            mainContext:self.dataStack.mainContext];

    _dataSource.configureCellBlock = ^(DesignerNewsTableViewCell *cell, Stories *story, NSIndexPath *indexPath) {
        if (cell.labelTitle) {
            [cell.labelTitle removeFromSuperview];
        }
        cell.labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, cell.frame.size.width - 50, cell.frame.size.height - 20)];
        cell.labelTitle.numberOfLines = 10;
        cell.labelTitle.adjustsFontSizeToFitWidth = YES;
        cell.labelTitle.font = [UIFont fontWithName:@"AvenirNext-Regular" size:18];
        cell.labelTitle.text = story.title;
        [cell.labelTitle sizeToFit];
        cell.labelTitle.frame = CGRectMake(25, 15, cell.labelTitle.frame.size.width, cell.labelTitle.frame.size.height);

        [cell addSubview:cell.labelTitle];
    };

    return _dataSource;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.arrayWithStories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DesignerNewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    Stories *story = self.arrayWithStories[indexPath.row];

    cell.labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(25, 0, cell.frame.size.width - 50, cell.frame.size.height - 20)];
    cell.labelTitle.numberOfLines = 10;
    cell.labelTitle.font = [UIFont fontWithName:@"AvenirNext-Regular" size:18];
    cell.labelTitle.text = story.title;
    [cell.labelTitle sizeToFit];
    cell.labelTitle.frame = CGRectMake(25, 15, cell.labelTitle.frame.size.width, cell.labelTitle.frame.size.height);

    [cell addSubview:cell.labelTitle];

    return cell;
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
