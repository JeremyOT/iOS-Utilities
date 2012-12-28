#import "JSONService.h"

#define RESPONSE_ENCODING @"application/json"

@implementation JSONService

+ (JSONService*)service{
	return [[JSONService alloc] init];
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
    [newHeaders setObject:RESPONSE_ENCODING forKey:@"Accept"];
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
    [newHeaders setObject:RESPONSE_ENCODING forKey:@"Content-Type"];
    [self requestWithURL:url
                  method:method
                 headers:newHeaders
                    body:(body ? [NSMutableData dataWithData:[body dataUsingEncoding:NSUTF8StringEncoding]] : nil)
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
    if (body) {
        bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
    }
    NSMutableDictionary *newHeaders = [NSMutableDictionary dictionaryWithDictionary:headers];
    [newHeaders setObject:RESPONSE_ENCODING forKey:@"Content-Type"];
    if (bodyData) {
        [self requestWithURL:url
                      method:method
                     headers:newHeaders
                        body:bodyData
              receiveHandler:receiveHandler
                errorHandler:errorHandler];
    } else {
        if (body) {
            //body failed to serialize
            errorHandler(error);
        }else{
            //body was nil, pass through
            [self requestWithURL:url
                          method:method
                         headers:newHeaders
                            body:nil
                  receiveHandler:receiveHandler
                    errorHandler:errorHandler];            
        }
    }
}

@end
