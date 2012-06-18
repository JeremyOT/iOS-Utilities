#import <Foundation/Foundation.h>

//MonitoredInputStream is a lightweight wrapper around an NSInputStream that provides a 
//way to monitor changes in stream position. It is not a subclass of NSInputStream but
//acts like one as it forwards all selectors to a wrapped NSInputStream object. This
//class should only be used to read from NSData objects and local files.

@class MonitoredInputStream;

@protocol MonitoredInputStreamDelegate

-(void)monitoredInputStreamPositionDidChange:(MonitoredInputStream*)monitoredInputStream;

@end

@interface MonitoredInputStream : NSObject {
    NSInputStream *baseStream;
}

@property(nonatomic,readonly) NSInteger position;
@property(nonatomic,readonly) NSInteger length;
@property(nonatomic,assign) id<MonitoredInputStreamDelegate> delegate;

+(id)inputStreamWithData:(NSData *)data;
+(id)inputStreamWithFileAtPath:(NSString *)path;
+(id)inputStreamWithURL:(NSURL *)url;

-(id)initWithData:(NSData *)data;
-(id)initWithFileAtPath:(NSString *)path;
-(id)initWithURL:(NSURL *)url;

@end
