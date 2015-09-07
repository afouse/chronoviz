//
//  NSMenuPopUpMenu.m
//  DataPrism
//
//  Created by Adam Fouse on 4/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSMenuPopUpMenu.h"

@implementation NSMenu (PopUpRegularMenuAdditions)
+ (void)popUpMenu:(NSMenu *)menu forView:(NSView *)view atOrigin:(NSPoint)point pullsDown:(BOOL)pullsDown {
    NSMenu *popMenu = [menu copy];
    NSRect frame = [view frame];
	frame.size.width = 100;
	frame.size.height = frame.size.height - point.y;
    frame.origin.x = point.x;
    frame.origin.y = point.y;
	
    if (pullsDown) [popMenu insertItemWithTitle:@"" action:NULL keyEquivalent:@"" atIndex:0];
	
    NSPopUpButtonCell *popUpButtonCell = [[[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:pullsDown] autorelease];
    [popUpButtonCell setMenu:[popMenu autorelease]];
    if (!pullsDown) [popUpButtonCell selectItem:nil];
    [popUpButtonCell performClickWithFrame:frame inView:view];
}
@end