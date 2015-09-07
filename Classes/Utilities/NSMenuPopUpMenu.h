//
//  NSMenuPopUpMenu.h
//  DataPrism
//
//  Created by Adam Fouse on 4/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSMenu (PopUpRegularMenuAdditions)
+ (void)popUpMenu:(NSMenu *)menu forView:(NSView *)view atOrigin:(NSPoint)point pullsDown:(BOOL)pullsDown;

@end
