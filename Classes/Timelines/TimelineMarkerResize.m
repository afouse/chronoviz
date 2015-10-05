//
//  ResizeLayer.m
//  Annotation
//
//  Created by Adam Fouse on 7/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TimelineMarkerResize.h"
#import "TimelineMarker.h"
#import "TimelineView.h"

@implementation TimelineMarkerResize

@synthesize radius;
@synthesize arrowMargin;
@synthesize highlighted;
@synthesize trackingArea;
@synthesize marker;

- (id)initWithLayer:(CALayer*)theLayer;
{
	self = [super init];
	if (self != nil) {
		resizelayer = [theLayer retain];
		trackingArea = nil;
//		layer.contents = nil;
		resizelayer.delegate = self;
		[self setRadius:8.0f];
		[self setArrowMargin:1.5f];
		resizelayer.bounds = CGRectMake(0, 0, radius*2, radius*2);
		
		theCircle = CGPathCreateMutable();
		theArrows = CGPathCreateMutable();
		
		CGPathAddEllipseInRect(theCircle, NULL, CGRectMake(0.5, 0.5, (radius*2) - 1, (radius*2) - 1));
		
		CGPathMoveToPoint(theArrows,NULL,radius - arrowMargin,arrowMargin);
		CGPathAddLineToPoint(theArrows, NULL, radius - arrowMargin, radius*2 - arrowMargin*2);
		CGPathAddLineToPoint(theArrows, NULL, arrowMargin, radius);
		CGPathCloseSubpath(theArrows);
		
		CGPathMoveToPoint(theArrows,NULL,radius + arrowMargin,arrowMargin);
		CGPathAddLineToPoint(theArrows, NULL, radius + arrowMargin, radius*2 - arrowMargin*2);
		CGPathAddLineToPoint(theArrows, NULL, radius*2 - arrowMargin, radius);
		CGPathCloseSubpath(theArrows);
	}
	return self;
}

- (void) dealloc
{
	//release the layer
	[resizelayer release];

	// release the paths
    CFRelease(theCircle);
	CFRelease(theArrows);

	[trackingArea release];
	
	[super dealloc];
}

- (CALayer*)layer
{
	return resizelayer;
}

/*
- (void)displayLayer:(CALayer *)theLayer
{
	NSLog(@"displayLayer");
}
 */

- (void)mouseEntered:(NSEvent *)theEvent
{
	[self setHighlighted:YES];
	[marker setHighlighted:YES];
	[resizelayer setNeedsDisplay];
	[[NSCursor resizeLeftRightCursor] push];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	[marker setHighlighted:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[NSCursor pop];
	if(![[marker timeline] resizingAnnotation])
	{
		[self setHighlighted:NO];	
	}
	if([[marker timeline] highlightedMarker] != marker)
		[marker setHighlighted:NO];
	[resizelayer setNeedsDisplay];
}

- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext
{
		
    CGContextBeginPath(theContext);
    CGContextAddPath(theContext, theCircle );
	CGContextSetRGBFillColor(theContext, 0.5f, 0.5f, 0.5f, 1.0f);
	CGContextFillPath(theContext);
	
	CGContextBeginPath(theContext);
	CGContextAddPath(theContext, theCircle );
	if(/* DISABLES CODE */ (NO))
	{
		CGContextSetRGBStrokeColor(theContext, 0.9f, 0.9f, 0.9f, 1.0f);
		CGContextSetLineWidth(theContext, 2.0f);
	}
	else
	{
		CGContextSetRGBStrokeColor(theContext, 0.2f, 0.2f, 0.2f, 1.0f);
		CGContextSetLineWidth(theContext, 1.0f);
	}
	CGContextStrokePath(theContext);
	
	CGContextBeginPath(theContext);
	CGContextAddPath(theContext, theArrows);
	if(highlighted)
	{
		CGContextSetRGBFillColor(theContext, 0.9f, 0.9f, 0.9f, 1.0f);
	}
	else
	{
		CGContextSetRGBFillColor(theContext, 0.2f, 0.2f, 0.2f, 1.0f);
	}

    CGContextFillPath(theContext);
	
//	CGContextBeginPath(theContext);
//	CGContextAddPath(theContext, theArrows);
//	CGContextSetRGBStrokeColor(theContext, 0.7f, 0.7f, 0.7f, 1.0f);
//	CGContextSetLineWidth(theContext, 2.0f);
//	CGContextStrokePath(theContext);
	
}


@end
