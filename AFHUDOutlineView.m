//
//  AFHUDOutlineView.m
//  DataPrism
//
//  Created by Adam Fouse on 4/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AFHUDOutlineView.h"


@implementation AFHUDOutlineView

@synthesize nextView;

- (void)keyDown:(NSEvent *)theEvent
{
	
	unsigned short theKey = [theEvent keyCode];
	//NSLog(@"KeyDown %i",theKey);
	if(theKey == 48)
	{
		[[self window] makeFirstResponder:nextView];
	}
	else if(theKey == 53)
	{
		[[[self window] parentWindow] removeChildWindow:[self window]];
		[[self window] close];
	}
	else
	{
		[super keyDown:theEvent];	
	}
}

@end
