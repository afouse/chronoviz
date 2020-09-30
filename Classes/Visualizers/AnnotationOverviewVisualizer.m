//
//  AnnotationOverviewVisualizer.m
//  ChronoViz
//
//  Created by Adam Fouse on 4/8/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "AnnotationOverviewVisualizer.h"
#import "Annotation.h"
#import "VideoProperties.h"
#import "AnnotationCategory.h"
#import "NSColorCGColor.h"

@interface AnnotationOverviewVisualizer (Internal)

- (NSString*)trackNameForMarker:(TimelineMarker*)marker;

@end

@implementation AnnotationOverviewVisualizer

-(id)initWithTimelineView:(TimelineView*)timelineView
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{
		tracks = [[NSMutableDictionary alloc] init];
		trackOrder = [[NSMutableArray alloc] init];
		trackHeight = 3;
	}
	return self;
}

-(void)dealloc
{
	[trackOrder release];
	[tracks release];
	[super dealloc];
}

-(void)reset
{
	[trackOrder removeAllObjects];
	[tracks removeAllObjects];
	[markers removeAllObjects];
	[super reset];
}

-(TimelineMarker *)addKeyframe:(SegmentBoundary*)keyframe
{
	TimelineMarker *marker = nil;
	
	// Make sure that we only display full annotations
	if([keyframe isMemberOfClass:[Annotation class]])
	{
		marker = [super addKeyframe:keyframe];
		if(marker) {
			[markers addObject:marker];
			[self updateMarker:marker];
		}
	}
	return marker;
}

-(TimelineMarker*)removeSegmentBoundary:(SegmentBoundary*)boundary
{
	TimelineMarker *marker = [[super removeSegmentBoundary:boundary] retain];
	if(marker)
	{
		NSString *trackName = [self trackNameForMarker:marker];
		NSMutableArray* track = [tracks objectForKey:trackName];
		[track removeObject:marker];
		if([track count] == 0)
		{
			[tracks removeObjectForKey:trackName];
			[trackOrder removeObject:track];
			[self updateMarkers];
		}
		
		[markers removeObject:marker];
	}
	return marker;
}

-(BOOL)updateMarkers
{
	for(TimelineMarker *marker in addedSegments)
	{
		[self updateMarker:marker];
	}
	return YES;
}

- (NSString*)trackNameForMarker:(TimelineMarker*)marker
{
	AnnotationCategory *category;
	if([[[marker annotation] category] category])
	{
		category = [[[marker annotation] category] category];
	}
	else
	{
		category = [[marker annotation] category];
	}
	
	NSString *categoryName= [category name];
	
	if(!categoryName)
	{
		categoryName = @"";
	}
	
	return categoryName;
}

-(void)updateMarker:(TimelineMarker*)marker
{	
	SegmentBoundary *segment = [marker boundary];
	NSMutableArray* track = [tracks objectForKey:[self trackNameForMarker:marker]];
	if(!track)
	{
		track = [NSMutableArray array];
		[tracks setObject:track forKey:[self trackNameForMarker:marker]];
		[trackOrder addObject:track];
	}
	[track addObject:marker];
	NSUInteger trackIndex = [trackOrder indexOfObject:track];
	
	CMTimeRange range = [timeline range];
	NSTimeInterval rangeDuration;
	NSTimeInterval rangeStart;
	rangeDuration = CMTimeGetSeconds(range.duration);
	rangeStart = CMTimeGetSeconds(range.start);
	float movieTimeToPixel = [timeline bounds].size.width/rangeDuration;
	
	
	NSTimeInterval startTime;
	startTime = CMTimeGetSeconds([segment time]);
	CGFloat start = floor((startTime - rangeStart) * movieTimeToPixel) + 0.5;
	CGFloat markerwidth;
	if([marker isDuration])
	{
		NSTimeInterval endTime;
		endTime = CMTimeGetSeconds([[marker annotation] endTime]);
		
		CGFloat end = floor((endTime - rangeStart) * movieTimeToPixel) + 0.5;
		if(end < start)
		{
			CGFloat starttemp = start;
			start = end;
			end = starttemp;
		}
		if(end - start < 1)
		{
			end += 2;
		}
		markerwidth = round(end - start);
	}
	else
	{
		markerwidth = 2;
	}
	
	NSRect rect = NSMakeRect(start,[timeline bounds].size.height - (trackHeight * (trackIndex + 1)),markerwidth,trackHeight);
	NSBezierPath *path = [[NSBezierPath bezierPathWithRect:rect] retain];
	
	[marker setPath:path];
	[path release];
	
	// Layer Setup
	
	if(CGRectIsNull(CGRectIntersection([timeline visualizationLayer].bounds, NSRectToCGRect(rect))))
	{
		[[marker layer] setHidden:YES];
	}
	else
	{
		CALayer *base = [timeline visualizationLayer];
		CALayer *layer = [marker layer];
		if(layer == nil)
		{
			layer = [CALayer layer];
			[marker setLayer:layer];
			[base addSublayer:layer];
			
			if([marker isDuration])
			{
				[layer setEdgeAntialiasingMask:0];
			}
		}
		else
		{
			[[[layer sublayers] objectAtIndex:0] removeFromSuperlayer];
		}
		
		[layer setHidden:NO];
		[layer setFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
		
		
		[layer setDelegate:marker];
		[layer setNeedsDisplay];
	}
	
}

-(void)drawMarker:(TimelineMarker*)marker
{
	Annotation* annotation = [marker annotation];
	
	NSColor *backgroundColor = [annotation colorObject];
	if(!backgroundColor)
	{
		backgroundColor = [NSColor grayColor];
	}

	CGRect layerBounds = [marker layer].bounds;
	layerBounds.size.height = trackHeight;
	[marker layer].bounds = layerBounds;
	
	if([marker backgroundColor] != backgroundColor)
	{
		[marker setBackgroundColor:backgroundColor];
		CGColorRef annColor = [backgroundColor createCGColor];
		[marker layer].backgroundColor = annColor;
		CGColorRelease(annColor);
	}
	
}


@end
