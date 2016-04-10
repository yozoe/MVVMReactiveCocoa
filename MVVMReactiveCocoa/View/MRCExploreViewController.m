//
//  MRCExploreViewController.m
//  MVVMReactiveCocoa
//
//  Created by leichunfeng on 16/3/26.
//  Copyright © 2016年 leichunfeng. All rights reserved.
//

#import "MRCExploreViewController.h"
#import "MRCExploreViewModel.h"
#import "MRCExploreTableViewCell.h"
#import "MRCReposSearchResultsViewController.h"
#import "MRCSearchBar.h"
#import "LCFInfiniteScrollView.h"
#import "SDVersion.h"

@interface MRCExploreViewController () <UISearchBarDelegate, UISearchControllerDelegate>

@property (nonatomic, strong) MRCExploreViewModel *viewModel;

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) MRCReposSearchResultsViewController *searchResultsController;

@end

@implementation MRCExploreViewController

@dynamic viewModel;

- (void)viewDidLoad {
    if ([SDVersion deviceVersion] == iPadPro) {
        self.viewModel.itemSize = CGSizeMake(530, 260);
        self.viewModel.itemSpacing = 5;
    } else {
        self.viewModel.itemSize = CGSizeMake(265, 129);
        self.viewModel.itemSpacing = 5;
    }

    [super viewDidLoad];

    [self.tableView registerNib:[UINib nibWithNibName:@"MRCExploreTableViewCell" bundle:nil] forCellReuseIdentifier:@"MRCExploreTableViewCell"];
    self.tableView.showsVerticalScrollIndicator = NO;

    self.searchResultsController = [[MRCReposSearchResultsViewController alloc] initWithViewModel:self.viewModel.searchResultsViewModel];

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchResultsController];
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.delegate = self;

    MRCSearchBar *searchBar = [[MRCSearchBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 44)];
    searchBar.delegate = self;
    self.navigationItem.titleView = searchBar;
    [self.searchController setValue:searchBar forKey:@"searchBar"];

    self.definesPresentationContext = YES;

    LCFInfiniteScrollView *infiniteScrollView = [[LCFInfiniteScrollView alloc] init];
    [self.view addSubview:infiniteScrollView];

    infiniteScrollView.itemSize = self.viewModel.itemSize;
    infiniteScrollView.itemSpacing = self.viewModel.itemSpacing;

    RAC(infiniteScrollView, items) = [RACObserve(self.viewModel, showcases) map:^(NSArray *showcases) {
        return [showcases.rac_sequence map:^(NSDictionary *showcase) {
            LCFInfiniteScrollViewItem *infiniteScrollViewItem = [[LCFInfiniteScrollViewItem alloc] init];

            infiniteScrollViewItem.imageURL = showcase[@"image_url"];
            infiniteScrollViewItem.text = showcase[@"name"];

            return infiniteScrollViewItem;
        }].array;
    }];

    RAC(infiniteScrollView, frame) = [RACObserve(self.tableView, contentOffset) map:^(NSValue *contentOffset) {
        CGFloat deltaY = contentOffset.CGPointValue.y - (-(64 + self.viewModel.itemSize.height));
        if (deltaY <= 0) {
            return [NSValue valueWithCGRect:CGRectMake(0, 64, SCREEN_WIDTH, self.viewModel.itemSize.height)];
        } else {
            return [NSValue valueWithCGRect:CGRectMake(0, 64 - deltaY, SCREEN_WIDTH, self.viewModel.itemSize.height)];
        }
    }];
}

- (UIEdgeInsets)contentInset {
    return UIEdgeInsetsMake(64 + self.viewModel.itemSize.height, 0, 49, 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView dequeueReusableCellWithIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:@"MRCExploreTableViewCell" forIndexPath:indexPath];
}

- (void)configureCell:(MRCExploreTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath withObject:(MRCExploreItemViewModel *)viewModel {
    [cell bindViewModel:viewModel];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 168;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchController.active = YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.viewModel.searchResultsViewModel.dataSource = @[];
    self.viewModel.searchResultsViewModel.query = searchText;
    self.searchController.view.subviews.firstObject.subviews.firstObject.hidden = (searchText.length == 0);
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (searchBar.text.length > 0) {
        [searchBar resignFirstResponder];
        [self.viewModel.searchResultsViewModel.requestRemoteDataCommand execute:nil];
    }
}

@end