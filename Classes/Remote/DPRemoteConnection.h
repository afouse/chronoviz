//
//  DPRemoteConnection.h
//  ChonoVizTouch
//
//  Created by Adam Fouse on 5/27/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AsyncSocket;

extern NSString *const DPRemoteConnectionStateChangeNotification;
extern NSString *const DPRemoteConnectionTimeUpdate;

typedef enum {
	DPRemoteConnectionNotConnected,
	DPRemoteConnectionConnectedNoHandshake,
	DPRemoteConnectionConnectedNoData,
	DPRemoteConnectionConnected
} DPRemoteConnectionState;


@interface DPRemoteConnection : NSObject {

	int messageTag;
	
	AsyncSocket *socket;
	
	NSString *remoteAddress;
	
	NSUInteger state;
	
	NSMutableArray *viewControllers;
    
    NSString *dropboxDirectory;
	
}

@property DPRemoteConnectionState state;

- (void)connectToAddress:(NSString*)hostname;
- (NSString*)remoteAddress;
- (BOOL)isConnected;
- (void)disconnect;
- (DPRemoteConnectionState)state;

- (void)sendTimeMessage:(NSTimeInterval)time;

- (BOOL)dataLoaded;

@end

@protocol DPRemoteConnectionDelegate

- (void)remoteConnection:(DPRemoteConnection*)theConnection didUpdateState:(DPRemoteConnectionState)theState;

@end
