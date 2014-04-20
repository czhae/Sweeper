//
//  SWFileStackViewController.m
//  Sweeper
//
//  Created by Jay Chae  on 1/3/14.
//  Copyright (c) 2014 JCLab. All rights reserved.
//

#import "SWFileStackViewController.h"
#import "SWFileStackHandler.h"
#import "SWFileStack.h"
#import "SWUnProcessedFile.h"
#import "SWAppDelegate.h"
#import "SWDirectorySearchCellView.h"
#import "NSURL+Sweeper.h"

@interface SWFileStackViewController ()

@property (nonatomic, strong) NSArray *directorySearchResult;
@property (nonatomic) BOOL initialized;

@end

@implementation SWFileStackViewController

@synthesize fileTableView;
@synthesize fileStackHandler;
@synthesize directoriesInUserHomeDirectory;
@synthesize directorySearchTableView;
@synthesize directorySearchBar;
@synthesize directorySearchResult;
@synthesize directorySearchTableViewContainer;
@synthesize fileTableViewContainer;

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self _initDirectoriesInUserHomeDirectory];
        [NSApp setServicesProvider:self];
        NSUpdateDynamicServices();
        [fileTableView setAllowsTypeSelect:NO];
        self.initialized = NO;
        NSLog(@"initialized with frame");
    }
    return self;
}

- (void)awakeFromNib {
    if (!self.initialized) {
        [self _initDirectoriesInUserHomeDirectory];
        [NSApp setServicesProvider:self];
        NSUpdateDynamicServices();
        self.initialized = YES;
        NSLog(@"awaken from nib");
        
#ifdef DEBUG
        [self fuckServices:nil userData:nil error:nil];
#endif
    }
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
    /*
     Actions for responding to file action events
     */
    NSString *keyCharacter = [theEvent characters];
    if ([keyCharacter isEqualToString:@"m"]) {
        NSLog(@"move file");
        [self showSearchBar];
    } else if ([keyCharacter isEqualToString:@"x"]) {
        NSLog(@"delete file");
        [self deleteFile];
    } else if ([keyCharacter isEqualToString:@"l"]) {
        NSLog(@"defer file");
        [self skipFile];
    } else if ([keyCharacter isEqualToString:@"z"]) {
        [fileStackHandler undoPreviousAction];
        [fileTableView reloadData];
        NSLog(@"undo action");
    }
    
    /*
     Action for responding to selecting destination file path event (usually RETURN key)
     */
    if ([keyCharacter isEqualToString:@"\r"]) {
        if ([directorySearchTableView selectedRow] > -1) {
            NSURL *url = [directorySearchResult objectAtIndex:[directorySearchTableView selectedRow]];
            [self moveFileTo:[url path]];
        }
    }
}


#pragma mark -
#pragma actions

- (void)fuckServices:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
    NSString *fileURL = [[pboard propertyListForType:NSFilenamesPboardType] lastObject];
    NSLog(@"fileURL bitches  %@", fileURL);
    [self initDataStorageWithPath:fileURL];
    [fileTableView reloadData];
}

- (void)moveFileTo:(NSString *)destinationPath {
    [fileStackHandler moveHeadFileToDirectoryAtPath:destinationPath];
    [fileTableView reloadData];
    [self hideSearchBar];
    [self resetSearchBarText];
}

- (void)deleteFile {
    [fileStackHandler removeHeadFile];
    [fileTableView reloadData];
}

- (void)skipFile {
    [fileStackHandler deferHeadFile];
    [fileTableView reloadData];
}

- (void)cancelOperation:(id)sender {
    [self hideSearchBar];
    [self resetSearchBarText];
    [directorySearchBar resignFirstResponder];
}

#pragma mark -
#pragma initializations


- (void)initDataStorageWithPath:(NSString *)path {
#ifdef RELEASE
    fileStackHandler = [SWFileStackHandler stackHandlerForURL:path];
#else
    fileStackHandler = [SWFileStackHandler stackHandlerForURL:@"/Users/jaychae/Desktop"];
#endif
}


/*
 Initialize the app using Services
 */

- (void)_initDirectoriesInUserHomeDirectory {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *userURL = [NSURL URLWithString:@"/Users/jaychae"];
    NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtURL:userURL
                                                   includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLNameKey]
                                                                      options:(NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsPackageDescendants)
                                                                 errorHandler:^BOOL(NSURL *url, NSError *error) {
                                                                     NSLog(@"Error occured while traversing URL : %@", [url absoluteString]);
                                                                     NSLog(@"Error : %@", [error localizedDescription]);
                                                                     return NO;
                                                                 }];
   
    self.directoriesInUserHomeDirectory = [[NSMutableArray alloc] init];
    for (NSURL *url in directoryEnumerator) {
        NSNumber *isDirectory;
        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        if ([isDirectory boolValue]) {
            [self.directoriesInUserHomeDirectory addObject:url];
        }
    }
    NSLog(@"%@", self);
}

- (NSString *)systemUserName {
    NSURL *documentDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSAllDomainsMask] lastObject];
    NSArray *components = [documentDirectory pathComponents];
    NSInteger componentSize = [components count];
    NSString *userName = components[componentSize - 2];
    return userName;
}

#pragma mark -
#pragma UI actions


- (void)showSearchBar {
    [fileTableViewContainer setFrame:NSMakeRect(0, -67, 616, 464)];
    [fileTableViewContainer setAlphaValue:0.0];
    [[self window] makeFirstResponder:directorySearchBar];
}

- (void)hideSearchBar {
    [fileTableViewContainer setFrame:NSMakeRect(0, -3, 616, 464)];
    [fileTableViewContainer setAlphaValue:1.0];
    [directorySearchTableViewContainer setAlphaValue:0.0];
}

- (void)resetSearchBarText {
    [directorySearchBar setStringValue:@""];
}



#pragma mark -
#pragma NSTableViewDelegate & NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if ([tableView isEqual:fileTableView]) {
        return [fileStackHandler.unprocessedFileStack stackCount];
    } else if ([tableView isEqual:directorySearchTableView]) {
        return [directorySearchResult count];
    }
    return 1;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([tableView isEqual:fileTableView]) {
        NSString *identifier = [tableColumn identifier];
        if ([identifier isEqualToString:@"fileColumn"]) {
            NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"SWFileStackViewCell" owner:self];
            SWUnProcessedFile *unprocessedFile = [fileStackHandler.unprocessedFileStack fileAtIndex:row];
            [cellView.textField setStringValue:[unprocessedFile fileName]];
            [cellView.imageView setImage:[unprocessedFile fileIcon]];
            return cellView;
        }
        return nil;
    } else if ([tableView isEqual:directorySearchTableView]) {
        NSString *identifier = [tableColumn identifier];
        if ([identifier isEqualToString:@"searchColumn"]) {
            NSWorkspace *workspace = [[NSWorkspace alloc] init];
            SWDirectorySearchCellView *cellView = [tableView makeViewWithIdentifier:@"SWDirectorySearchCellView" owner:self];
            
            NSURL *directoryURL = directorySearchResult[row];
            NSString *fullPath = [directoryURL path];
            NSString *directoryName = [fullPath lastPathComponent];
            NSImage *iconImage = [workspace iconForFile:fullPath];
            [iconImage setSize:NSMakeSize(64.0, 64.0)];
           
            [cellView.fullPathTextField setStringValue:fullPath];
            [cellView.nameTextField setStringValue:directoryName];
            [cellView.iconImageView setImage:iconImage];
            return cellView;
        }
    }
    return nil;
}

#pragma mark -
#pragma NSTextFieldDelegate methods

- (void)controlTextDidChange:(NSNotification *)obj {
    NSString *searchQueryString = [[[obj.userInfo valueForKey:@"NSFieldEditor"] textStorage] string];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.lastPathComponent BEGINSWITH[c] %@", searchQueryString];
   
    NSLog(@"query string  %@", searchQueryString);
    directorySearchResult = [directoriesInUserHomeDirectory filteredArrayUsingPredicate:predicate];
    if ([directorySearchResult count] > 10) {
        NSRange range;
        range.location = 0;
        range.length = 10;
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"depthOfURLByPathComponents" ascending:YES];
        directorySearchResult = [directorySearchResult sortedArrayUsingDescriptors:@[sortDescriptor]];
        directorySearchResult = [directorySearchResult subarrayWithRange:range];
    }
    
    if ([directorySearchResult count] > 0) {
        [directorySearchTableViewContainer setAlphaValue:1.0];
    } else {
        [directorySearchTableViewContainer setAlphaValue:0.0];
    }
    [directorySearchTableView reloadData];
}

@end
