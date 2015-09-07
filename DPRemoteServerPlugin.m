//
//  DPRemoteServerPlugin.m
//  ChronoViz
//
//  Created by Adam Fouse on 12/13/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPRemoteServerPlugin.h"
#import "DPRemoteServer.h"
#import "DPAppProxy.h"
#import "DPRemoteConnection.h"

@interface DPRemoteServerPlugin (Internal)

- (NSString*)requestIP;
- (void) updateTime:(NSNotification*)notification;

@end

@implementation DPRemoteServerPlugin

- (id) initWithAppProxy:(DPAppProxy *)appProxy
{
	self = [super init];
	if (self != nil) {
        app = appProxy;
        
        DPRemoteServer *server = [DPRemoteServer defaultServer];
        client = nil;
        
        // Set up menu item
		NSMenuItem *serverMenuItem = [[NSMenuItem alloc] initWithTitle:@"Start Remote Client Connection"
																   action:@selector(startStop:)
															keyEquivalent:@""];
        server.serverMenuItem = serverMenuItem;
		[serverMenuItem setTarget:server];
		
		[appProxy addMenuItem:serverMenuItem toMenuNamed:@"File"];
		[serverMenuItem release];
        
        clientMenuItem = [[NSMenuItem alloc] initWithTitle:@"Connect to Remote Server…"
                                                                action:@selector(startStopClient:)
                                                         keyEquivalent:@""];
		[clientMenuItem setTarget:self];
        [appProxy addMenuItem:clientMenuItem toMenuNamed:@"File"];
        
	}
	return self;
}

- (void)dealloc
{
    [clientMenuItem release];
    [client release];
    [super dealloc];
}

- (void) reset
{
    
}

- (IBAction)startStopClient:(id)sender
{
    if(!client)
    {
        NSString *ipAddress = [self requestIP];
        NSLog(@"Input IP Address: %@",ipAddress);
        if(ipAddress)
        {
            client = [[DPRemoteConnection alloc] init];
            [client connectToAddress:ipAddress];
            [clientMenuItem setTitle:@"Disconnect from Remote Server"];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(updateTime:)
                                                         name:DPRemoteConnectionTimeUpdate
                                                       object:nil];
            
        }
    }
    else 
    {
        [client disconnect];
        [client release];
        client = nil;
        [clientMenuItem setTitle:@"Connect to Remote Server…"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void) updateTime:(NSNotification*)notification
{
	NSNumber *time = [[notification userInfo] objectForKey:@"time"];
    [app setCurrentTime:QTMakeTimeWithTimeInterval([time floatValue]) fromSender:self];
}

- (NSString*)requestIP
{
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Please enter the IP address of the server."];
    [alert addButtonWithTitle:@"Connect"];
    [alert addButtonWithTitle:@"Cancel"];
    
    NSTextField *nameInputField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 22)];
    [nameInputField setStringValue:@"0.0.0.0"];
    [alert setAccessoryView:nameInputField];
    
    //[[alert window] makeFirstResponder:nameInputField];
    
    NSInteger response = [alert runModal];
    
    if(response == NSAlertFirstButtonReturn)
    {
        return [nameInputField stringValue];
    }
    else 
    {
        return nil;
    }
    
}

@end
