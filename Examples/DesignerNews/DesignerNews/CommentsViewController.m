#import "CommentsViewController.h"
#import "UIFont+DNStyle.h"

static const CGFloat HYPDistanceFromSides = 15.0;
static const int HYPIndentationWidthSubcomment = 20.0;
static const int HYPIndentationWidthComment = 0.0;

static NSString * const CellIdentifier = @"Cell";

@interface CommentsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSMutableArray *arrayWithComments;
@property (nonatomic) NSMutableArray *arrayWithSubcommentPositions;

@end

@implementation CommentsViewController

#pragma mark - UITableViewMethods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.arrayWithComments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    cell.textLabel.text = self.arrayWithComments[indexPath.row];
    cell.textLabel.numberOfLines = 1000;
    cell.textLabel.font = [UIFont commentFont];
    cell.indentationLevel = 1;

    if ([self.arrayWithSubcommentPositions[indexPath.row] boolValue]) {
        cell.indentationWidth = HYPIndentationWidthSubcomment;
    } else {
        cell.indentationWidth = HYPIndentationWidthComment;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UILabel *label = [UILabel new];

    if ([self.arrayWithSubcommentPositions[indexPath.row] boolValue]) {
        label.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width - HYPIndentationWidthSubcomment, 0);
    } else {
        label.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width - HYPIndentationWidthComment, 0);
    }

    label.numberOfLines = 1000;
    label.font = [UIFont commentFont];
    label.text = self.arrayWithComments[indexPath.row];
    [label sizeToFit];

    return (label.frame.size.height + HYPDistanceFromSides*2);
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.tableView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.title = self.story.title;
    
    self.arrayWithComments = [NSMutableArray new];
    self.arrayWithSubcommentPositions = [NSMutableArray new];

    for (NSDictionary *dictionary in [NSKeyedUnarchiver unarchiveObjectWithData:self.story.comments]) {
        [self.arrayWithComments addObject:dictionary[@"body"]];

        [self.arrayWithSubcommentPositions addObject:@0];

        for (NSDictionary *subDictionary in dictionary[@"comments"]) {
            [self.arrayWithComments addObject:subDictionary[@"body"]];
            [self.arrayWithSubcommentPositions addObject:@1];
        }
    }

    [self.tableView reloadData];
}

@end
