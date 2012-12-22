#import "DataService.h"

#define DATA_SERVICE_DOMAIN @"DataService"

@interface DataService ()

@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, copy) void (^onReceiveBlock)(id, NSNumber*, NSDictionary*);
@property (nonatomic, copy) void (^onErrorBlock)(NSError*);

// Response properties: generate hidden setters
@property(nonatomic, retain, readwrite) NSDictionary *responseHeaders;
@property(nonatomic, readwrite) long long expectedContentLength;
@property(nonatomic, retain, readwrite) NSString *textEncodingName;
@property(nonatomic, retain, readwrite) NSString *MIMEType;
@property(nonatomic, retain, readwrite) NSString *suggestedFilename;

@end

@implementation DataService

@synthesize requestURL = _requestURL;
@synthesize statusCode = _statusCode;
@synthesize receivedData = _receivedData;
@synthesize urlConnection = _urlConnection;
@synthesize onReceiveBlock = _onReceiveBlock;
@synthesize onErrorBlock = _onErrorBlock;
@synthesize inProgress = _inProgress;
@synthesize responseHeaders = _responseHeaders;
@synthesize expectedContentLength = _expectedContentLength;
@synthesize textEncodingName = _textEncodingName;
@synthesize MIMEType = _MIMEType;
@synthesize suggestedFilename = _suggestedFilename;

#pragma mark - Initialization

+ (DataService*)service{
    return [[DataService alloc] init];
}

#pragma mark - Request

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
           bodyStream:(NSInputStream*)bodyStream
          cachePolicy:(NSURLRequestCachePolicy)cachePolicy
      timeoutInterval:(NSTimeInterval)timeoutInterval
       receiveHandler:(void (^)(id, NSNumber*, NSDictionary*))receiveHandler
         errorHandler:(void (^)(NSError*))errorHandler {
    self.onReceiveBlock = receiveHandler;
    self.onErrorBlock = errorHandler;
    self.requestURL = url;
    self.responseHeaders = nil;
    self.expectedContentLength = 0;
    self.textEncodingName = nil;
    self.MIMEType = nil;
    self.suggestedFilename = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.requestURL cachePolicy:cachePolicy timeoutInterval:timeoutInterval];
    for (NSString *header in headers) {
        [request addValue:[headers objectForKey:header] forHTTPHeaderField:header];
    }
    [request setHTTPShouldUsePipelining:YES];
    [request setHTTPMethod:method];
    [request setHTTPBodyStream:bodyStream];
    [_urlConnection cancel];
    _urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [_urlConnection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_urlConnection start];
    _inProgress = !!_urlConnection;
    if (_urlConnection) {
        self.receivedData = [NSMutableData data];
    } else {
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:@"Failed to create connection" forKey:NSLocalizedDescriptionKey];
        self.onErrorBlock([NSError errorWithDomain:DATA_SERVICE_DOMAIN code:0 userInfo:errorInfo]);
        self.urlConnection = nil;
    }
}

-(void)requestWithURL:(NSURL *)url
               method:(NSString *)method
              headers:(NSDictionary *)headers
                 body:(NSData *)body
       receiveHandler:(void (^)(id, NSNumber *, NSDictionary*))receiveHandler
         errorHandler:(void (^)(NSError *))errorHandler {
    NSMutableDictionary *newHeaders = [NSMutableDictionary dictionaryWithDictionary:headers];
    if (body) {
        [newHeaders setObject:[NSString stringWithFormat:@"%d", [body length]] forKey:@"Content-Length"];
    }
    [self requestWithURL:url
                  method:method
                 headers:newHeaders
              bodyStream:body ? [NSInputStream inputStreamWithData:body] : nil
          receiveHandler:receiveHandler
            errorHandler:errorHandler];
}

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
           bodyStream:(NSInputStream*)bodyStream
       receiveHandler:(void (^)(id, NSNumber*, NSDictionary*))receiveHandler
         errorHandler:(void (^)(NSError*))errorHandler {
    [self requestWithURL:url
                  method:method
                 headers:headers
              bodyStream:bodyStream 
             cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
         timeoutInterval:60.0
          receiveHandler:receiveHandler
            errorHandler:errorHandler];
}

#pragma mark - Receive

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    self.statusCode = [httpResponse statusCode];
    self.responseHeaders = [httpResponse allHeaderFields];
    self.expectedContentLength = [httpResponse expectedContentLength];
    self.textEncodingName = [httpResponse textEncodingName];
    self.MIMEType = [httpResponse MIMEType];
    self.suggestedFilename = [httpResponse suggestedFilename];
    [self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data{
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error{
    _inProgress = NO;
    self.receivedData = nil;
    self.onReceiveBlock = nil;
    self.responseHeaders = nil;
    self.expectedContentLength = 0;
    self.textEncodingName = nil;
    self.MIMEType = nil;
    self.suggestedFilename = nil;
    self.urlConnection = nil;
    if (self.onErrorBlock) {
        // Hold on to the block so that this DataService can be used for new requests in the callback.
        void (^onErrorBlock)(NSError*) = self.onErrorBlock;
        self.onErrorBlock = nil;
        onErrorBlock(error);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection{
    _inProgress = NO;
    // check to see if the status code is an error code and react appropriately
    if (self.statusCode / 100 == RESPONSE_CLIENT_ERROR / 100 || self.statusCode / 100 == RESPONSE_SERVER_ERROR / 100) {
        NSString *errorString = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:DATA_SERVICE_DOMAIN code:self.statusCode userInfo:errorInfo];
        [self connection:connection didFailWithError:error];
        return;
    }
    self.onErrorBlock = nil;
    self.urlConnection = nil;
    // Hold on to required values so that this DataService can be reused from the callback.
    NSData *receivedData = self.receivedData;
    NSDictionary *responseHeaders = self.responseHeaders;
    self.receivedData = nil;
    self.responseHeaders = nil;
    self.expectedContentLength = 0;
    self.textEncodingName = nil;
    self.MIMEType = nil;
    self.suggestedFilename = nil;
    if (self.onReceiveBlock) {
        void (^onReceiveBlock)(id, NSNumber*, NSDictionary*) = self.onReceiveBlock;
        self.onReceiveBlock = nil;
        onReceiveBlock([NSData dataWithData:receivedData], [NSNumber numberWithInteger:self.statusCode], responseHeaders);
    }
}

#pragma mark - Cleanup

- (void)cancel{
    [self.urlConnection cancel];
    self.urlConnection = nil;
    self.requestURL = nil;
    self.receivedData = nil;
    self.onReceiveBlock = nil;
    self.onErrorBlock = nil;
    self.responseHeaders = nil;
    self.expectedContentLength = 0;
    self.textEncodingName = nil;
    self.MIMEType = nil;
    self.suggestedFilename = nil;
    _inProgress = NO;
}

- (void)dealloc{
    self.receivedData = nil;
    self.requestURL = nil;
    self.onReceiveBlock = nil;
    self.onErrorBlock = nil;
    self.urlConnection = nil;
    self.responseHeaders = nil;
    self.expectedContentLength = 0;
    self.textEncodingName = nil;
    self.MIMEType = nil;
    self.suggestedFilename = nil;
}

@end
