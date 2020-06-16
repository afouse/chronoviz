//
//  LayeredVisualizer.m
//  Annotation
//
//  Created by Adam Fouse on 8/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LayeredVisualizer.h"
#import "Annotation.h"
#import "TimelineView.h"
#import "NSColorCGColor.h"

@implementation LayeredVisualizer

@synthesize overlayAnnotations;

-(id)initWithTimelineView:(TimelineView*)timelineView
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{
		viz = nil;
	}
	return self;
}

-(id)initWithTimelineView:(TimelineView*)timelineView andSecondVisualizer:(SegmentVisualizer*)secondViz
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{
		viz = [secondViz retain];
	}
	return self;
}

- (void) dealloc
{
	[viz release];
	[super dealloc];
}

- (SegmentVisualizer*)dataVisualizer
{
	return viz;
}

-(void)reset
{
	[viz reset];
	[super reset];
}

-(void)setup
{
	[viz setup];
	[super setup];
}

-(BOOL)updateMarkers
{
	if(viz)
	{
		return [viz updateMarkers] & [super updateMarkers];
	}
	else
	{
		return [super updateMarkers];
	}
	
}

//-(void)updateMarker:(TimelineMarker*)marker
//{
////	if(![[marker annotation] isDuration])
////	{
//		[super updateMarker:marker];
////	}
//}

-(TimelineMarker *)addKeyframe:(SegmentBoundary*)keyframe
{
	[viz setup];
	return [super addKeyframe:keyframe];
}


-(void)updateMarker:(TimelineMarker*)marker
{	
	if(!self.overlayAnnotations)
	{
		[super updateMarker:marker];
	}
	else
	{
		SegmentBoundary *segment = [marker boundary];
		
		CMTimeRange range = [timeline range];
		NSTimeInterval rangeDuration;
		NSTimeInterval rangeStart;
		rangeDuration = CMTimeGetSeconds(range.duration);
        rangeStart = CMTimeGetSeconds(range.start);
		float movieTimeToPixel = [timeline bounds].size.width/rangeDuration;
		
		NSRect rect;
		NSBezierPath *path = nil;
		NSTimeInterval startTime;
		startTime = CMTimeGetSeconds([segment time]);
		if([marker isDuration])
		{
			NSTimeInterval endTime;
			endTime = CMTimeGetSeconds([[marker annotation] endTime]);
			
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
				
                if([marker isDuration] && [[base sublayers] count])
                {
                    [base insertSublayer:layer below:[[base sublayers] objectAtIndex:0]];
                }
				else
				{
					[base addSublayer:layer];
					//[base insertSublayer:layer below:[timeline playheadLayer]];
				}
				
//				if([marker isDuration])
//				{
//					//[base insertSublayer:layer below:[dataViz graphLayer]];
//					[base addSublayer:layer];
//				}
//				else
//				{
//					[base addSublayer:layer];
//				}
			}
			
			[layer setFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
			[layer setDelegate:marker];
			[layer setNeedsDisplay];
		}
	}
	
}

-(void)drawMarker:(TimelineMarker*)marker
{
	if(!self.overlayAnnotations)
	{
		[super drawMarker:marker];
	}
	else
	{
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
				[marker layer].opacity = 0.5;
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
}


@end
