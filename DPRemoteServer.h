//
//  DPRemoteServer.h
//  ChronoViz
//
//  Created by Adam Fouse on 5/28/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationView.h"
@class AsyncSocket;

////////////////////
// To enable the remote server menu item, use the following command in the terminal:
// defaults write edu.ucsd.DataPrism EnableChronoVizRemote -bool YES
////////////////////

@interface DPRemoteServer : NSObject <AnnotationView> {

	IBOutlet NSMenuItem *serverMenuItem;
    
	AsyncSocket *listenSocket;
	NSMutableArray *connectedSockets;

	BOOL isRunning;
    
    NSString *dropboxDirectory;
	
	NSWindow *ipWindow;
	NSTextField *ipTextField;
	
	NSTimeInterval lastTimeUpdate;
	NSOperationQueue *updateQueue;
	NSInvocationOperation *updateOperation;
}
@property(nonatomic,assign) NSMenuItem* serverMenuItem;

+(DPRemoteServer*) defaultServer;

- (IBAction)startStop:(id)sender;

- (NSWindow*)ipWindow;

@end
