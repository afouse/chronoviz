//
//  DPBluetoothPen.h
//  DataPrism
//
//  Created by Adam Fouse on 6/21/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

@interface DPBluetoothPen : NSObject {
	
	NSMenuItem *penMenuItem;
	
	BOOL penBrowserRunning;
	ProcessSerialNumber penBrowserPSN;
	
	NSMutableSet *loadedPages;
	
	NSWindow *progressWindow;
	NSProgressIndicator *progressIndicator;
	NSButton *cancelButton;
	NSTextField *progressTextField;
	
	NSString *clientDirectory;

}

@property(nonatomic,assign) IBOutlet NSMenuItem* penMenuItem;

+(DPBluetoothPen*)penClient;

-(void)reset;

-(IBAction)startListening:(id)sender;
-(IBAction)stopListening:(id)sender;

-(IBAction)penBrowserStarting:(id)sender;
-(IBAction)penBrowserStarted:(id)sender;
-(IBAction)penBrowserConnected:(id)sender;

-(void)loadPages:(NSArray*)pages;

@end
