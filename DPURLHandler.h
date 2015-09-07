//
//  DPURLHandler.h
//  ChronoViz
//
//  Created by Adam Fouse on 3/22/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class AppController;

@interface DPURLHandler : NSObject {

	NSMutableDictionary *handlers;
	
	AppController *app;
}

- (id)initForAppController:(AppController*)controller;

- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent;

- (void)registerHandler:(id)handler forCommand:(NSString*)command;

@end
