//
//  AnnotationTimeSeriesVisualizer.m
//  Annotation
//
//  Created by Adam Fouse on 8/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationTimeSeriesVisualizer.h"
#import "TimeSeriesVisualizer.h"
#import "Annotation.h"
#import "NSColorCGColor.h"

@implementation AnnotationTimeSeriesVisualizer

-(id)initWithTimelineView:(TimelineView*)timelineView
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{
		dataViz = [[TimeSeriesVisualizer alloc] initWithTimelineView:timelineView];
		viz = [dataViz retain];
        
        self.overlayAnnotations = NO;
        
	}
	return self;
}

- (id)initWithTimelineView:(TimelineView *)timelineView andVisualizer:(TimeSeriesVisualizer*)theViz
{
	self = [super initWithTimelineView:timelineView andSecondVisualizer:theViz];
	if(self)
	{
		dataViz = [theViz retain];
        
        self.overlayAnnotations = YES;
	}
	return self;
}

- (void) dealloc
{
	[dataViz release];
	[super dealloc];
}


-(void)updateMarker:(TimelineMarker*)marker
{	
//    self.overlayAnnotations = NO;
//    [super updateMarker:marker];
//    return;
    
	SegmentBoundary *segment = [marker boundary];
	
	QTTimeRange range = [timeline range];
	NSTimeInterval rangeDuration;
	NSTimeInterval rangeStart;
	QTGetTimeInterval(range.duration, &rangeDuration);
	QTGetTimeInterval(range.time, &rangeStart);
	float movieTimeToPixel = [timeline bounds].size.width/rangeDuration;
	
	NSRect rect;
	NSBezierPath *path = nil;
	NSTimeInterval startTime;
	QTGetTimeInterval([segment time], &startTime);
	if([marker isDuration])
	{
		NSTimeInterval endTime;
		QTGetTimeInterval([[marker annotation] endTime], &endTime);
		
		CGFloat start = (startTime - rangeStart) * movieTimeToPixel;
		CGFloat end = (endTime - rangeStart) * movieTimeToPixel;
		if(end < start)
		{
			float starttemp = start;
			start = end;
			end = starttemp;
		}
		if(end - start < 1)
		{
			end += 1;
		}
		rect = NSMakeRect(start,0,end - start,[timeline bounds].size.height);
		path = [[NSBezierPath bezierPathWithRect:rect] retain];
	}
	else
	{
		rect = NSMakeRect(((startTime - rangeStart) * movieTimeToPixel) - annotationRadius, 
						  [timeline bounds].size.height/4.0,
						  annotationRadius * 2,
						  [timeline bounds].size.height/2.0);
		NSRect zeroedRect = NSMakeRect(1, 
									   1,
									   (annotationRadius * 2) - 2.0,
									   ([timeline bounds].size.height/2.0) - 2.0);
		path = [[NSBezierPath bezierPathWithRoundedRect:zeroedRect xRadius:4 yRadius:4] retain];
	}
	[marker setPath:path];
	[path release];
	

	if([marker trackingArea])
	{
		[timeline removeTrackingArea:[marker trackingArea]];
		[marker setTrackingArea:nil];
	}

	
	if(CGRectIsNull(CGRectIntersection([timeline visualizationLayer].bounds, NSRectToCGRect(rect))))
	{
		[[marker layer] setHidden:YES];
	}
	else
	{	
		int options = NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp;
		NSTrackingArea *ta;
		ta = [[NSTrackingArea alloc] initWithRect:rect options:options owner:marker userInfo:nil];
		[marker setTrackingArea:ta];
		[timeline addTrackingArea:ta];
		[ta release];
		
		// Core Animation Setup
		CALayer *base = [timeline visualizationLayer];
		CALayer *layer = [marker layer];
		[layer setHidden:NO];
		if(layer == nil)
		{
			layer = [CALayer layer];
			[marker setLayer:layer];
			if([marker isDuration])
			{
				[base insertSublayer:layer below:[dataViz graphLayer]];
			}
			else
			{
				[base addSublayer:layer];
			}
		}
		
		[layer setFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
		[layer setDelegate:marker];
		[layer setNeedsDisplay];
	}
	
}

-(void)drawMarker:(TimelineMarker*)marker
{
//    self.overlayAnnotations = NO;
//    [super drawMarker:marker];
//    return;
    
	Annotation* annotation = [marker annotation];
	
	NSColor *backgroundColor = [annotation colorObject];
	if(!backgroundColor)
	{
		backgroundColor = [NSColor grayColor];
	}
	
	CGFloat defaultLineWidth = [NSBezierPath defaultLineWidth];
	
	if([marker isDuration])
	{		
		CGColorRef annColor = [backgroundColor createCGColor];
		[marker layer].backgroundColor = annColor;
		CGColorRelease(annColor);
		
		[backgroundColor set];
		[NSBezierPath fillRect:NSRectFromCGRect([[marker layer] bounds])];
		
		if([marker highlighted])
		{
			[marker layer].opacity = 0.8;
		} else {
			//[marker layer].opacity = 0.5;
            [marker layer].opacity = 0.7;
		}
	}
	else
	{
		[backgroundColor set];
		[[marker path] fill];
		
		if([marker highlighted]) {
			[[NSColor whiteColor] set];
			[[marker path] stroke];
		} else {
			[[NSColor blackColor] set];
			[[marker path] stroke];
		}
	}
	if([marker selected])
	{
		[marker layer].shadowOpacity = 0.5;
	} else {
		[marker layer].shadowOpacity = 0;
	}
	
	[NSBezierPath setDefaultLineWidth:defaultLineWidth];
	
}

@end
