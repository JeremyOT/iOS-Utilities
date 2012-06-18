#import <Foundation/Foundation.h>

#define RESPONSE_OK 200
#define RESPONSE_CLIENT_ERROR 400
#define RESPONSE_SERVER_ERROR 500

@interface DataService : NSObject <NSURLConnectionDelegate>

@property(nonatomic,retain) NSURL *requestURL;
@property(nonatomic) NSInteger statusCode;
@property(nonatomic,readonly,getter = isInProgress) BOOL inProgress;

// Response properties
@property(nonatomic, retain, readonly) NSDictionary *responseHeaders;
@property(nonatomic, readonly) long long expectedContentLength;
@property(nonatomic, retain, readonly) NSString *textEncodingName;
@property(nonatomic, retain, readonly) NSString *MIMEType;
@property(nonatomic, retain, readonly) NSString *suggestedFilename;

+ (DataService*)service;

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
           bodyStream:(NSInputStream*)bodyStream
          cachePolicy:(NSURLRequestCachePolicy)cachePolicy
      timeoutInterval:(NSTimeInterval)timeoutInterval
       receiveHandler:(void (^)(id, NSNumber*, NSDictionary*))receiveHandler
         errorHandler:(void (^)(NSError*))errorHandler;

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
           bodyStream:(NSInputStream*)bodyStream
       receiveHandler:(void (^)(id, NSNumber*, NSDictionary*))receiveHandler
         errorHandler:(void (^)(NSError*))errorHandler;

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
                 body:(NSData*)body
       receiveHandler:(void (^)(id, NSNumber*, NSDictionary*))receiveHandler
         errorHandler:(void (^)(NSError*))errorHandler;

- (void)cancel;

@end
