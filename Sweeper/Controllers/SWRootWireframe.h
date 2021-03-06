//
//  SWRootWireframe.h
//  Sweeper
//
//  Created by Jay Chae  on 7/13/14.
//  Copyright (c) 2014 JCLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SWStackViewController;
@class SWHomeDirectoryViewController;
@class SWMainWindowController;

@interface SWRootWireframe : NSObject

@property (nonatomic, readonly) SWStackViewController *fileStackViewController;
@property (nonatomic, readonly) SWHomeDirectoryViewController *homeDirectoryViewController;

- (instancetype)initWithDirectoryPathToDirectory:(NSString *)pathToDirectory;

- (void)beginFlow;

@end
