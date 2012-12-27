#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import "NetworkMonitorService.h"

@implementation NetworkMonitorService

static void NetworkMonitorServiceCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
    NSCAssert([(NSObject*)info isKindOfClass:[NetworkMonitorService class]], @"info was wrong class in ReachabilityCallback");
    
    //We're on the main RunLoop, so an NSAutoreleasePool is not necessary, but is added defensively
    // in case someone consumes NetworkMonitorService in a different thread.
    NSAutoreleasePool* myPool = [[NSAutoreleasePool alloc] init];
    
    // Notify the client that the network reachability changed.
    [(NetworkMonitorService*)info sendStatusChangedNotification];
    
    [myPool release];
}

-(void)sendStatusChangedNotification {
    // Post a notification to notify the client that the network reachability changed.
    [[NSNotificationCenter defaultCenter] postNotificationName:NetworkStateChangedNotification object:self];
}

-(BOOL)startNotifier{
    SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
    if(SCNetworkReachabilitySetCallback(reachabilityRef, NetworkMonitorServiceCallback, &context) && 
       SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
            return YES;
    }
    return NO;
}

-(void)stopNotifier{
    if(reachabilityRef != NULL) {
        SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}

-(void)dealloc {
    [self stopNotifier];
    if(reachabilityRef!= NULL) {
        CFRelease(reachabilityRef);
    }
    [super dealloc];
}

#pragma mark - Network Flag Handling

-(NetworkStatus)localWiFiStatusForFlags:(SCNetworkReachabilityFlags)flags {
    BOOL retVal = NetworkStatusNotAvailable;
    if((flags & kSCNetworkReachabilityFlagsReachable) && (flags & kSCNetworkReachabilityFlagsIsDirect)) {
        retVal = NetworkStatusWifi;  
    }
    return retVal;
}

-(NetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags {
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        // if target host is not reachable
        return NetworkStatusNotAvailable;
    }
    
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        // WWAN connections are OK if the calling application
        // is using the CFNetwork APIs.
        return NetworkStatusWWAN;
    }
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        // if target host is reachable and no connection is required
        // then we'll assume that you're on Wi-Fi
        return NetworkStatusWifi;
    }
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
        // ... and the connection is on-demand (or on-traffic) if the
        //     calling application is using the CFSocketStream or higher APIs
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            // ... and no [user] intervention is needed
            return NetworkStatusWifi;
        }
    }
    return NetworkStatusNotAvailable;
}

#pragma mark - Current Status

-(BOOL)connectionRequired {
    NSAssert(reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef, use static initializers.");
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
    }
    return NO;
}

-(NetworkStatus)currentNetworkStatus {
    NSAssert(reachabilityRef != NULL, @"currentNetworkStatus called with NULL reachabilityRef, use static initializers.");
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        return localWiFiRef ? [self localWiFiStatusForFlags:flags] : [self networkStatusForFlags:flags];
    }
    return NetworkStatusNotAvailable;
}

#pragma mark - Static Initializers

+(NetworkMonitorService*)networkMonitorServiceWithHostName:(NSString*)hostName {
    NetworkMonitorService* retVal = NULL;
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
    if(reachability!= NULL)
    {
        retVal= [[[self alloc] init] autorelease];
        if(retVal!= NULL)
        {
            retVal->reachabilityRef = reachability;
            retVal->localWiFiRef = NO;
        }
    }
    return retVal;
}

+(NetworkMonitorService*)networkMonitorServiceWithAddress:(const struct sockaddr_in*)hostAddress {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)hostAddress);
    NetworkMonitorService* retVal = NULL;
    if(reachability!= NULL)
    {
        retVal= [[[self alloc] init] autorelease];
        if(retVal!= NULL)
        {
            retVal->reachabilityRef = reachability;
            retVal->localWiFiRef = NO;
        }
    }
    return retVal;
}

+(NetworkMonitorService*)networkMonitorServiceForInternetConnection {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    return [self networkMonitorServiceWithAddress: &zeroAddress];
}

+(NetworkMonitorService*)networkMonitorServiceForLocalWiFi {
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len = sizeof(localWifiAddress);
    localWifiAddress.sin_family = AF_INET;
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
    localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
    NetworkMonitorService* retVal = [self networkMonitorServiceWithAddress: &localWifiAddress];
    if(retVal != NULL)
    {
        retVal->localWiFiRef = YES;
    }
    return retVal;
}

+(NetworkMonitorService*)sharedService {
    static NetworkMonitorService *sharedService = nil;
    if (!sharedService) {
        sharedService = [[self networkMonitorServiceForInternetConnection] retain];
    }
    return sharedService;
}

@end
