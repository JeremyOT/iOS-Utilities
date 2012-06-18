//
//  DebugLog.m
//
//  Created by Jeremy Olmsted-Thompson on 12/22/11.
//  Copyright (c) 2011 JOT. All rights reserved.
//

#import "DebugLog.h"

#define DefaultLogFileName @"DebugLog.txt"

@implementation DebugLog

-(id)initWithLogFilePath:(NSString*)path {
    if ((self = [super init])) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        }
        logFileHandle = [[NSFileHandle fileHandleForUpdatingAtPath:path] retain];
        [logFileHandle seekToEndOfFile];
    }   
    return self;
}

-(void)log:(NSString*)logString {
    NSLog(@"%@", logString);
    [logFileHandle writeData:[[NSString stringWithFormat:@"%@: %@\n", [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterLongStyle], logString] dataUsingEncoding:NSUTF8StringEncoding]];
    [logFileHandle synchronizeFile];
}

+(DebugLog*)defaultLog {
    static DebugLog *defaultLog = nil;
    if (!defaultLog) {
        defaultLog = [[DebugLog alloc] initWithLogFilePath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:DefaultLogFileName]];
    }   
    return defaultLog;
}

@end