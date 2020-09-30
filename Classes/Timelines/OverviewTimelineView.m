//
//  OverviewTimelineView.m
//  DataPrism
//
//  Created by Adam Fouse on 3/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OverviewTimelineView.h"
#import "TimeVisualizer.h"
#import "TimelineZoomAnimation.h"
#import "AnnotationDocument.h"
#import "Annotation.h"
#import "AppController.h"
#import <AVKit/AVKit.h>

@implementation OverviewTimelineView

-(void)setup
{
	if(!setup)
	{
		[super setup];
		
		[self setShowPlayhead:NO];
		[self showTimes:YES];
		[[self timesLayer] removeFromSuperlayer];
		[[self layer] addSublayer:timesLayer];
		
		overSelection = NO;
		resizeSelectionLeft = NO;
		resizeSelectionRight = NO;
		makingSelection = NO;
		selectionCursor = nil;
		
		resizeMargin = 4;
		minSelectionWidth = 10;
		
		CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		CGFloat components[4] = {0.2f, 0.2f, 0.8f, 0.5f};
		selectionColor = CGColorCreate(colorSpace, components);
		
		selectionLayer = [[CALayer layer] retain];
		[selectionLayer setBounds:[self layer].bounds];
		[selectionLayer setBackgroundColor:selectionColor];
		
		[[self layer] addSublayer:selectionLayer];
		
		[detailTimeline addObserver:self
						 forKeyPath:@"annotationFilter"
							options:0
							context:NULL];
		
		setup = YES;
	}
}

- (void) dealloc
{
	[detailTimeline removeObserver:self
						forKeyPath:@"annotationFilter"];
	[selectionLayer release];
	[selectionTrackingArea release];
	CGColorRelease(selectionColor);
	[super dealloc];
}

- (void)setFrame:(NSRect)boundsRect
{
	[super setFrame:boundsRect];
	
	[self setSelection:selection];
}

- (void)setSegmentVisualizer:(SegmentVisualizer *)visualizer
{
	[super setSegmentVisualizer:visualizer];
	//[self setup];
}

-(void)setRange:(CMTimeRange)theRange
{
	range = theRange;
	[self setSelection:range];
}

-(CMTimeRange)selection
{
	return selection;
}

-(void)setSelection:(CMTimeRange)theSelection animate:(BOOL)animateChange
{
	if(animateChange)
	{
		TimelineZoomAnimation *anim = [[TimelineZoomAnimation alloc] initWithDuration:0.5
																	   animationCurve:NSAnimationEaseInOut];
		[anim setAnimationBlockingMode:NSAnimationNonblocking];
		[anim setStartRange:selection];
		[anim setEndRange:theSelection];
		[anim setOverviewTimeline:self];
		[anim setDelegate:self];
		
		[detailTimeline setResizing:YES];
		
		[anim startAnimation];
		
		[anim release];
	}
	else
	{
		[self setSelection:theSelection];
	}
}

- (void)animationDidEnd:(NSAnimation *)animation
{
	[detailTimeline setResizing:NO];
	[detailTimeline redrawSegments];
}

-(void)setSelection:(CMTimeRange)theSelection
{	
	selection = theSelection;
	
	selection = CMTimeRangeGetIntersection(theSelection, range);
	
	BOOL full = CMTimeRangeEqual(selection, range);
	
	NSTimeInterval rangeDuration;
	NSTimeInterval rangeStart;
	rangeDuration = CMTimeGetSeconds(range.duration);
	rangeStart = CMTimeGetSeconds(range.start);
	float movieTimeToPixel = [self bounds].size.width/rangeDuration;
	
	NSTimeInterval startTime;
	startTime = CMTimeGetSeconds(selection.start);
	NSTimeInterval endTime;
	endTime = CMTimeGetSeconds(CMTimeRangeGetEnd(selection));
	selectionStartX = (startTime - rangeStart) * movieTimeToPixel;
	selectionEndX = (endTime - rangeStart) * movieTimeToPixel;
	
	NSRect newFrame = NSMakeRect(selectionStartX, 0, selectionEndX - selectionStartX, [self bounds].size.height);
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	[selectionLayer setFrame:NSRectToCGRect(newFrame)];
	
	[CATransaction commit];
	
	if(full)
	{
		[selectionLayer setOpacity:0.5];
	}
	else
	{
		[selectionLayer setOpacity:1.0];
	}
	
	if(selectionTrackingArea)
	{
		[self removeTrackingArea:selectionTrackingArea];
		[selectionTrackingArea release];
		selectionTrackingArea = nil;
	}
	
	if(!dragging || full)
	{
		int options = NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp;
		NSTrackingArea *ta;
		newFrame.size.width = newFrame.size.width + (2*resizeMargin);
		newFrame.origin.x = newFrame.origin.x - resizeMargin;
		ta = [[NSTrackingArea alloc] initWithRect:newFrame options:options owner:self userInfo:nil];
		selectionTrackingArea = ta;
		[self addTrackingArea:ta];
	}
	
	if(!makingSelection)
	{
		[detailTimeline setRange:selection];
	}
		
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"annotationFilter"]) {
		
		//NSLog(@"update overview filter");
		
		[self setAnnotationFilter:[detailTimeline annotationFilter]];
    }
	else
	{
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
	}
}

#pragma mark Mouse Actions


-(void)updateSelectionCursor:(NSEvent*)theEvent
{
	overSelection = NO;
	resizeSelectionLeft = NO;
	resizeSelectionRight = NO;
	NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSCursor *cursor;
	if(fabs(curPoint.x - selectionLayer.frame.origin.x) < resizeMargin)
	{
		cursor = [NSCursor resizeLeftRightCursor];
		resizeSelectionLeft = YES;
	}
	else if(fabs(curPoint.x - (selectionLayer.frame.origin.x + selectionLayer.frame.size.width)) < resizeMargin)
	{
		cursor = [NSCursor resizeLeftRightCursor];
		resizeSelectionRight = YES;
	}
	else
	{
		cursor = [NSCursor openHandCursor];
		overSelection = YES;
	}
	if(selectionCursor)
	{
		[cursor set];
	}
	else
	{
		[cursor push];
	}
	selectionCursor = cursor;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	[self updateSelectionCursor:theEvent];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	[self updateSelectionCursor:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	if(!dragging)
	{
		overSelection = NO;
		resizeSelectionLeft = NO;
		resizeSelectionRight = NO;
		[NSCursor pop];
		selectionCursor = nil;
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	long long timeValue = ([self range].duration.value * (curPoint.x / [self bounds].size.width)) + [self range].start.value;
	CMTime current = CMTimeMake(timeValue, [self range].duration.timescale);
	
	if(overSelection)
	{
		CMTime newtime = CMTimeSubtract(current,offset);
        if(newtime.value < 0) {
			newtime.value = 0;
        }
		
        if(CMTIME_COMPARE_INLINE(CMTimeRangeGetEnd(range), <, CMTimeAdd(newtime, selection.duration))) {
			newtime = CMTimeSubtract(CMTimeRangeGetEnd(range), selection.duration);
        }
		
		selection.start = newtime;
		[self setSelection:selection];
	}
	else if ((resizeSelectionLeft) && ((selectionEndX - curPoint.x) > minSelectionWidth))
	{
		CMTime newStart = CMTimeSubtract(current,offset);
		if(newStart.value < 0)
			newStart.value = 0;
		
		CMTime end = CMTimeRangeGetEnd(selection);
		selection.start = newStart;
		selection.duration = CMTimeSubtract(end, newStart);
		[self setSelection:selection];
	}
	else if ((resizeSelectionRight) && ((curPoint.x - selectionStartX) > minSelectionWidth))
	{
		CMTime newEnd = CMTimeSubtract(current,offset);
		if(CMTIME_COMPARE_INLINE(CMTimeRangeGetEnd(range), <, newEnd))
			newEnd = CMTimeRangeGetEnd(range);
		
		selection.duration = CMTimeSubtract(newEnd, selection.start);
		[self setSelection:selection];
	}
	else if(makingSelection)
	{

		CMTime duration = CMTimeSubtract(current, clickTime);
		
		if(duration.value > 0)
		{
			[self setSelection:CMTimeRangeMake(clickTime, duration)];
		}
		else
		{
			duration.value = -duration.value;
			[self setSelection:CMTimeRangeMake(current, duration)];
		}		
		
	}
}

-(void)mouseUp:(NSEvent *)theEvent
{
	dragging = NO;
	[detailTimeline setResizing:NO];
	if(overSelection)
	{
		[[self window] enableCursorRects];
		[NSCursor pop];
	}
	else if (resizeSelectionLeft)
	{
		
	}
	else if (resizeSelectionRight)
	{
		
	}
	else if (makingSelection)
	{
		makingSelection = NO;
	}
	[self setSelection:selection];
	
	if(CMTimeRangeEqual(selection, range))
	{
		[[AppController currentApp] setOverviewVisible:NO];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	dragging = YES;
	[detailTimeline setResizing:YES];
	NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	long long timeValue = ([self range].duration.value * (curPoint.x / [self bounds].size.width)) + [self range].start.value;
	int timeScale = [self range].duration.timescale;
	clickTime = CMTimeMake(timeValue,timeScale);
	
	if(overSelection)
	{
		[[NSCursor closedHandCursor] push];
		[[self window] disableCursorRects];
		offset = CMTimeSubtract(clickTime,selection.start);
	}
	else if (resizeSelectionLeft)
	{
		offset = CMTimeSubtract(clickTime,selection.start);
	}
	else if (resizeSelectionRight)
	{
		offset = CMTimeSubtract(clickTime,CMTimeRangeGetEnd(selection));
	}
	else
	{
		makingSelection = YES;
	}
}

#pragma mark AnnotationView Methods

-(void)addAnnotation:(Annotation*)annotation
{
	if(![annotations containsObject:annotation])
	{
		[annotations addObject:annotation];
		[self displayAnnotation:annotation];
	}
}

-(void)addAnnotations:(NSArray*)array
{
	for(Annotation* annotation in array)
	{
		[self addAnnotation:annotation];
	}
}

-(void)removeAnnotation:(Annotation*)annotation
{
	[annotations removeObject:annotation];
	[segmentVisualizer removeSegmentBoundary:annotation];
}

-(void)updateAnnotation:(Annotation*)annotation
{
	[self displayAnnotation:annotation];
	if([selectedMarker annotation] == annotation)
	{
		[self setSelected:selectedMarker];
	}
}

-(BOOL)displayAnnotation:(Annotation*)annotation
{
	if(!filterAnnotations
	   || [[annotationFilter predicate] evaluateWithObject:annotation])
	{
		TimelineMarker *marker = [segmentVisualizer addKeyframe:annotation];
		if(marker)
		{			
			if(annotation == [[AppController currentApp] selectedAnnotation])
			{
				[self setSelected:marker];
			}
            return YES;
		}
	}
    return NO;
}

//-(void)setAnnotationFilter:(AnnotationFilter*)filter
//{
//	//	annotationFilter = [filter retain];
//	//	filterAnnotations = YES;
//	//	[self redrawAllSegments];
//}
//
//-(AnnotationFilter*)annotationFilter
//{
//	return nil;
//}

-(NSArray*)dataSets
{
	return [NSArray array];
}


-(void)update
{
    CMTime currentTime = [[[AppController currentDoc] movie] currentTime];
	if(!CMTimeRangeContainsTime(selection, currentTime))
	{
		CMTimeRange newSelection = selection;
		if(CMTIME_COMPARE_INLINE(currentTime, <, selection.start))
		{
			newSelection.start = CMTimeSubtract(selection.start, selection.duration);
			if(newSelection.start.value < 0)
			{
				newSelection.start.value = 0;
			}	
		}
		else
		{
			newSelection.start = CMTimeRangeGetEnd(selection);
			if(CMTIME_COMPARE_INLINE(CMTimeRangeGetEnd(range), <, CMTimeRangeGetEnd(newSelection)))
			{
				newSelection.start = CMTimeSubtract(CMTimeRangeGetEnd(range),selection.duration);
			}
		}
		[self setSelection:newSelection animate:NO];
	}
}

-(NSData*)currentState
{	
	NSMutableData *data = [NSMutableData data];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeCMTimeRange:selection forKey:@"OverviewTimeSelection"];
	[archiver finishEncoding];
	[archiver release];
	
	return data;
}

-(BOOL)setState:(NSData*)stateData
{
	
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:stateData];
	CMTimeRange storedRange = [unarchiver decodeCMTimeRangeForKey:@"OverviewTimeSelection"];
	[unarchiver finishDecoding];
	[unarchiver release];
	
	[self setSelection:storedRange];
	
//	NSDictionary *stateDict;
//	@try {
//		stateDict = [NSKeyedUnarchiver unarchiveObjectWithData:stateData];
//	}
//	@catch (NSException *e) {
//		NSLog(@"Invalid archive, %@", [e description]);
//		return NO;
//	}
	
	
	return YES;
}

@end
