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
#import <QTKit/QTKit.h>

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

-(void)setRange:(QTTimeRange)theRange
{
	range = theRange;
	[self setSelection:range];
}

-(QTTimeRange)selection
{
	return selection;
}

-(void)setSelection:(QTTimeRange)theSelection animate:(BOOL)animateChange
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

-(void)setSelection:(QTTimeRange)theSelection
{	
	selection = theSelection;
	
	selection = QTIntersectionTimeRange(theSelection, range);
	
	BOOL full = QTEqualTimeRanges(selection, range);
	
	NSTimeInterval rangeDuration;
	NSTimeInterval rangeStart;
	QTGetTimeInterval(range.duration, &rangeDuration);
	QTGetTimeInterval(range.time, &rangeStart);
	float movieTimeToPixel = [self bounds].size.width/rangeDuration;
	
	NSTimeInterval startTime;
	QTGetTimeInterval(selection.time, &startTime);
	NSTimeInterval endTime;
	QTGetTimeInterval(QTTimeRangeEnd(selection), &endTime);
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
	long long timeValue = ([self range].duration.timeValue * (curPoint.x / [self bounds].size.width)) + [self range].time.timeValue;
	QTTime current = QTMakeTime(timeValue, [self range].duration.timeScale);
	
	if(overSelection)
	{
		QTTime newtime = QTTimeDecrement(current,offset);
		if(newtime.timeValue < 0)
			newtime.timeValue = 0;
		
		if(QTTimeCompare(QTTimeRangeEnd(range), QTTimeIncrement(newtime, selection.duration)) == NSOrderedAscending)
			newtime = QTTimeDecrement(QTTimeRangeEnd(range), selection.duration);
		
		selection.time = newtime;
		[self setSelection:selection];
	}
	else if ((resizeSelectionLeft) && ((selectionEndX - curPoint.x) > minSelectionWidth))
	{
		QTTime newStart = QTTimeDecrement(current,offset);
		if(newStart.timeValue < 0)
			newStart.timeValue = 0;
		
		QTTime end = QTTimeRangeEnd(selection);
		selection.time = newStart;
		selection.duration = QTTimeDecrement(end, newStart);
		[self setSelection:selection];
	}
	else if ((resizeSelectionRight) && ((curPoint.x - selectionStartX) > minSelectionWidth))
	{
		QTTime newEnd = QTTimeDecrement(current,offset);
		if(QTTimeCompare(QTTimeRangeEnd(range), newEnd) == NSOrderedAscending)
			newEnd = QTTimeRangeEnd(range);
		
		selection.duration = QTTimeDecrement(newEnd, selection.time);
		[self setSelection:selection];
	}
	else if(makingSelection)
	{

		QTTime duration = QTTimeDecrement(current, clickTime);
		
		if(duration.timeValue > 0)
		{
			[self setSelection:QTMakeTimeRange(clickTime, duration)];
		}
		else
		{
			duration.timeValue = -duration.timeValue;
			[self setSelection:QTMakeTimeRange(current, duration)];
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
	
	if(QTEqualTimeRanges(selection, range))
	{
		[[AppController currentApp] setOverviewVisible:NO];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	dragging = YES;
	[detailTimeline setResizing:YES];
	NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	long long timeValue = ([self range].duration.timeValue * (curPoint.x / [self bounds].size.width)) + [self range].time.timeValue;
	long timeScale = [self range].duration.timeScale;
	clickTime = QTMakeTime(timeValue,timeScale);
	
	if(overSelection)
	{
		[[NSCursor closedHandCursor] push];
		[[self window] disableCursorRects];
		offset = QTTimeDecrement(clickTime,selection.time);
	}
	else if (resizeSelectionLeft)
	{
		offset = QTTimeDecrement(clickTime,selection.time);
	}
	else if (resizeSelectionRight)
	{
		offset = QTTimeDecrement(clickTime,QTTimeRangeEnd(selection));
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
	QTTime currentTime = [[[AppController currentDoc] movie] currentTime];
	if(!QTTimeInTimeRange(currentTime, selection))
	{
		QTTimeRange newSelection = selection;
		if(QTTimeCompare(currentTime, selection.time) == NSOrderedAscending)
		{
			newSelection.time = QTTimeDecrement(selection.time, selection.duration);
			if(newSelection.time.timeValue < 0)
			{
				newSelection.time.timeValue = 0;
			}	
		}
		else
		{
			newSelection.time = QTTimeRangeEnd(selection);
			if(QTTimeCompare(QTTimeRangeEnd(range),QTTimeRangeEnd(newSelection)) == NSOrderedAscending)
			{
				newSelection.time = QTTimeDecrement(QTTimeRangeEnd(range),selection.duration);
			}
		}
		[self setSelection:newSelection animate:NO];
	}
}

-(NSData*)currentState
{	
	NSMutableData *data = [NSMutableData data];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeQTTimeRange:selection forKey:@"OverviewTimeSelection"];
	[archiver finishEncoding];
	[archiver release];
	
	return data;
}

-(BOOL)setState:(NSData*)stateData
{
	
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:stateData];
	QTTimeRange storedRange = [unarchiver decodeQTTimeRangeForKey:@"OverviewTimeSelection"];
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
