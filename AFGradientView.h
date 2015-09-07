//
//  AFGradientView.h
//  ChronoViz
//
//  Created by Adam Fouse on 8/18/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const AFGradientUpdatedNotification;

@interface AFGradientView : NSView {

	NSGradient *gradient;
	
	NSMutableArray *colorControls;
	
	CGFloat gradientInset;
	CGFloat colorSize;
	NSRect gradientFrame;
	NSRect colorsFrame;
	
	BOOL continuous;
	BOOL dragging;
	BOOL updateOnDragEnd;
}

@property(retain) NSGradient* gradient;
@property BOOL continuous;

@end
