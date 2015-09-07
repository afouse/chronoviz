//
//  SegmentMarker.m
//  Annotation
//
//  Created by Adam Fouse on 1/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TimelineMarker.h"
#import "SegmentVisualizer.h"
#import "Annotation.h"
#import "AppController.h"

@interface TimelineMarker (Private)

- (void)updateCursorForPoint:(NSPoint)pt;

@end

@implementation TimelineMarker

@synthesize date;
@synthesize data;
@synthesize layer;
@synthesize visualizer;
@synthesize timeline;
@synthesize end;
@synthesize path;
@synthesize alternate;
@synthesize track;
@synthesize backgroundColor;

//static int markerCount = 0;

-(id)initWithKeyframe:(SegmentBoundary*)theKeyframe
{
	return [self initWithKeyframe:theKeyframe andPath:nil];
}

-(id)initWithKeyframe:(SegmentBoundary*)theKeyframe andPath:(NSBezierPath*)thePath
{
	self = [super init];
	if(self != nil)
	{
		
		start = [theKeyframe retain];

		if([theKeyframe isMemberOfClass:[Annotation class]])
		{
			
			annotation = (Annotation*)theKeyframe;
			
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(select)
														 name:AnnotationSelectedNotification
													   object:annotation];
			
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(update)
														 name:AnnotationUpdatedNotification
													   object:annotation];
			
		}
		else
		{
			annotation = nil;
		}
		
		self.path = [thePath retain];
		self.end = nil;
		trackingArea = nil;
		self.data = nil;
		self.visualizer = nil;
		self.backgroundColor = nil;
		self.image = 0;
		self.track = 0;
		
	}
	return self;
}

-(id)initWithAnnotation:(Annotation*)theAnnotation
{
	return [self initWithKeyframe:theAnnotation andPath:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[start release];
	[end release];
	if(path)
		[path release];
	if(trackingArea)
		[trackingArea release];
	if(data)
		[data release];
	if(backgroundColor)
		[backgroundColor release];
	
	if(image)
		CGImageRelease(image);
	if(layer)
	{
		[layer release];
	}
		
	[super dealloc];
}

-(void)update
{
	[visualizer updateMarker:self];
	[timeline updateAnnotation:annotation];
}

-(void)select
{
	if([annotation selected])
	{
		[timeline setSelected:self];
	}
	[layer setNeedsDisplay];
}

-(NSTrackingArea *)trackingArea
{
	return trackingArea;
}

-(void)setTrackingArea:(NSTrackingArea*)ta
{
	[ta retain];
	if(trackingArea)
		[trackingArea release];
	trackingArea = ta;
}

-(void)setImage:(CGImageRef)img
{
	CGImageRetain(img);
	if(image)
	{
		CGImageRelease(image);
	}
	image = img;
}

-(CGImageRef)image
{
	return image;
}

-(SegmentBoundary*)boundary
{
	return start;
}

-(Annotation*)annotation
{
	return annotation;
}

-(BOOL)isDuration
{
	return [annotation isDuration];
}

-(NSTimeInterval)time
{
	NSTimeInterval theTime = 0;
	if(annotation)
	{
		QTGetTimeInterval([annotation startTime], &theTime);
	}
	return theTime;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	NSGraphicsContext *nsGraphicsContext;
	nsGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx
																   flipped:NO];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:nsGraphicsContext];
	
	[visualizer drawMarker:self];
	
	[NSGraphicsContext restoreGraphicsState];
	
	[CATransaction commit];
}

- (void)setHighlighted:(BOOL)isHighlighted
{
	[start setHighlighted:isHighlighted];
	[layer setNeedsDisplay];
}

- (BOOL)highlighted
{
	return [start highlighted];
}

-(BOOL)startResizeLeft:(CGPoint)point
{
	if(![[self layer] containsPoint:point])
	{
		return NO;
	}
	
	if(![annotation isDuration])
	{
		return YES;
	}
	
	if((point.x > 0) 
	   && (point.x < 5) 
	   && (point.x < [self layer].bounds.size.width))
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

-(BOOL)startResizeRight:(CGPoint)point
{
	if(![[self layer] containsPoint:point])
	{
		return NO;
	}
	
	if((point.x > ([self layer].bounds.size.width - 5)) && (point.x < [self layer].bounds.size.width))
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

- (void)setSelected:(BOOL)isSelected
{
	[annotation setSelected:isSelected];
	[layer setNeedsDisplay];
}

- (BOOL)selected
{
	return (annotation && [annotation selected]);
}

- (void)mouseMoved:(NSEvent*)theEvent
{
	if([timeline shouldHighlightMarker:self])
	{
		if(![timeline highlightedMarker]) // || ([timeline highlightedMarker] == self))
		{
			[self setHighlighted:YES];
			[timeline setHighlightedMarker:self];
			
			if(annotation)
				[[AppController currentApp] displayHoverForTimelineMarker:self];
		}
	}
	
	NSPoint pt = [timeline convertPoint:[theEvent locationInWindow] fromView:nil];
	CGPoint markerPoint = [[self layer] convertPoint:CGPointMake(pt.x, pt.y) fromLayer:[timeline layer]];
	
	if([self selected])
	{
		if([self startResizeLeft:markerPoint] || [self startResizeRight:markerPoint])
		{
			[[NSCursor resizeLeftRightCursor] set];
		}
		else
		{
			[[NSCursor arrowCursor] set];
		}
		//[[NSCursor resizeLeftRightCursor] set];
	}
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	if([timeline shouldHighlightMarker:self])
	{
		[self setHighlighted:YES];
		if([timeline highlightedMarker])
		{
			[[timeline highlightedMarker] setHighlighted:NO];
		}
		[timeline setHighlightedMarker:self];
		
		if(annotation)
			[[AppController currentApp] displayHoverForTimelineMarker:self];
	}	
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[self setHighlighted:NO];
	
	if([timeline highlightedMarker] == self)
	{
		[timeline setHighlightedMarker:nil];
	}
	
	[timeline cursorUpdate:nil];
	
	[[AppController currentApp] closeHoverForMarker:self];
}

- (void)updateCursorForPoint:(NSPoint)pt
{
	
}

@end
