//
//  DebugLog.h
//
//  Created by Jeremy Olmsted-Thompson on 12/22/11.
//  Copyright (c) 2011 JOT. All rights reserved.
//

#import <Foundation/Foundation.h>

// Define DEBUG_LOG here or configure it as a preprocessor macro in your project settings. Using
// project settings allows the log to automatically be disabled for release builds.

#ifdef DEBUG_LOG
#define DLog(...) \
[[DebugLog defaultLog] log:[NSString stringWithFormat:@"%s (%@: %d): %@", __PRETTY_FUNCTION__, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:__VA_ARGS__]]]
#else
#define DLog(...)
#endif

#ifdef DEBUG_LOG
#define DLogThread(...) \
[[DebugLog defaultLog] log:[NSString stringWithFormat:@"%s (%@: %d) %@: %@", __PRETTY_FUNCTION__, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSThread currentThread], [NSString stringWithFormat:__VA_ARGS__]]]
#else
#define DLogThread(...)
#endif

@interface DebugLog : NSObject {
    NSFileHandle *logFileHandle;
}

-(id)initWithLogFilePath:(NSString*)path;
-(void)log:(NSString*)logString;

+(DebugLog*)defaultLog;

@end