//
//  FileService.h
//
//  Created by Jeremy Olmsted-Thompson on 1/20/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import "DataService.h"

@interface StreamService : DataService {
    long long _downloadedLength;
}

@property(nonatomic,retain) NSOutputStream *outputStream;
@property(nonatomic,copy) void (^progressHandler)(long long downloadedSize, long long expectedSize);

-(id)initWithOutputStream:(NSOutputStream*)stream;
-(id)initWithOutputStream:(NSOutputStream*)stream progressHandler:(void (^)(long long downloadedSize, long long expectedSize))progressHandler;

+(id)serviceWithOutputStream:(NSOutputStream*)stream;
+(id)serviceWithOutputStream:(NSOutputStream*)stream progressHandler:(void (^)(long long downloadedSize, long long expectedSize))progressHandler;

@end
