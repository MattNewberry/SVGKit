//
//  RootViewController.m
//  SVGPad
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

@implementation MasterViewController

@synthesize sampleNames = _sampleNames;
@synthesize detailViewController = _detailViewController;

- (id)init
{
    if (self) {
        self.sampleNames = [NSMutableArray arrayWithObjects: @"http://upload.wikimedia.org/wikipedia/commons/f/f9/BlankMap-Africa.svg", @"australia_states_blank", @"Reinel_compass_rose", @"Monkey", @"Blank_Map-Africa", @"Note", @"imageWithASinglePointPath", @"Lion", @"Map", @"CurvedDiamond", @"Text", @"Location_European_nation_states", @"uk-only", @"Europe_states_reduced", @"Compass_rose_pale", nil];
    }
	
	/** Apple really sucks. They keep randomly changing which init methods they call, BREAKING ALL EXISTING CODE */
    return nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		[self init];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self init];
	}
	return self;
}

- (void)dealloc {
	[_detailViewController release];
	[_sampleNames release];
	
	[super dealloc];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.clearsSelectionOnViewWillAppear = NO;
	self.contentSizeForViewInPopover = CGSizeMake(320.0f, 600.0f);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	return [_sampleNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (!cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
									   reuseIdentifier:CellIdentifier] autorelease];
	}
	
	cell.textLabel.text = [_sampleNames objectAtIndex:indexPath.row];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( [[_sampleNames objectAtIndex:indexPath.row] isEqualToString:@"Reinel_compass_rose"])
	{
		NSLog(@"*****************\n*   WARNING\n*\n* The sample 'Reinel_compass_rose' is currently unsupported;\n* it is included in this build so that people working on it can test it and see if it works yet\n*\n*\n*****************");
	}
	
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    if (!self.detailViewController) {
	        self.detailViewController = [[[DetailViewController alloc] initWithNibName:@"iPhoneDetailViewController" bundle:nil] autorelease];
	    }
	    [self.navigationController pushViewController:self.detailViewController animated:YES];
		self.detailViewController.detailItem = [_sampleNames objectAtIndex:indexPath.row];
    } else {
        self.detailViewController.detailItem = [_sampleNames objectAtIndex:indexPath.row];
    }
}

@end
