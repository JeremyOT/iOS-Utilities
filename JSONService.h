#import <Foundation/Foundation.h>
#import "DataService.h"

@interface JSONService : DataService

+ (JSONService*)service;

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
           jsonString:(NSString*)body
       receiveHandler:(void (^)(id, NSNumber*))receiveHandler
         errorHandler:(void (^)(NSError*))errorHandler;

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
             jsonData:(id)body
       receiveHandler:(void (^)(id, NSNumber*))receiveHandler
         errorHandler:(void (^)(NSError*))errorHandler;

@end
