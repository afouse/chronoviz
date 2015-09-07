//
//  MovieControllerView.m
//  Annotation
//
//  Created by Adam Fouse on 10/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MovieControllerView.h"


@implementation MovieControllerView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		NSLog(@"Initializing");
    }
    return self;
}

/*
- (void)drawRect:(NSRect)rect {
    NSRect bounds = [self bounds];
	[[NSColor darkGrayColor] set];
	[NSBezierPath fillRect:bounds];
}
*/
 
- (BOOL)acceptsFirstResponder {
    return NO;
}

- (BOOL)isOpaque
{
	return NO;
}

- (void)mouseDown:(NSEvent *)event
{
	//[mAppController nextAction];
}

- (void)rightMouseDown:(NSEvent *)event
{
	//[mAppController addSegment];
}

- (void)keyDown:(NSEvent *)event
{
	// Disable this for now...
	[super keyDown:event];
	return;
	
	
	NSString *theKey = [event charactersIgnoringModifiers];
	NSLog(@"KeyDown %@",theKey);
	if(([theKey length] == 0) || [event isARepeat]) {
		return;
	}
	
	if([theKey characterAtIndex:0] == 'p') {
		[mAppController togglePlay:self];
		return;
	}
	
	unsigned short code = [event keyCode];
	//NSLog(@"code: %hu",code);
	if(code == 53) {
		[mAppController exitFullScreen:self];
	}
	
	int value = [theKey intValue];
	if([event modifierFlags] & NSAlternateKeyMask) {
		value += 10;
	}
	
	
	if((value < 1) || (value > 15)) {
		[super keyDown:event];
		return;
	}
	
	/*
	if(!speeds) {
		float temp[15] = {-6,-5,-4,-3,-2,-1,-0.5,0,0.5,1,2,3,4,5,6};
		speeds = temp;
	}
	*/
	 
	
	// NSNumber *rate = [[mAppController speeds] objectAtIndex:(value - 1)];
	
	/*
	if([event modifierFlags] & NSAlternateKeyMask) {
		if(value < 5) {
			rate = value - 8.0;
		} else {
			rate = value - 2.0;
		}
	} else {
		rate = ((value - 5.0)/2.0);
	}
	*/
	
	// [mAppController setRate:[rate floatValue] fromSender:self];
	//NSLog(@"rate %f",rate);

}

- (void)keyUp:(NSEvent *)event
{
	
}

@end
