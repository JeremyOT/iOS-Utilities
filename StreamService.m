//
//  FileService.m
//
//  Created by Jeremy Olmsted-Thompson on 1/20/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import "StreamService.h"

@implementation StreamService

@synthesize outputStream = _outputStream;
@synthesize progressHandler = _progressHandler;

+(id)serviceWithOutputStream:(NSOutputStream*)stream {
    return [[[self alloc] initWithOutputStream:stream] autorelease];
}

+(id)serviceWithOutputStream:(NSOutputStream*)stream progressHandler:(void (^)(long long, long long))progressHandler {
    return [[[self alloc] initWithOutputStream:stream progressHandler:progressHandler] autorelease];
}

-(id)initWithOutputStream:(NSOutputStream*)stream {
    return [self initWithOutputStream:stream progressHandler:nil];
}

-(id)initWithOutputStream:(NSOutputStream*)stream progressHandler:(void (^)(long long, long long))progressHandler {
    if ((self = [super init])) {
        self.outputStream = stream;
        self.progressHandler = progressHandler;
    }
    return self;
}

-(void)dealloc {
    [_outputStream release];
    [_progressHandler release];
    [super dealloc];
}

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
           bodyStream:(NSInputStream*)bodyStream
          cachePolicy:(NSURLRequestCachePolicy)cachePolicy
      timeoutInterval:(NSTimeInterval)timeoutInterval
       receiveHandler:(void (^)(id, NSNumber*, NSDictionary*))receiveHandler
         errorHandler:(void (^)(NSError*))errorHandler {
    [_outputStream open];
    _downloadedLength = 0;
    [super requestWithURL:url
                   method:method
                  headers:headers
               bodyStream:bodyStream
              cachePolicy:cachePolicy
          timeoutInterval:timeoutInterval
           receiveHandler:^(id response, NSNumber *status, NSDictionary *headers) {
               [_outputStream close];
               receiveHandler(self.outputStream, status, headers);
           }
             errorHandler:^(NSError *error) {
                 [_outputStream close];
                 errorHandler(error);
             }];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.outputStream write:[data bytes] maxLength:[data length]];
    if (_progressHandler) {
        _downloadedLength += [data length];
        _progressHandler(_downloadedLength, self.expectedContentLength);
    }
}

@end
