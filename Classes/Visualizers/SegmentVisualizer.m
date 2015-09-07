//
//  SegmentVisualizer.m
//  Annotation
//
//  Created by Adam Fouse on 1/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SegmentVisualizer.h"
#import "TimelineView.h"
#import "TimelineMarker.h"
#import "VideoProperties.h"
#import "Annotation.h"
#import "AppController.h"


@interface SegmentVisualizer (SegmentVisualizerInternal)

-(void)detachTimelineMarker:(TimelineMarker*)marker;

@end


@implementation SegmentVisualizer

@synthesize autoSegments;
@synthesize videoProperties;

-(id)initWithTimelineView:(TimelineView*)timelineView
{
	timeline = timelineView;
	//[self setMovie:[timeline movie]];
	[self setVideoProperties:nil];
	addedSegments = [[NSMutableArray alloc] init];
	markers = [[NSMutableArray alloc] init];
	[self setAutoSegments:NO];
	return self;
}

-(void)dealloc
{
//	for(TimelineMarker *marker in addedSegments)
//	{
//		[marker setVisualizer:nil];
//		[marker setTimeline:nil];
//		if([marker layer])
//		{
//			[[marker layer] removeFromSuperlayer];
//		}
//	}
	for(TimelineMarker *marker in addedSegments)
	{
		[self detachTimelineMarker:marker];
	}
	[addedSegments release];
	[markers release];
	[videoProperties release];
	[super dealloc];
}

-(void)reset
{
	for(TimelineMarker *marker in addedSegments)
	{
		[self detachTimelineMarker:marker];
	}
	[addedSegments removeAllObjects];
}

-(void)detachTimelineMarker:(TimelineMarker*)marker
{
	[marker setVisualizer:nil];
	[marker setTimeline:nil];
	if([marker layer])
	{
		[[marker layer] removeFromSuperlayer];
	}
	if([timeline highlightedMarker] == marker)
	{
		[[AppController currentApp] closeHoverForMarker:marker];
		[marker setHighlighted:NO];
		[timeline setHighlightedMarker:nil];
	}
}

-(void)setup
{
	
}

-(TimelineMarker *)addKeyframe:(SegmentBoundary*)keyframe
{
	for(TimelineMarker *marker in addedSegments)
	{
		if([marker boundary] == keyframe)
		{
			return nil;
		}
	}

	TimelineMarker *segmentMarker = [[TimelineMarker alloc] initWithKeyframe:keyframe];
	[addedSegments addObject:segmentMarker];
	[segmentMarker release];
	[segmentMarker setVisualizer:self];
	[segmentMarker setTimeline:timeline];
	return segmentMarker;
}

-(TimelineMarker*)removeSegmentBoundary:(SegmentBoundary*)boundary
{
	TimelineMarker *marker = nil;
	for(marker in addedSegments)
	{
		if([marker boundary] == boundary)
			break;
	}
	if(marker)
	{
		[marker retain];
		[self detachTimelineMarker:marker];
		[addedSegments removeObject:marker];
		[marker autorelease];
	}
	return marker;
}

-(NSArray *)markers
{
	return markers;
}

-(QTMovie *)movie
{
	if(videoProperties)
	{
		return [videoProperties movie];
	}
	else
	{
		return [timeline movie];
	}
}

-(CALayer*)visualizationLayer
{
	return [timeline visualizationLayer];
}

-(BOOL)updateMarkers
{
	return NO;
}

-(void)updateMarker:(TimelineMarker*)marker
{
	
}

-(void)drawMarker:(TimelineMarker *)marker
{
	
}

-(BOOL)canDragMarkers
{
	return NO;
}

-(BOOL)dragMarker:(TimelineMarker*)marker forDragEvent:(NSEvent*)theEvent
{
	return NO;
}
	
	

@end
