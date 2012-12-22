#import "JSONService.h"

@implementation JSONService

+ (JSONService*)service{
	return [[JSONService alloc] init] ;
}

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
           bodyStream:(NSInputStream*)bodyStream
          cachePolicy:(NSURLRequestCachePolicy)cachePolicy
      timeoutInterval:(NSTimeInterval)timeoutInterval
       receiveHandler:(void (^)(id, NSNumber*, NSDictionary*))receiveHandler
         errorHandler:(void (^)(NSError*))errorHandler {
    void (^jsonReceiveHander)(id, NSNumber*, NSDictionary*) = ^(id data, NSNumber* statusCode, NSDictionary *headers) {
        NSError *error = nil;
        id object = nil;
        object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (object) {
            receiveHandler(object, statusCode, headers);
        } else {
            errorHandler(error);
        }
    };
    NSMutableDictionary *newHeaders = [NSMutableDictionary dictionaryWithDictionary:headers];
    [newHeaders setObject:@"application/json" forKey:@"Accept"];
    [super requestWithURL:url
                   method:method
                  headers:newHeaders
               bodyStream:bodyStream
              cachePolicy:cachePolicy
          timeoutInterval:timeoutInterval
           receiveHandler:jsonReceiveHander
             errorHandler:errorHandler];
}

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
           jsonString:(NSString*)body
       receiveHandler:(void (^)(id, NSNumber*, NSDictionary*))receiveHandler
         errorHandler:(void (^)(NSError*))errorHandler {
    NSMutableDictionary *newHeaders = [NSMutableDictionary dictionaryWithDictionary:headers];
    [newHeaders setObject:@"application/json" forKey:@"Content-Type"];
    [self requestWithURL:url
                  method:method
                 headers:newHeaders
                    body:[NSMutableData dataWithData:[body dataUsingEncoding:NSUTF8StringEncoding]]
          receiveHandler:receiveHandler
            errorHandler:errorHandler];
}

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
             jsonData:(id)body
       receiveHandler:(void (^)(id, NSNumber*, NSDictionary*))receiveHandler
         errorHandler:(void (^)(NSError*))errorHandler {
    NSError *error = nil;
    NSData *bodyData = nil;
    bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
    NSMutableDictionary *newHeaders = [NSMutableDictionary dictionaryWithDictionary:headers];
    [newHeaders setObject:@"application/json" forKey:@"Content-Type"];
    if (bodyData) {
        [self requestWithURL:url
                      method:method
                     headers:newHeaders
                        body:bodyData
              receiveHandler:receiveHandler
                errorHandler:errorHandler];
    } else {
        errorHandler(error);
    }
}

@end
