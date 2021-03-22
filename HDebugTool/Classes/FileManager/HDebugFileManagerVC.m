//
//  HDebugFileManagerVC.m
//  HDebugTool
//
//  Created by HeXiaoTian on 2021/3/22.
//

#import "HDebugFileManagerVC.h"
#import "HDebugFileSearchOperation.h"

@interface SaicDebugFileBrowserCell : UITableViewCell
@end

@interface HDebugFileManagerVC ()<UISearchResultsUpdating, UISearchControllerDelegate,HDebugFileSearchOperationDelegate>
//文件路径
@property (nonatomic, copy) NSString *path;
//目录索引
@property (nonatomic, copy) NSArray<NSString *> *childPaths;
//搜索索引
@property (nonatomic, strong) NSArray<NSString *> *searchPaths;
//大小
@property (nonatomic, strong) NSNumber *recursiveSize;
@property (nonatomic, strong) NSNumber *searchPathsSize;
//搜索
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic, strong) UIDocumentInteractionController *documentController;

@end

@implementation HDebugFileManagerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
}

- (id)initWithStyle:(UITableViewStyle)style
{
    return [self initWithPath:NSHomeDirectory()];
}

- (id)initWithPath:(NSString *)path
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.path = path;
        self.title = [path lastPathComponent];
        self.operationQueue = [NSOperationQueue new];
        
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        self.searchController.searchResultsUpdater = self;
        self.searchController.delegate = self;
        self.searchController.dimsBackgroundDuringPresentation = NO;
        self.tableView.tableHeaderView = self.searchController.searchBar;
        
        //计算大小
        HDebugFileManagerVC *__weak weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSDictionary<NSString *, id> *attributes = [fileManager attributesOfItemAtPath:path error:NULL];
            uint64_t totalSize = [attributes fileSize];
            
            for (NSString *fileName in [fileManager enumeratorAtPath:path]) {
                attributes = [fileManager attributesOfItemAtPath:[path stringByAppendingPathComponent:fileName] error:NULL];
                totalSize += [attributes fileSize];
                if (!weakSelf) {
                    return;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                HDebugFileManagerVC *__strong strongSelf = weakSelf;
                strongSelf.recursiveSize = @(totalSize);
                [strongSelf.tableView reloadData];
            });
        });
        
        [self reloadChildPaths];
    }
    return self;
}


- (void)alert:(NSString *)title message:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)fileBrowserSearchOperationResult:(NSArray<NSString *> *)searchResult size:(uint64_t)size
{
    self.searchPaths = searchResult;
    self.searchPathsSize = @(size);
    [self.tableView reloadData];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [self reloadDisplayedPaths];
}

- (void)willDismissSearchController:(UISearchController *)searchController
{
    [self.operationQueue cancelAllOperations];
    [self reloadChildPaths];
    [self.tableView reloadData];
}


#pragma mark ============== tableView DataSource ============

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchController.isActive ? [self.searchPaths count] : [self.childPaths count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    BOOL isSearchActive = self.searchController.isActive;
    NSNumber *currentSize = isSearchActive ? self.searchPathsSize : self.recursiveSize;
    NSArray<NSString *> *currentPaths = isSearchActive ? self.searchPaths : self.childPaths;
    
    NSString *sizeString = @"计算中…";
    if (currentSize) {
        sizeString = [NSByteCountFormatter stringFromByteCount:[currentSize longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
    }
    return [NSString stringWithFormat:@"%lu 个文件 (%@)", (unsigned long)[currentPaths count], sizeString];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *fullPath = [self filePathAtIndexPath:indexPath];
    NSDictionary<NSString *, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:NULL];
    BOOL isDirectory = [[attributes fileType] isEqual:NSFileTypeDirectory];
    NSString *subtitle = nil;
    if (isDirectory) {
        NSUInteger count = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:NULL] count];
        subtitle = [NSString stringWithFormat:@"%lu 个文件", (unsigned long)count];
    } else {
        NSString *sizeString = [NSByteCountFormatter stringFromByteCount:[attributes fileSize] countStyle:NSByteCountFormatterCountStyleFile];
        subtitle = [NSString stringWithFormat:@"%@ - %@", sizeString, [attributes fileModificationDate]];
    }
    
    static NSString *textCellIdentifier = @"textCell";
    static NSString *imageCellIdentifier = @"imageCell";
    UITableViewCell *cell = nil;
    
    // Separate image and text only cells because otherwise the separator lines get out-of-whack on image cells reused with text only.
    UIImage *image = [UIImage imageWithContentsOfFile:fullPath];
    NSString *cellIdentifier = image ? imageCellIdentifier : textCellIdentifier;
    
    if (!cell) {
        cell = [[SaicDebugFileBrowserCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    NSString *cellTitle = [fullPath lastPathComponent];
    cell.textLabel.text = cellTitle;
    cell.detailTextLabel.text = subtitle;
    
    if (image) {
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.imageView.image = image;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *fullPath = [self filePathAtIndexPath:indexPath];
    NSString *subpath = fullPath.lastPathComponent;
    
    BOOL isDirectory = NO;
    BOOL stillExists = [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
    
    if (!stillExists) {
        [self alert:@"未找到文件" message:@"当前文件不存在"];
        [self reloadDisplayedPaths];
        return;
    }
    
    UIViewController *drillInViewController = nil;
    if (isDirectory) {
        drillInViewController = [[[self class] alloc] initWithPath:fullPath];
    }
    
    if (drillInViewController) {
        drillInViewController.title = subpath.lastPathComponent;
        [self.navigationController pushViewController:drillInViewController animated:YES];
    } else {
        // 分享文件
        [self openFileController:fullPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIMenuItem *renameMenuItem = [[UIMenuItem alloc] initWithTitle:@"重命名" action:@selector(fileBrowserRename:)];
    UIMenuItem *deleteMenuItem = [[UIMenuItem alloc] initWithTitle:@"删除" action:@selector(fileBrowserDelete:)];
    NSMutableArray *menus = [NSMutableArray arrayWithObjects:renameMenuItem, deleteMenuItem, nil];
    
    NSString *fullPath = [self filePathAtIndexPath:indexPath];
    NSError *error = nil;
    NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:fullPath error:&error];
    if (error == nil && [attributes fileType] != NSFileTypeDirectory) {
        UIMenuItem *shareMenuItem = [[UIMenuItem alloc] initWithTitle:@"分享" action:@selector(fileBrowserShare:)];
        [menus addObject:shareMenuItem];
    }
    [UIMenuController sharedMenuController].menuItems = menus;
    
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return action == @selector(fileBrowserDelete:) || action == @selector(fileBrowserRename:) || action == @selector(fileBrowserShare:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    // Empty, but has to exist for the menu to show
    // The table view only calls this method for actions in the UIResponderStandardEditActions informal protocol.
    // Since our actions are outside of that protocol, we need to manually handle the action forwarding from the cells.
}


- (void)openFileController:(NSString *)fullPath{
    UIDocumentInteractionController *controller = [UIDocumentInteractionController new];
    controller.URL = [[NSURL alloc] initFileURLWithPath:fullPath];
    
    [controller presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
    self.documentController = controller;
}

- (void)fileBrowserRename:(UITableViewCell *)sender{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSString *fullPath = [self filePathAtIndexPath:indexPath];
    
    [self showAlertTitle:@"重命名" defaultString:@"请输入新文件名" confirmBlock:^(NSString *contentString) {
        NSString *newFileName = contentString;
        NSString *newPath = [[fullPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
        [[NSFileManager defaultManager] moveItemAtPath:fullPath toPath:newPath error:NULL];
    }];
}

- (void)fileBrowserDelete:(UITableViewCell *)sender{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSString *fullPath = [self filePathAtIndexPath:indexPath];
    
    [self showAlertTitle:@"删除文件" defaultString:nil confirmBlock:^(NSString *contentString) {
        [[NSFileManager defaultManager] removeItemAtPath:fullPath error:NULL];
    }];
}

- (void)fileBrowserShare:(UITableViewCell *)sender{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSString *fullPath = [self filePathAtIndexPath:indexPath];
    
    if (fullPath != nil) {
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[fullPath] applicationActivities:nil];
        [self presentViewController:activityViewController animated:true completion:nil];
    }
}

- (void)reloadDisplayedPaths{
    if (self.searchController.isActive) {
        [self reloadSearchPaths];
    } else {
        [self reloadChildPaths];
    }
    [self.tableView reloadData];
}

- (void)reloadChildPaths{
    NSMutableArray<NSString *> *childPaths = [NSMutableArray array];
    NSArray<NSString *> *subpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:NULL];
    for (NSString *subpath in subpaths) {
        [childPaths addObject:[self.path stringByAppendingPathComponent:subpath]];
    }
    self.childPaths = childPaths;
}

- (void)reloadSearchPaths{
    self.searchPaths = nil;
    self.searchPathsSize = nil;
    
    [self.operationQueue cancelAllOperations];
    HDebugFileSearchOperation *newOperation = [[HDebugFileSearchOperation alloc] initWithPath:self.path searchString:self.searchController.searchBar.text];
    newOperation.delegate = self;
    [self.operationQueue addOperation:newOperation];
}

- (NSString *)filePathAtIndexPath:(NSIndexPath *)indexPath
{
    return self.searchController.isActive ? self.searchPaths[indexPath.row] : self.childPaths[indexPath.row];
}


-(void)showAlertTitle:(NSString *)title defaultString:(NSString *)defaultString confirmBlock:(void (^)(NSString *))confirmBolck{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:title preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField* uploadServerTextField = alertController.textFields.firstObject;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (confirmBolck) {
                confirmBolck((uploadServerTextField)?uploadServerTextField.text:nil);
            }
        });
    }]];
    if (defaultString) {
        [alertController addTextFieldWithConfigurationHandler:^(UITextField*_Nonnull textField) {
            textField.placeholder = defaultString;
        }];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

@end


@implementation SaicDebugFileBrowserCell

- (void)fileBrowserRename:(UIMenuController *)sender
{
    id target = [self.nextResponder targetForAction:_cmd withSender:sender];
    [[UIApplication sharedApplication] sendAction:_cmd to:target from:self forEvent:nil];
}

- (void)fileBrowserDelete:(UIMenuController *)sender
{
    id target = [self.nextResponder targetForAction:_cmd withSender:sender];
    [[UIApplication sharedApplication] sendAction:_cmd to:target from:self forEvent:nil];
}

- (void)fileBrowserShare:(UIMenuController *)sender
{
    id target = [self.nextResponder targetForAction:_cmd withSender:sender];
    [[UIApplication sharedApplication] sendAction:_cmd to:target from:self forEvent:nil];
}


@end
