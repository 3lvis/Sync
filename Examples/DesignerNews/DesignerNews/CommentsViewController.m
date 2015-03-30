#import "CommentsViewController.h"
#import "UIFont+DNStyle.h"

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

    cell.indentationLevel = 1;

    if ([self.arrayWithSubcommentPositions[indexPath.row] boolValue]) {
        cell.indentationWidth = HYPIndentationWidthSubcomment;
    } else {
        cell.indentationWidth = HYPIndentationWidthComment;
    }

    cell.textLabel.text = self.arrayWithComments[indexPath.row];
    cell.textLabel.numberOfLines = 1000;
    cell.textLabel.font = [UIFont commentFont];

    return cell;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.tableView.delegate = self;
    self.tableView.allowsSelection = NO;
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
