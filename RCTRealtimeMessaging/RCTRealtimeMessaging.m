//
//  RCTRealtimeMessaging.m
//  RCTRealtimeMessaging
//
//  Created by Joao Caixinha on 02/04/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

#import "RCTRealtimeMessaging.h"
#import <RCTConvert.h>

@implementation RCTRealtimeMessaging
@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(connect:(NSDictionary*)connectionSettings id:(NSString*)pId){
    
    NSString *appKey = [RCTConvert NSString:connectionSettings[@"appKey"]];
    NSString *clientConnMeta = [RCTConvert NSString:connectionSettings[@"connectionMetadata"]];
    NSString *url = [RCTConvert NSString:connectionSettings[@"url"]];
    NSString *clusterUrl = [RCTConvert NSString:connectionSettings[@"clusterUrl"]];
    NSString *token = [RCTConvert NSString:connectionSettings[@"token"]];
    
    if (!_queue) {
        _queue = [[NSMutableDictionary alloc] init];
    }
    
    OrtcClient *ortcClient = [_queue objectForKey:pId];
    
    if (!ortcClient) {
        ortcClient = [OrtcClient ortcClientWithConfig:self];
        [_queue setObject:ortcClient forKey:pId];
    }
    
    // Set connection properties
    [ortcClient setConnectionMetadata:clientConnMeta];
    
    if (url) {
        [ortcClient setUrl:url];
    }else if (clusterUrl)
    {
        [ortcClient setClusterUrl:clusterUrl];
    }

    // Connect
    [ortcClient connect:appKey authenticationToken:token];
    
}

RCT_EXPORT_METHOD(sendMessage:(NSString*)message toChannel:(NSString*)channel usingClient:(NSString*)clientID)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    [ortcClient send:channel message:message];
}

/**
 * Occurs when the client connects.
 *
 * @param ortc The ORTC object.
 */
RCT_EXPORT_METHOD(onConnected:(OrtcClient*) ortc)
{
    NSString *clientID = [[_queue allKeysForObject:ortc] objectAtIndex:0];
    [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onConnected", clientID]
                                                    body:@{}];
}

RCT_EXPORT_METHOD(subscribe:(NSString*)channel subscribeOnReconnected:(BOOL)aSubscribeOnReconnected usingClient:(NSString*)clientID)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    [ortcClient subscribe:channel subscribeOnReconnected:aSubscribeOnReconnected onMessage:^(OrtcClient *ortc, NSString *channel, NSString *message)
     {
         
             NSString *clientID = [[_queue allKeysForObject:ortc] objectAtIndex:0];
             [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onMessage", clientID]
                                                             body:@{@"message": message,
                                                                    @"channel": channel
                                                                    }];
     }];
}

RCT_EXPORT_METHOD(subscribeWithNotifications:(NSString*) channel subscribeOnReconnected:(BOOL) aSubscribeOnReconnected usingClient:(NSString*)clientID)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    [ortcClient subscribeWithNotifications:channel subscribeOnReconnected:aSubscribeOnReconnected onMessage:^(OrtcClient *ortc, NSString *channel, NSString *message) {
        
            NSString *clientID = [[_queue allKeysForObject:ortc] objectAtIndex:0];
            [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onMessage", clientID]
                                                            body:@{@"message": message,
                                                                   @"channel": channel,
                                                                   }];
    }];
}


/** Enables presence for the specified channel with first 100 unique metadata if true.
 
 @warning This function will send your private key over the internet. Make sure to use secure connection.
 @param url Server containing the presence service.
 @param isCluster Specifies if url is cluster.
 @param applicationKey Application key with access to presence service.
 @param privateKey The private key provided when the ORTC service is purchased.
 @param channel Channel with presence data active.
 @param metadata Defines if to collect first 100 unique metadata.
 @param callback Callback with error (NSError) and result (NSString) parameters
 */
RCT_EXPORT_METHOD(enablePresence:(NSString*) aUrl isCLuster:(BOOL) aIsCluster applicationKey:(NSString*) aApplicationKey privateKey:(NSString*) aPrivateKey channel:(NSString*) channel metadata:(BOOL) aMetadata usingClient:(NSString*)clientID)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    [ortcClient enablePresence:aUrl isCLuster:aIsCluster applicationKey:aApplicationKey privateKey:aPrivateKey channel:channel metadata:aMetadata callback:^(NSError *error, NSString *result) {
        if (error) {
            [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onEnablePresence", clientID]
                                                            body:@{@"error": error.localizedDescription,
                                                                   }];
        }else{
            [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onEnablePresence", clientID]
                                                            body:@{@"result": result,
                                                                   }];
        }
    }];
}

/** Disables presence for the specified channel.
 
 @warning This function will send your private key over the internet. Make sure to use secure connection.
 @param url Server containing the presence service.
 @param isCluster Specifies if url is cluster.
 @param applicationKey Application key with access to presence service.
 @param privateKey The private key provided when the ORTC service is purchased.
 @param channel Channel with presence data active.
 @param callback Callback with error (NSError) and result (NSString) parameters
 */
RCT_EXPORT_METHOD(disablePresence:(NSString*) aUrl isCLuster:(BOOL) aIsCluster applicationKey:(NSString*) aApplicationKey privateKey:(NSString*) aPrivateKey channel:(NSString*)channel usingClient:(NSString*)clientID)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    [ortcClient disablePresence:aUrl isCLuster:aIsCluster applicationKey:aApplicationKey privateKey:aPrivateKey channel:channel callback:^(NSError *error, NSString *result) {
        if (error) {
            [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onDisablePresence", clientID]
                                                            body:@{@"error": error.localizedDescription,
                                                                   }];
        }else{
            [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onDisablePresence", clientID]
                                                            body:@{@"result": result,
                                                                   }];
        }
    }];
}

/**
 * Gets a NSDictionary indicating the subscriptions in the specified channel and if active the first 100 unique metadata.
 *
 * @param url Server containing the presence service.
 * @param isCluster Specifies if url is cluster.
 * @param applicationKey Application key with access to presence service.
 * @param authenticationToken Authentication token with access to presence service.
 * @param channel Channel with presence data active.
 * @param callback Callback with error (NSError) and result (NSDictionary) parameters
 */
RCT_EXPORT_METHOD(presence:(NSString*) aUrl isCLuster:(BOOL) aIsCluster applicationKey:(NSString*) aApplicationKey authenticationToken:(NSString*) aAuthenticationToken channel:(NSString*) channel usingClient:(NSString*)clientID)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    [ortcClient presence:aUrl isCLuster:aIsCluster applicationKey:aApplicationKey authenticationToken:aAuthenticationToken channel:channel callback:^(NSError *error, NSDictionary *result) {
        
        if (error) {
            [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onPresence", clientID]
                                                            body:@{@"error": error.localizedDescription,
                                                                   }];
        }else{
            [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onPresence", clientID]
                                                            body:@{@"result": result,
                                                                   }];
        }
    }];
}


/**
 * Occurs when the client disconnects.
 *
 * @param ortc The ORTC object.
 */
RCT_EXPORT_METHOD(onDisconnected:(OrtcClient*) ortc)
{   
    NSString *clientID = [[_queue allKeysForObject:ortc] objectAtIndex:0];
    [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onDisconnected", clientID]
                                                    body:@{}];
}
/**
 * Occurs when the client subscribes to a channel.
 *
 * @param ortc The ORTC object.
 * @param channel The channel name.
 */
RCT_EXPORT_METHOD(onSubscribed:(OrtcClient*) ortc channel:(NSString*) channel)
{
    NSString *clientID = [[_queue allKeysForObject:ortc] objectAtIndex:0];
    [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onSubscribed", clientID]
                                                    body:@{@"channel":channel,
                                                           }];
}
/**
 * Occurs when the client unsubscribes from a channel.
 *
 * @param ortc The ORTC object.
 * @param channel The channel name.
 */
RCT_EXPORT_METHOD(onUnsubscribed:(OrtcClient*) ortc channel:(NSString*) channel)
{
    NSString *clientID = [[_queue allKeysForObject:ortc] objectAtIndex:0];
    [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onUnSubscribed", clientID]
                                                    body:@{@"channel":channel,
                                                           }];
}

/**
 * Occurs when there is an exception.
 *
 * @param ortc The ORTC object.
 * @param error The occurred exception.
 */
RCT_EXPORT_METHOD(onException:(OrtcClient*) ortc error:(NSError*) error)
{
    NSString *clientID = [[_queue allKeysForObject:ortc] objectAtIndex:0];
    [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onException", clientID]
                                                    body:@{@"error":error.localizedDescription,
                                                        }];
}

/**
 * Occurs when the client attempts to reconnect.
 *
 * @param ortc The ORTC object.
 */
RCT_EXPORT_METHOD(onReconnecting:(OrtcClient*) ortc)
{
    NSString *clientID = [[_queue allKeysForObject:ortc] objectAtIndex:0];
    [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onReconnecting", clientID]
                                                    body:@{}];
}
/**
 * Occurs when the client reconnects.
 *
 * @param ortc The ORTC object.
 */
RCT_EXPORT_METHOD(onReconnected:(OrtcClient*) ortc)
{
    NSString *clientID = [[_queue allKeysForObject:ortc] objectAtIndex:0];
    [self.bridge.eventDispatcher sendDeviceEventWithName:[NSString stringWithFormat:@"%@-onReconnected", clientID]
                                                    body:@{}];
}


/**
 * Unsubscribes from a channel to stop receiving messages sent to it.
 *
 * @param channel The channel name.
 */
RCT_EXPORT_METHOD(unsubscribe:(NSString*) channel usingClient:(NSString*)clientID)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    [ortcClient unsubscribe:channel];
}
/**
 * Disconnects.
 */
RCT_EXPORT_METHOD(disconnect:(NSString*)clientID)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    [ortcClient disconnect];
}
/**
 * Indicates whether is subscribed to a channel or not.
 *
 * @param channel The channel name.
 *
 * @return TRUE if subscribed to the channel or FALSE if not.
 */
RCT_EXPORT_METHOD(isSubscribed:(NSString*) channel usingClient:(NSString*)clientID callback:(RCTResponseSenderBlock)callback)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    NSNumber* result = [ortcClient isSubscribed:channel];
    callback(@[result]);
}

/** Saves the channels and its permissions for the authentication token in the ORTC server.
 @warning This function will send your private key over the internet. Make sure to use secure connection.
 @param url ORTC server URL.
 @param isCluster Indicates whether the ORTC server is in a cluster.
 @param authenticationToken The authentication token generated by an application server (for instance: a unique session ID).
 @param authenticationTokenIsPrivate Indicates whether the authentication token is private (1) or not (0).
 @param applicationKey The application key provided together with the ORTC service purchasing.
 @param timeToLive The authentication token time to live (TTL), in other words, the allowed activity time (in seconds).
 @param privateKey The private key provided together with the ORTC service purchasing.
 @param permissions The channels and their permissions (w: write, r: read, p: presence, case sensitive).
 @return TRUE if the authentication was successful or FALSE if it was not.
 */
RCT_EXPORT_METHOD(saveAuthentication:(NSString*) url isCLuster:(BOOL) isCluster authenticationToken:(NSString*) authenticationToken authenticationTokenIsPrivate:(BOOL) authenticationTokenIsPrivate applicationKey:(NSString*) applicationKey timeToLive:(int) timeToLive privateKey:(NSString*) privateKey permissions:(NSMutableDictionary*) permissions usingClient:(NSString*)clientID callback:(RCTResponseSenderBlock)callback)
{   
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    BOOL result =  [ortcClient saveAuthentication:url isCLuster:isCluster authenticationToken:authenticationToken authenticationTokenIsPrivate:authenticationTokenIsPrivate applicationKey:applicationKey timeToLive:timeToLive privateKey:privateKey permissions:permissions];
    callback(@[[NSNumber numberWithBool:result]]);
}


/**
 * Get heartbeat interval.
 */
RCT_EXPORT_METHOD(getHeartbeatTime:(NSString*)clientID callback:(RCTResponseSenderBlock)callback)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    int result = ortcClient.getHeartbeatTime;
    callback(@[[NSNumber numberWithInt:result]]);
}
/**
 * Set heartbeat interval.
 */
RCT_EXPORT_METHOD(setHeartbeatTime:(int)newHeartbeatTime usingClient:(NSString*)clientID)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    [ortcClient setHeartbeatTime:newHeartbeatTime];
}
/**
 * Get how many times can the client fail the heartbeat.
 */
RCT_EXPORT_METHOD(getHeartbeatFails:(NSString*)clientID callback:(RCTResponseSenderBlock)callback)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    int result = [ortcClient getHeartbeatFails];
    callback(@[[NSNumber numberWithInt:result]]);
}
/**
 * Set heartbeat fails. Defines how many times can the client fail the heartbeat.
 */
RCT_EXPORT_METHOD(setHeartbeatFails:(int) newHeartbeatFails usingClient:(NSString*)clientID)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    [ortcClient setHeartbeatFails:newHeartbeatFails];
}
/**
 * Indicates whether heartbeat is active or not.
 */
RCT_EXPORT_METHOD(isHeartbeatActive:(NSString*)clientID callback:(RCTResponseSenderBlock)callback)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    BOOL result = [ortcClient isHeartbeatActive];
    callback(@[[NSNumber numberWithInt:result]]);
}
/**
 * Enables the client heartbeat
 */
RCT_EXPORT_METHOD(enableHeartbeat:(NSString*)clientID)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    [ortcClient enableHeartbeat];
}
/**
 * Disables the client heartbeat
 */
RCT_EXPORT_METHOD(disableHeartbeat:(NSString*)clientID)
{
    OrtcClient *ortcClient = [_queue objectForKey:clientID];
    [ortcClient disableHeartbeat];
}


RCT_EXPORT_METHOD(setDEVICE_TOKEN:(NSString *) deviceToken)
{
    [OrtcClient setDEVICE_TOKEN:deviceToken];
}



@end
