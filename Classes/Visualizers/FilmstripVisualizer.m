//
//  FilmstripVisualizer.m
//  Annotation
//
//  Created by Adam Fouse on 8/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FilmstripVisualizer.h"
#import "VideoFrameLoader.h"
#import "AppController.h"

@implementation FilmstripVisualizer

-(id)initWithTimelineView:(TimelineView*)timelineView
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{
		//[self reset];
		[self setAutoSegments:YES];
		autoSegmentPadding = 4;
	}
	return self;
}

- (void) dealloc
{
	[markers removeAllObjects];
	[super dealloc];
}

-(void)reset
{
	[markers removeAllObjects];
	builtMarkers = NO;
	[super reset];
}

-(void)setup
{
	if(!builtMarkers)
	{
		[self buildMarkers];
	}
}

-(TimelineMarker *)addKeyframe:(SegmentBoundary*)keyframe
{
	[self setup];
	return nil;
}

-(void)buildMarkers
{
	if([self movie]) {
		
		float timelineWidth = [timeline bounds].size.width;
		
		QTTimeRange range = [timeline range];
		NSTimeInterval rangeDuration;
		NSTimeInterval rangeStart;
		QTGetTimeInterval(range.duration, &rangeDuration);
		QTGetTimeInterval(range.time, &rangeStart);
		float pixelToMovieTime = rangeDuration/timelineWidth;
		float movieTimeToPixel = [timeline bounds].size.width/rangeDuration;
		
		int width;
		int numberOfSegments;

		NSSize contentSize = [[[self movie] attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
		float ratio = contentSize.width/contentSize.height;
		width = ([timeline bounds].size.height *  ratio) + autoSegmentPadding;
		numberOfSegments = ceil((float)timelineWidth / width);

		int x = width;
		int i;
		
		SegmentBoundary *initial = [[SegmentBoundary alloc] initFromApp:[AppController currentApp] atTime:range.time];
		SegmentBoundary *previous = initial;
		
		NSTimeInterval previousStart;
		NSTimeInterval boundaryStart;
		
		for(i = 0; i < numberOfSegments; i++)
		{
			NSTimeInterval time = ((float)x)*pixelToMovieTime + rangeStart;
			QTTime qttime = QTMakeTimeWithTimeInterval(time);
			SegmentBoundary *boundary = [[SegmentBoundary alloc] initFromApp:[AppController currentApp] atTime:qttime];
			
			TimelineMarker *marker = [super addKeyframe:previous];
			[markers addObject:marker];
			[marker setEnd:boundary];
			
			QTGetTimeInterval([previous time], &previousStart);
			QTGetTimeInterval([boundary time], &boundaryStart);
			
			float beginX = (float)(previousStart - rangeStart) * movieTimeToPixel;
			float endX = (float)(boundaryStart - rangeStart) * movieTimeToPixel;
			
			// Set up segment border
			NSRect rect = NSMakeRect(beginX, 
									 0,
									 endX - beginX,
									 [timeline bounds].size.height);
			NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
			[marker setPath:path];
			
			CALayer *base = [self visualizationLayer];
			CALayer *layer = [CALayer layer];
			[layer setAnchorPoint:CGPointMake(0.0, 0.0)];
			[layer setFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
            CGColorRef borderColor = CGColorCreateGenericRGB(0.2, 0.3, 0.4, 1.0);
			[layer setBorderColor:borderColor];
            CGColorRelease(borderColor);
			[layer setBorderWidth:2.0];
			[marker setLayer:layer];
			[layer setDelegate:marker];
			[layer setNeedsDisplay];
			[base addSublayer:layer];
			
			[marker setVisualizer:self];
			
			[[[AppController currentApp] frameLoader] loadCIImage:marker immediately:NO];
			
			[boundary release];
			
			previous = boundary;
			x = x + width;
		}
		[initial release];
		
	}
	builtMarkers = YES;
}

-(BOOL)updateMarkers
{
	if([timeline inLiveResize])
	{
		for(TimelineMarker *marker in markers)
		{
			CGRect bounds = [marker layer].bounds;
			bounds.size.height = [timeline frame].size.height;
			//			CGPoint position = [marker layer].position;
			//			position.y = 0;
			[marker layer].bounds = bounds;
		}
		return YES;
	}
	else
	{
		return NO;
	}
}

-(void)drawMarker:(TimelineMarker*)marker
{
	//NSLog(@"draw frame marker");
	//if(([[[marker layer] sublayers] count] == 0) && [marker image])
	if([marker image])
	{
		//NSLog(@"draw frame marker frame, delay: %f",[[marker date] timeIntervalSinceNow]);
//		[marker layer].borderColor = CGColorCreateGenericRGB(0.2, 0.3, 0.4, 1.0);
//		[marker layer].borderWidth = 2.0;
		[marker layer].contents = (id)[marker image];
	}
	 
}


@end
