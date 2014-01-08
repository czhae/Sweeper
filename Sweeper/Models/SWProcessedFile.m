//
//  SWProcessedFile.m
//  Sweeper
//
//  Created by Jay Chae  on 1/3/14.
//  Copyright (c) 2014 JCLab. All rights reserved.
//

#import "SWProcessedFile.h"
#import "SWUnProcessedFile.h"

@implementation SWProcessedFile

@synthesize processedAction;
@synthesize pathProcessedFrom;
@synthesize currentPath;

- (id)init {
    self = [super init];
    if (self) { }
    return self;
}

+ (instancetype)processedFileFromUnprocessedFile:(SWUnProcessedFile *)anUnprocessedFile
                                          Action:(NSString *)action {
    SWProcessedFile *processedFile = [[SWProcessedFile alloc] init];
    [processedFile setProcessedAction:action];
    [processedFile setPathProcessedFrom:[anUnprocessedFile filePath]];
    return processedFile;
}
//@property (nonatomic, strong) NSString *processedAction;
//@property (nonatomic, strong) NSString *pathProcessedFrom;
//@property (nonatomic, strong) NSString *currentPath;

@end