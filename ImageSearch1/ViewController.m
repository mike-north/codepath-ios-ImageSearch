//
//  ViewController.m
//  ImageSearch1
//
//  Created by Mike North on 2/2/14.
//  Copyright (c) 2014 Mike North. All rights reserved.
//

#import "ViewController.h"
//#import "UIImageView+AFNetworking.h"
#import "AFNetworking.h"
#import "ImageCell.h"

@interface ViewController ()
@property (nonatomic, strong) NSMutableArray *imageResults;
@property (weak, nonatomic) IBOutlet UICollectionView *imagesCollectionView;
@property (atomic) int currentPage;
@property (weak) NSString* currentSearchTerm;

-(void)loadSomeImages;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.imageResults = [NSMutableArray array];
    self.currentPage = 0;
    self.currentSearchTerm = nil;
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.imageResults count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath:indexPath];

    // Load the image asynchronously
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        // Load the thumbnail URL -- it's way faster!
        NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [self.imageResults[indexPath.row] valueForKeyPath:@"tbUrl"]]];
        if ( data == nil )
            return;
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.imageView.image = [UIImage imageWithData: data];
        });
    });    
    return cell;
}


-(void)loadSomeImages
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://ajax.googleapis.com/ajax/services/search/images?v=1.0&start=%d&rsz=8&q=%@", (self.currentPage * 8), [self.currentSearchTerm stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSLog(@"Sending request");
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        id results = [JSON valueForKeyPath:@"responseData.results"];
        if ([results isKindOfClass:[NSArray class]]) {

            [self.imageResults addObjectsFromArray:results];
            NSLog(@"Results: %@", results);
            [self.imagesCollectionView reloadData];
            if (self.currentPage == 1) {
                self.currentPage = 2;
                [self loadSomeImages];
            }
        }
    } failure:nil];
    
    [operation start];
}

#pragma mark - UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
    self.currentSearchTerm = searchBar.text;
    self.currentPage = 1;
    [self.imageResults removeAllObjects];
    [self loadSomeImages];
    [searchBar endEditing:YES];

}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    return YES;
}


@end
