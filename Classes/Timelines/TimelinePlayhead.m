//
//  TimelinePlayhead.m
//  Annotation
//
//  Created by Adam Fouse on 7/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TimelinePlayhead.h"


@implementation TimelinePlayhead

- (id)init
{
	return [self initWithLayer:[CALayer layer]];
}

- (id)initWithLayer:(CALayer*)theLayer;
{
	self = [super init];
	if (self != nil) {
		theThumb = nil;
		playheadlayer = [theLayer retain];
		playheadlayer.delegate = self;
				
		thumblayer = [[CALayer layer] retain];
		thumblayer.delegate = self;
		thumblayer.anchorPoint = CGPointMake(0.0, 0.0);
		thumblayer.position = CGPointMake(0.0, 0.0);
		thumblayer.autoresizingMask = kCALayerNotSizable;
		
		[playheadlayer addSublayer:thumblayer];
		
		[self setBounds:playheadlayer.bounds];
		
	}
	return self;
}

- (void)setHeight:(CGFloat)height
{
	CGRect bounds = playheadlayer.bounds;
	bounds.size.height = height;
	playheadlayer.bounds = bounds;
}

- (void)setBounds:(CGRect)theRect
{
	if(theRect.size.width < 10)
	{
		theRect.size.width = 10;
	}
	playheadlayer.bounds = theRect;
	thumblayer.bounds = theRect;
		
	if(theThumb)
		CGPathRelease(theThumb);
	
	theThumb = CGPathCreateMutable();
	
	CGFloat bumpHeight = 3.0;
	CGRect rect = CGRectMake(0, 0, theRect.size.width, theRect.size.width - bumpHeight);
	rect.size.height = rect.size.height - 1.0;
	rect.size.width = rect.size.width - 1.0;
	rect.origin.x = rect.origin.x + (1.0 / 2);
	rect.origin.y = rect.origin.y + (1.0 / 2);
	
	CGFloat radius = 3.0;
	minx = CGRectGetMinX(rect);
	midx = CGRectGetMidX(rect);
	CGFloat maxx = CGRectGetMaxX(rect);
	CGFloat miny = CGRectGetMinY(rect);
	CGFloat midy = CGRectGetMidY(rect);
	CGFloat maxy = CGRectGetMaxY(rect);
	
	CGPathMoveToPoint(theThumb,NULL,minx, midy);
	CGPathAddArcToPoint(theThumb,NULL,minx, miny, midx, miny, radius);
	CGPathAddArcToPoint(theThumb,NULL,maxx, miny, maxx, midy, radius);
	CGPathAddArcToPoint(theThumb,NULL,maxx, maxy, midx + midx/2, maxy + bumpHeight, radius);
	CGPathAddArcToPoint(theThumb,NULL,midx, maxy + bumpHeight*2,midx - midx/2, maxy + bumpHeight, radius);
	CGPathAddArcToPoint(theThumb,NULL,minx, maxy, minx, midy, radius);
	CGPathCloseSubpath(theThumb);
	CGPathMoveToPoint(theThumb, NULL, midx + 3, miny + 2);
	CGPathAddLineToPoint(theThumb, NULL, midx + 3, maxy - 2);
	CGPathMoveToPoint(theThumb, NULL, midx - 3, miny + 2);
	CGPathAddLineToPoint(theThumb, NULL, midx - 3, maxy - 2);
	CGPathMoveToPoint(theThumb, NULL, midx, miny + 2);
	CGPathAddLineToPoint(theThumb, NULL, midx, maxy - 2);
	
	[thumblayer setNeedsDisplay];
}

- (void) dealloc
{
	//release the layer
	[playheadlayer release];
	[thumblayer release];
	
	// release the paths
    CFRelease(theThumb);
	
	[super dealloc];
}

- (CALayer*)layer
{
	return playheadlayer;
}


- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext
{
	CGSize bounds = theLayer.bounds.size;

	if(theLayer == playheadlayer)
	{
	CGContextBeginPath(theContext);
	CGContextAddRect(theContext, CGRectMake(minx+inset, 0, bounds.width - (inset*2), bounds.height));
	CGContextSetRGBFillColor(theContext, 1.0f, 0.9f, 0.5f, 0.3f);
	CGContextFillPath(theContext);
	
	CGContextBeginPath(theContext);
	CGContextMoveToPoint(theContext, midx, 0);
	CGContextAddLineToPoint(theContext, midx, bounds.height);
	CGContextSetRGBStrokeColor(theContext, 0.1f, 0.1f, 0.1f, 1.0f);
	CGContextSetLineWidth(theContext, 0.3f);
    CGContextStrokePath(theContext);
	
	}
	else if(theLayer == thumblayer)
	{

	CGContextBeginPath(theContext);
    CGContextAddPath(theContext, theThumb );
	CGContextSetRGBFillColor(theContext, 0.5f, 0.5f, 0.5f, 1.0f);
	CGContextFillPath(theContext);
	
	CGContextBeginPath(theContext);
	CGContextAddPath(theContext, theThumb );
	CGContextSetRGBStrokeColor(theContext, 0.2f, 0.2f, 0.2f, 1.0f);
	CGContextSetLineWidth(theContext, 1.0f);
	CGContextStrokePath(theContext);
	}
}



@end
