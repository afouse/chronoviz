//
//  DPConsoleWindowController.m
//  DataPrism
//
//  Created by Adam Fouse on 6/23/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "DPConsoleWindowController.h"
#import "DPConsole.h"

@implementation DPConsoleWindowController


- (id)init
{
	if(![super initWithWindowNibName:@"DPConsoleWindow"])
		return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateText:)
												 name:DPConsoleChangedNotification
											   object:[DPConsole defaultConsole]];
	
	return self;
}

- (void)updateText:(id)sender
{
	[textView setString:[[DPConsole defaultConsole] consoleText]];
	
	NSRange range;
    range = NSMakeRange ([[textView string] length], 0);
	
    [textView scrollRangeToVisible: range];
}

- (void)windowDidLoad
{
	[self updateText:self];
}

@end
