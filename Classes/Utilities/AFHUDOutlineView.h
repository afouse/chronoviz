//
//  AFHUDOutlineView.h
//  DataPrism
//
//  Created by Adam Fouse on 4/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BGHUDAppKit/BGHUDAppKit.h>

@interface AFHUDOutlineView : BGHUDOutlineView {

	NSView *nextView;
	
}

@property(assign) NSView* nextView;

@end
