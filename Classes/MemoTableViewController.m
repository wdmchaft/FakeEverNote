//
//  MemoViewController.m
//  CoreDataMemo
//
//  Created by ohashi tosikazu on 11/06/16.
//  Copyright 2011 nagoya-bunri. All rights reserved.
//

#import "MemoTableViewController.h"

#import "Memo.h"
#import "MemoEditorViewController.h"

@implementation MemoTableViewController

@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize searchDisplayController;

@synthesize savedSearchTerm;
@synthesize savedScopeButtonIndex;
@synthesize searchWasActive;

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	fetchedResultsController = nil;
	managedObjectContext = nil;
	searchDisplayController = nil;
}


- (void)dealloc {
	[fetchedResultsController release];
	[managedObjectContext release];
	[searchDisplayController release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"メモ";
        self.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"メモ" image:[UIImage imageNamed:@"MemoIcon.png"] tag:0] autorelease];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
		
	// ナビゲーションバーに編集ボタンを作成。
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
	// ナビゲーションバーに追加ボタンを作成。
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewMemo:)];
                                
	self.navigationItem.rightBarButtonItem = addButton;
	[addButton release];
	
	// 検索バーを作成
	UISearchBar *searchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 44.0)] autorelease];
    searchBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.tableView.tableHeaderView = searchBar;
	
	// 検索表示ビューコントローラ作成
    self.searchDisplayController = [[[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self] autorelease];
    self.searchDisplayController.delegate = self;
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
	
	if (self.savedSearchTerm)
    {
		// 
        [self.searchDisplayController setActive:self.searchWasActive];
        [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:self.savedScopeButtonIndex];
        [self.searchDisplayController.searchBar setText:savedSearchTerm];
		
        self.savedSearchTerm = nil;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.searchWasActive = [self.searchDisplayController isActive];
    self.savedSearchTerm = [self.searchDisplayController.searchBar text];
    self.savedScopeButtonIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
}

#pragma mark -
#pragma mark Adding a Memo

- (IBAction)addNewMemo:sender
{
	// 追加用ビューを作成。
	MemoEditorViewController *memoEditorViewController = [[MemoEditorViewController alloc] init];
	
	// メモのエンティティを追加。
	memoEditorViewController.memo = (Memo*)[NSEntityDescription insertNewObjectForEntityForName:@"Memo" inManagedObjectContext:self.managedObjectContext];
	
	// 追加メモの編集ビューをへ移動
	[self.navigationController pushViewController:memoEditorViewController animated:YES];
	
	[memoEditorViewController release];
}

#pragma mark -
#pragma mark Table view data source

/**
 セルの内容を編集する。
 */
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	// タイトルを表示
    Memo *memoObject = (Memo*)[self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = memoObject.title;
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy/MM/dd"];
	cell.detailTextLabel.text = [formatter stringFromDate:memoObject.timestamp];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	NSArray *sections = fetchedResultsController.sections;
	id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MemoCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	// 表示テーブルビューに応じたフェッチコントローラを取得し、フェッチの結果をテーブルセルに代入する。
	[self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSManagedObjectContext *context = [fetchedResultsController managedObjectContext];
		[context deleteObject:[fetchedResultsController objectAtIndexPath:indexPath]];
		
		NSError *error;
		if (![context save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
	}   
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    // 選択したセルの情報の詳細表示ビューを作成して、そのビューに移動。
    MemoEditorViewController *detailViewController = [[MemoEditorViewController alloc] init];
	detailViewController.memo = (Memo*)[self.fetchedResultsController objectAtIndexPath:indexPath];
	[self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
    
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (UITableView*)tableViewForController:(NSFetchedResultsController*)controller 
{	
	if (controller == self.fetchedResultsController) {
		return self.tableView;
	}
	else {
		return self.searchDisplayController.searchResultsTableView;
	}
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller 
{
	UITableView *tableView = [self tableViewForController:controller];
	[tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller 
didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
atIndex:(NSUInteger)sectionIndex 
forChangeType:(NSFetchedResultsChangeType)type 
{
	UITableView *tableView = [self tableViewForController:controller];
	[tableView beginUpdates];	
	
    switch(type) 
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller 
didChangeObject:(id)anObject
atIndexPath:(NSIndexPath *)theIndexPath 
forChangeType:(NSFetchedResultsChangeType)type
newIndexPath:(NSIndexPath *)newIndexPath 
{
    UITableView *tableView = [self tableViewForController:controller];
	
	// 変更の種類ごとに処理を分割
    switch(type) 
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:theIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeUpdate:
			[self configureCell:[tableView cellForRowAtIndexPath:theIndexPath] atIndexPath:theIndexPath];
            break;
			
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:theIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
	UITableView *tableView = [self tableViewForController:controller];
    [tableView endUpdates];
}

#pragma mark -
#pragma mark UISearchDisplayControllerDelegate 


- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSString *query = self.searchDisplayController.searchBar.text;
    if (query && query.length) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", searchText];
        [self.fetchedResultsController.fetchRequest setPredicate:predicate];
		[NSFetchedResultsController deleteCacheWithName:@"UserSearch"];
    }
	
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Handle error
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }  
	
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
	
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
	
    return YES;
}

#pragma mark - Fetched results controller   

/**
 フェッチのコントローラーを作成する。
 */
- (NSFetchedResultsController *)fetchedResultsController
{
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // 取得するエンティティをリクエストに指定する。
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Memo" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // 一度に取得するデータ数をリクエストに指定
    [fetchRequest setFetchBatchSize:20];
    
    // 並び替えのキーをリクエストに指定
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // リクエストをコンテキストに投げてフェッチコントローラーを作成
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
    
    // フェッチを実行する
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        // エラー処理
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return fetchedResultsController;
}    
@end

