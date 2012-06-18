#import "MonitoredInputStream.h"

@implementation MonitoredInputStream

@synthesize position = _position;
@synthesize length = _length;
@synthesize delegate;

#pragma mark - Initialization

+(id)inputStreamWithData:(NSData *)data {
    return [[[self alloc] initWithData:data] autorelease];
}

+(id)inputStreamWithFileAtPath:(NSString *)path {
    return [[[self alloc] initWithFileAtPath:path] autorelease];
}

+(id)inputStreamWithURL:(NSURL *)url{
    return [[[self alloc] initWithURL:url] autorelease];
}

-(id)initWithData:(NSData *)data {
    if ((self = [super init])) {
        baseStream = [[NSInputStream alloc] initWithData:data];
        _position = 0;
        _length = [data length];
    }
    return self;
}

-(id)initWithFileAtPath:(NSString *)path {
    if ((self = [super init])) {
        baseStream = [[NSInputStream alloc] initWithFileAtPath:path];
        _position = 0;
        _length = [[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] objectForKey:NSFileSize] integerValue];
    }
    return self;
}

-(id)initWithURL:(NSURL *)url {
    if ((self = [super init])) {
        baseStream = [[NSInputStream alloc] initWithURL:url];
        _position = 0;
        _length = [[[[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:nil] objectForKey:NSFileSize] integerValue];
    }
    return self;
}

#pragma mark - Data access

-(NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    NSInteger read = [baseStream read:buffer maxLength:len];
    _position += read;
    [self.delegate monitoredInputStreamPositionDidChange:self];
    return read;
}

#pragma mark - Message forwarding

-(BOOL)isKindOfClass:(Class)aClass {
    return [super isKindOfClass:aClass] || [baseStream isKindOfClass:aClass];
}

-(BOOL)respondsToSelector:(SEL)aSelector {
    return [super respondsToSelector:aSelector] || [baseStream respondsToSelector:aSelector];
}

-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        signature = [baseStream methodSignatureForSelector:aSelector];
    }
    return signature;
}

-(id)forwardingTargetForSelector:(SEL)aSelector {
    return baseStream;
}

+(BOOL)instancesRespondToSelector:(SEL)aSelector {
    return [self instancesRespondToSelector:aSelector] || [NSInputStream instancesRespondToSelector:aSelector];
}

-(void)dealloc {
    [baseStream release];
    [super dealloc];
}

@end
