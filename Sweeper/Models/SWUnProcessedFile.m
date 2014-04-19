//
//  SWUnProcessedFile.m
//  Sweeper
//
//  Created by Jay Chae  on 1/2/14.
//  Copyright (c) 2014 JCLab. All rights reserved.
//

#import "SWUnProcessedFile.h"
#import <QuickLook/QuickLook.h>

@implementation SWUnProcessedFile

@synthesize filePath;
@synthesize fileName;
@synthesize fileIcon;

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

+ (instancetype)unprocessedFileAtPath:(NSString *)path {
    NSString *fileName = [[path componentsSeparatedByString:@"/"] lastObject];
    
    SWUnProcessedFile *unprocessedFile = [[SWUnProcessedFile alloc] init];
    [unprocessedFile setFilePath:path];
    [unprocessedFile setFileName:fileName];
    
    CGImageRef iconImageRef = QLThumbnailImageCreate(NULL, (__bridge CFURLRef)[NSURL fileURLWithPath:path], CGSizeMake(64, 64), (__bridge CFDictionaryRef)@{ (NSString*) kQLThumbnailOptionIconModeKey:@(YES)});
    
    if (iconImageRef == NULL) {
        NSWorkspace *workspace = [[NSWorkspace alloc] init];
        [unprocessedFile setFileIcon:[workspace iconForFile:path]];
    } else {
        NSImage *icon = [[NSImage alloc] initWithCGImage:iconImageRef size:NSMakeSize(64, 64)];
        [unprocessedFile setFileIcon:icon];
    }
    return unprocessedFile;
}

@end
