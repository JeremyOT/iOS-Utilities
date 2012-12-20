#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#define NetworkStateChangedNotification @"NetworkStateChangedNotification"

typedef enum {
    NetworkStatusNotAvailable,
    NetworkStatusWifi,
    NetworkStatusWWAN
} NetworkStatus;

@interface NetworkMonitorService : NSObject {
    @private
    BOOL localWiFiRef;
    SCNetworkReachabilityRef reachabilityRef;

}

-(BOOL)startNotifier;
-(void)stopNotifier;
-(void)sendStatusChangedNotification;
-(BOOL)connectionRequired;
-(NetworkStatus)currentNetworkStatus;

+(NetworkMonitorService*)networkMonitorServiceWithHostName:(NSString*)hostName;
+(NetworkMonitorService*)networkMonitorServiceForInternetConnection;
+(NetworkMonitorService*)networkMonitorServiceForLocalWiFi;
+(NetworkMonitorService*)sharedService;

@end
