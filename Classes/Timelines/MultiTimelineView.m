//
//  MultiTimelineView.m
//  Annotation
//
//  Created by Adam Fouse on 6/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MultiTimelineView.h"
#import "AnnotationFilmstripVisualizer.h"
#import "AudioVisualizer.h"
#import "TimeSeriesData.h"
#import "TimeSeriesVisualizer.h"
#import "VideoProperties.h"
#import "Annotation.h"
#import "AnnotationFilter.h"
#import "AnnotationCategoryFilter.h"
#import "AppController.h"
#import "DPConstants.h"

@implementation MultiTimelineView

@synthesize maximumHeight;
@synthesize interTimelineSpace;
@synthesize timelineHeight;
@synthesize needsLayout;
@synthesize draggingTimeline;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {		
		backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.1 alpha:1.0] 
														   endingColor:[NSColor colorWithDeviceWhite:0.2 alpha:1.0]];
		
		borderColor = [NSColor blackColor];
		
		filterAnnotations = NO;
		wrappedTimelines = NO;
        
		timelines = [[NSMutableArray alloc] init];
		TimelineView* baseTimeline = [[TimelineView alloc] initWithFrame:frame];
		[timelines addObject:baseTimeline];
		[baseTimeline setAutoresizingMask:(NSViewWidthSizable | NSViewMinXMargin | NSViewMaxXMargin)];
		[self addSubview:baseTimeline];
		[baseTimeline release];
		[baseTimeline setSuperTimelineView:self];
		[self setActiveTimeline:baseTimeline];
		
		[baseTimeline addObserver:self
				   forKeyPath:@"annotationFilter"
					  options:0
					  context:NULL];
		
        self.maximumHeight = FLT_MAX;
		self.interTimelineSpace = 15.0;
		self.timelineHeight = frame.size.height;
		
		theLines = CGPathCreateMutable();
		
    }
    return self;
}

- (void)dealloc
{
	for(TimelineView *timeline in timelines)
	{
		[timeline removeObserver:self
					  forKeyPath:@"annotationFilter"];
	}
	
	[timelines release];
	CGPathRelease(theLines);
	[super dealloc];
}

- (void)awakeFromNib
{
	rootLayer = [[CALayer layer] retain];
	[rootLayer setDelegate:self];
	[self setLayer:rootLayer];
	[self setWantsLayer:YES];
	//rootLayer = [self layer];
	
	playheadLayer = nil;		
	
	[rootLayer setNeedsDisplay];
}

-(NSData*)currentState:(NSDictionary*)stateFlags
{
	//NSLog(@"MultiTimeline Save State");
	NSMutableArray *timelineStates = [NSMutableArray array];
	
	for(TimelineView *timeline in timelines)
	{
		[timelineStates addObject:[timeline currentState:stateFlags]];
	}
	
	return [NSKeyedArchiver archivedDataWithRootObject:[NSDictionary dictionaryWithObjectsAndKeys:
														timelineStates,@"TimelineStates",
														[NSNumber numberWithFloat:timelineHeight],@"TimelineHeight",												
														nil]];
}

-(BOOL)setState:(NSData*)stateData
{
	//NSLog(@"MultiTimeline Set State");
	NSDictionary *stateDict;
	@try {
		stateDict = [NSKeyedUnarchiver unarchiveObjectWithData:stateData];
	}
	@catch (NSException *e) {
		NSLog(@"Invalid archive, %@", [e description]);
		return NO;
	}
	
	NSArray *timelineStates = [stateDict objectForKey:@"TimelineStates"];
	[self setTimelineHeight:[[stateDict objectForKey:@"TimelineHeight"] floatValue]];
	
	for(TimelineView* timeline in timelines)
	{
		[timeline removeObserver:self
					  forKeyPath:@"annotationFilter"];
		[timeline removeFromSuperviewWithoutNeedingDisplay];
		[timeline setSuperTimelineView:nil];
	}
	[timelines removeAllObjects];
	
	NSMutableArray *theTimelines = [NSMutableArray arrayWithCapacity:[timelineStates count]];
	NSRect timelineFrame = [self frame];
	timelineFrame.origin.y = 0;
	timelineFrame.size.height = timelineHeight;
	
	for(NSData* state in timelineStates)
	{
		TimelineView *timeline = [[TimelineView alloc] initWithFrame:timelineFrame];
		[timeline setMovie:[[AppController currentApp] movie]];
		[timeline setState:state];
		[timeline addAnnotations:annotations];
		[theTimelines addObject:timeline];
		[timeline release];
	}
	
	[self addTimelines:theTimelines];
		
	activeTimeline = nil;
	
	return YES;
}


- (void)resetCursorRects
{
	if([[AppController currentApp] currentTool] == DataPrismZoomTool)
	{
		[self addCursorRect:[self bounds] cursor:magnifyCursor];	
	}
	else
	{
		[self addCursorRect:[self bounds] cursor:[NSCursor arrowCursor]];
	}
}

- (BOOL)wrappedTimelines
{
    return wrappedTimelines;
}

- (void)setWrappedTimelines:(BOOL)wrapTimelines
{
    wrappedTimelines = wrapTimelines;
    [self setRange:range];
}

- (TimelineView*)baseTimeline
{
	return [timelines objectAtIndex:0];
}

- (NSArray*)timelines
{
	return [[timelines copy] autorelease];
}

- (int)maxTimelines
{
    if(self.maximumHeight == FLT_MAX)
    {
        return INT_MAX;
    }
    else
    {
       return floor((self.maximumHeight + interTimelineSpace) / (MIN_TIMELINE_HEIGHT + interTimelineSpace)); 
    }
}

- (void)setActiveTimeline:(TimelineView *)timeline
{
	activeTimeline = timeline;
}

- (TimelineView*)activeTimeline
{
	if(!activeTimeline || ![timelines containsObject:activeTimeline])
	{
		activeTimeline = [timelines objectAtIndex:0];
	}
	return activeTimeline;
}

- (void)setFrame:(NSRect)boundsRect
{		
	[super setFrame:boundsRect];
	[self layoutTimelines];
	
	
	/*
	[CATransaction flush];
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	[self redrawAllSegments];
	
	[CATransaction commit];
	
	[playheadLayer setNeedsDisplay];
	//NSLog(@"New Bounds Width: %f",boundsRect.size.width);
	 */
}

- (TimelineView *)addNewKeyframeTimeline:(id)sender;
{
	TimelineView *timeline = [self addNewTimeline];
	AnnotationFilmstripVisualizer *viz = [[AnnotationFilmstripVisualizer alloc] initWithTimelineView:timeline];
	
	VideoProperties *video = [sender representedObject];
	if(video)
	{
		[viz setVideoProperties:video];
	}
	
	[timeline setSegmentVisualizer:viz];
	[viz release];
	return timeline;
}

- (TimelineView *)addNewAudioTimeline:(id)sender
{	
	TimelineView *timeline = [self addNewTimeline];
	AudioVisualizer *viz = [[AudioVisualizer alloc] initWithTimelineView:timeline];
	
	VideoProperties *video = [sender representedObject];
	if(video)
	{
		[viz setVideoProperties:video];
	}
	
	[timeline setSegmentVisualizer:viz];
	[viz release];
	return timeline;
}

- (TimelineView *)addNewDataTimeline:(id)sender;
{
	TimelineView *timeline = [self addNewTimeline];
	id vizType = [sender representedObject];
	if(vizType && ([vizType isKindOfClass:[TimeSeriesData class]]))
	{
		[timeline visualizeData:sender];
//		TimeSeriesVisualizer *viz = [[TimeSeriesVisualizer alloc] initWithTimelineView:timeline];
//		[viz setData:vizType];
//		[timeline setSegmentVisualizer:viz];
//		[viz release];
	}
	else
	{
		[timeline visualizeData:nil];
	}
	return timeline;
}

- (TimelineView *)addNewAnnotationTimeline:(id)sender;
{
	TimelineView *timeline = [self addNewTimeline];
	AnnotationVisualizer *viz = [[AnnotationVisualizer alloc] initWithTimelineView:timeline];
	[timeline setSegmentVisualizer:viz];
	[viz release];
	return timeline;
}

- (TimelineView *)addNewTimeline;
{
	TimelineView *timeline = [[TimelineView alloc] initWithFrame:[[self baseTimeline] frame]];
	[timeline setMovie:[[AppController currentApp] movie]];
	[timeline setRange:range];
	[timeline addAnnotations:annotations];
	[self addTimeline:timeline];
	[timeline release];
	return timeline;
}

- (BOOL)addTimelines:(NSArray*)timelineArray
{
	return [self addTimelines:timelineArray atIndex:[timelines count]];
}

- (BOOL)addTimelines:(NSArray*)timelineArray atIndex:(NSUInteger)index;
{
    
    BOOL success = YES;
    
	for(TimelineView *timeline in timelineArray)
	{
        if([timelines count] < [self maxTimelines])
        {        
            [timelines insertObject:timeline atIndex:index];
            [timeline setSuperTimelineView:self];
            [timeline setRange:[self range]];
            [timeline setAutoresizingMask:(NSViewWidthSizable | NSViewMinXMargin | NSViewMaxXMargin)];
            [self addSubview:timeline];
            index++;
            
            [timeline addObserver:self
                        forKeyPath:@"annotationFilter"
                           options:0
                           context:NULL];
        }
        else
        {
            success = NO;
            break;
        }
	}
	
	[[AppController currentApp] resizeTimelineView];
    
    return success;
}

- (BOOL)addTimeline:(TimelineView*)timeline
{
	return [self addTimeline:timeline atIndex:[timelines count]];
}

- (BOOL)addTimeline:(TimelineView*)timeline aboveTimeline:(TimelineView*)existingTimeline
{
	NSUInteger index = [timelines indexOfObject:existingTimeline];
	if(index == NSNotFound)
	{
		index = [timelines count];
	}
	return [self addTimeline:timeline atIndex:index + 1];
}

- (BOOL)addTimeline:(TimelineView*)timeline atIndex:(NSUInteger) index
{
	return [self addTimelines:[NSArray arrayWithObject:timeline] atIndex:index];
}

- (void)removeTimeline:(TimelineView*)timeline
{
	if([timelines count] > 1)
	{
		[timeline removeObserver:self
					  forKeyPath:@"annotationFilter"];
		
		[timeline removeFromSuperviewWithoutNeedingDisplay];
		[timeline setSuperTimelineView:nil];
		if(timeline == [[self baseTimeline] subTimelineView])
		{
			[[self baseTimeline] setSubTimelineView:nil];
		}

		[timelines removeObject:timeline];
		
		[[AppController currentApp] resizeTimelineView];
		
		activeTimeline = nil;
		
		//[self layoutTimelines];		
	}
}

- (void)removeHighestTimeline
{
	[self removeTimeline:[timelines lastObject]];	
}

- (void)replaceTimeline:(TimelineView*)oldTimeline withTimeline:(TimelineView*)newTimeline
{
	if(oldTimeline != [self baseTimeline])
	{
		NSUInteger index = [timelines indexOfObject:oldTimeline];
		if(index != NSNotFound)
		{
			[oldTimeline removeFromSuperviewWithoutNeedingDisplay];
			[oldTimeline setSuperTimelineView:nil];
			[timelines removeObject:oldTimeline];
			[self addTimeline:newTimeline atIndex:index];
			
			activeTimeline = nil;
		}
	}
}

- (void)replaceHighestTimelineWithTimeline:(TimelineView*)timeline
{
	if([timelines count] > 1)
	{
		[self replaceTimeline:[timelines lastObject] withTimeline:timeline];
	}
	
//	{
//		[(TimelineView*)[timelines lastObject] removeFromSuperviewWithoutNeedingDisplay];
//		[[timelines lastObject] setSuperTimelineView:nil];
//		[timelines removeObject:[timelines lastObject]];
//	}
//	[self addTimeline:timeline];
	
}

- (void)layoutTimelines
{
	NSUInteger numTimelines = [timelines count];
	
	float height = [self frame].size.height;
	
	float newTimelineHeight = (height - ((numTimelines - 1.0) * interTimelineSpace))/numTimelines;
	if([self inLiveResize] || [[AppController currentApp] animating] || (fabs(newTimelineHeight- timelineHeight) > 5))
	{
		timelineHeight = newTimelineHeight; 
	}
	//float timelineHeight = (height - ((numTimelines - 1.0) * interTimelineSpace))/numTimelines;
	
	float bottom = 0;
	CGPathRelease(theLines);
	theLines = CGPathCreateMutable();
	TimelineView *previous = nil;
	for(TimelineView *timeline in timelines)
	{
		NSRect frame = [timeline frame];
		if(timeline != draggingTimeline)
		{
			frame.size.height = timelineHeight;
			frame.origin.y = bottom;
			[timeline setFrame:frame];
		}
		
		if(previous)
		{
			[timeline showTimes:NO];
		}
		else
		{
			[timeline showTimes:YES];
		}
		
		if(previous && [timeline basisAnnotation])
		{
			CGFloat left = [previous pointFromTime:[timeline range].start].x;
			CGFloat right = [previous pointFromTime:CMTimeRangeGetEnd([timeline range])].x;
			
//			CGPathMoveToPoint(theLines, NULL, frame.size.width/2 - 20, bottom - (interTimelineSpace));
//			CGPathAddCurveToPoint(theLines, NULL, frame.size.width/2 - 20, bottom - (interTimelineSpace/2), 0, bottom - (interTimelineSpace/2), 0, bottom);
//			CGPathMoveToPoint(theLines, NULL, frame.size.width/2 + 20, bottom - (interTimelineSpace));
//			CGPathAddCurveToPoint(theLines, NULL, frame.size.width/2 + 20, bottom - (interTimelineSpace/2), frame.size.width, bottom - (interTimelineSpace/2), frame.size.width, bottom);
			
			CGPathMoveToPoint(theLines, NULL, left, bottom - (interTimelineSpace));
			CGPathAddCurveToPoint(theLines, NULL, left, bottom - (interTimelineSpace/2), 0, bottom - (interTimelineSpace/2), 0, bottom);
			CGPathMoveToPoint(theLines, NULL, right, bottom - (interTimelineSpace));
			CGPathAddCurveToPoint(theLines, NULL, right, bottom - (interTimelineSpace/2), frame.size.width, bottom - (interTimelineSpace/2), frame.size.width, bottom);
		}
		bottom += timelineHeight + interTimelineSpace;
		previous = timeline;
	}
	[self setNeedsLayout:NO];
	[rootLayer setNeedsDisplay];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{	
	CGRect boundingBox = CGContextGetClipBoundingBox(ctx);
	//NSLog(@"Draw Layer");
	NSGraphicsContext *nsGraphicsContext;
	nsGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx
																   flipped:NO];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:nsGraphicsContext];
	
	//NSRect bounds = [self bounds];
	NSRect bounds = NSRectFromCGRect(boundingBox);
	
	//NSLog(@"draw background");
	[backgroundGradient drawInRect:bounds angle:270];
	
	[NSGraphicsContext restoreGraphicsState];
	
	CGContextBeginPath(ctx);
	CGContextAddPath(ctx, theLines );
	CGContextSetRGBStrokeColor(ctx, 0.8f, 0.8f, 0.8f, 1.0f);
	CGContextSetLineWidth(ctx, 2.0f);
	CGContextStrokePath(ctx);
	
	[self updatePlayheadPosition];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"annotationFilter"]) {
		
		NSLog(@"update filter");
		
		NSMutableArray *predicates = [NSMutableArray array];
		
		for(TimelineView *timeline in timelines)
		{
			AnnotationFilter *theFilter = [timeline annotationFilter];
			if(theFilter)
			{
				[predicates addObject:[theFilter predicate]];
			}
		}
		
		if([predicates count] > 0)
		{
			AnnotationFilter *filter = [[AnnotationFilter alloc] initWithPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:predicates]];
			[self setAnnotationFilter:filter];
			[filter release];	
		}
    }
	else
	{
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
	}
}

#pragma mark TimelineView Methods

-(void)reset
{
	//NSLog(@"Multitimeline reset");
	[super reset];
	
	TimelineView *baseTimeline = [[self baseTimeline] retain];
	
	for(TimelineView* timeline in timelines)
	{
		[timeline removeObserver:self
					  forKeyPath:@"annotationFilter"];
		
		[timeline removeFromSuperviewWithoutNeedingDisplay];
	}
	[timelines removeAllObjects];
	
	[baseTimeline reset];
	[self addTimeline:baseTimeline];
	
	[baseTimeline release];
}

- (void)setMovie:(AVPlayer *)mov
{
	[super setMovie:mov];
	
	for(TimelineView* timeline in timelines)
	{
		[timeline setMovie:mov];
	}
	
}

- (void)setRange:(CMTimeRange)theRange
{
	range = theRange;
    
    if(!wrappedTimelines)
    {    
        for(TimelineView *timeline in timelines)
        {
            if(![timeline basisAnnotation])
            {
                [timeline setRange:theRange];
            }
        }
    }
    else
    {
        NSTimeInterval totalDuration = 0;
        totalDuration = CMTimeGetSeconds(range.duration);
        CMTime timelineDuration = CMTimeMake(totalDuration/(CGFloat)[timelines count], 1000000); // TODO: Check if the timescale is correct.
        
        CMTime start = range.start;
        for(TimelineView *timeline in timelines)
        {
            CMTimeRange timelineRange = CMTimeRangeMake(start, timelineDuration);
            start = CMTimeAdd(start, timelineDuration);
            [timeline setRange:timelineRange];
        }
    }
	[self layoutTimelines];
}

- (SegmentVisualizer *)segmentVisualizer
{
	return [[timelines objectAtIndex:0] segmentVisualizer];
}

- (void)setSegmentVisualizer:(SegmentVisualizer *)visualizer
{
	[[timelines objectAtIndex:0] setSegmentVisualizer:visualizer];
}

- (void)setFilterAnnotations:(BOOL)filter
{
	filterAnnotations = filter;
	for(TimelineView *timeline in timelines)
	{
		if(timeline != [self baseTimeline])
		{
			[timeline setFilterAnnotations:filter];
		}
	}
}

-(void)setAnnotationFilter:(AnnotationFilter*)filter
{
	[filter retain];
	[annotationFilter release];
	annotationFilter = filter;
}

-(AnnotationFilter*)annotationFilter
{
	return annotationFilter;
}

- (void)showAnnotation:(Annotation*)annotation
{
	if(![annotationFilter shouldShowAnnotation:annotation])
	{
		AnnotationFilter *activeFilter = [[self activeTimeline] annotationFilter];
		if([activeFilter isKindOfClass:[AnnotationCategoryFilter class]])
		{
			AnnotationCategoryFilter *filter = (AnnotationCategoryFilter*)activeFilter;
			[filter showCategory:[annotation category]];
			[[self activeTimeline] setAnnotationFilter:filter];
		}
	}
}

-(void)addAnnotation:(Annotation*)annotation
{
	if(![annotations containsObject:annotation])
	{
		[annotations addObject:annotation];
		for(TimelineView *timeline in timelines)
		{
			[timeline addAnnotation:annotation];
		}
	}
}

-(void)addAnnotations:(NSArray*)array
{
	//NSLog(@"Add Annotations: %i",[array count]);
	for(Annotation* annotation in array)
	{
		[self addAnnotation:annotation];
	}
}

-(void)removeAnnotation:(Annotation*)annotation
{
	[annotations removeObject:annotation];
	for(TimelineView *timeline in timelines)
	{
		[timeline removeAnnotation:annotation];
	}
}

-(void)updateAnnotation:(Annotation*)annotation
{
	for(TimelineView *timeline in timelines)
	{
		[timeline updateAnnotation:annotation];
	}
	
}

-(NSArray*)dataSets
{
	NSMutableArray *combinedDataSets = [NSMutableArray array];
	for(TimelineView *timeline in timelines)
	{
		[combinedDataSets addObjectsFromArray:[timeline dataSets]];
	}
	return combinedDataSets;	
}

- (BOOL)removeData:(TimeCodedData*)theData
{
	BOOL success = NO;
	if([theData isKindOfClass:[TimeSeriesData class]])
	{
		NSArray* tempTimelines = [timelines copy];
		for(TimelineView *timeline in tempTimelines)
		{
			if([[timeline dataSets] containsObject:theData])
			{
				[timeline removeData:theData];
				success = YES;	
				
				if([[timeline dataSets] count] == 0)
				{
					[self removeTimeline:timeline];	
				}
			}
		}
		[tempTimelines release];
	}
	return success;
}

- (void)redrawAllSegments
{
//	[rootLayer setNeedsDisplay];
//	for(TimelineView *timeline in timelines)
//	{
//		[timeline redrawAllSegments];
//	}
}

- (void)redrawSegments
{	
	[rootLayer setNeedsDisplay];
	for(TimelineView *timeline in timelines)
	{
		[timeline redrawSegments];
	}
}

- (void)redraw
{
	[CATransaction flush];
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	for(TimelineView *timeline in timelines)
	{
		[timeline updatePlayheadPosition];
	}	
	[CATransaction commit];
}

-(void)setResizing:(BOOL)inprogress
{
	[super setResizing:inprogress];
	for(TimelineView *timeline in timelines)
	{
		[timeline setResizing:inprogress];
		if(!inprogress)
		{
			[timeline viewDidEndLiveResize];
		}
	}	
}

-(void)viewDidEndLiveResize
{
	// Override so that it doesn't get sent twice
	// (Once by each timeline, then once by the multitimeline)
}

- (void)updatePlayheadPosition
{
	for(TimelineView *timeline in timelines)
	{
		[timeline updatePlayheadPosition];
	}		
}

#pragma mark Mouse Event Override
- (void)mouseDown:(NSEvent *)theEvent
{
	if(draggingTimeline)
	{
		[[draggingTimeline layer] setZPosition:5];
		[[draggingTimeline layer] setOpacity:0.8];
		NSPoint pt = [draggingTimeline convertPoint:[theEvent locationInWindow] fromView:nil];
		dragOffset = pt.y;
		
		[self setResizing:YES];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if(draggingTimeline)
	{
		NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		pt.y = pt.y - dragOffset;
		pt.x = [draggingTimeline frame].origin.x;
		[draggingTimeline setFrameOrigin:pt];
		
		NSInteger index = floorf((pt.y + timelineHeight/2) / (timelineHeight + interTimelineSpace));
		if(index < 0)
		{
			index = 0;
		}
		else if(index >= [timelines count])
		{
			index = [timelines count] - 1;
		}
		NSUInteger currentIndex = [timelines indexOfObject:draggingTimeline];
		if(index != currentIndex)
		{
			[draggingTimeline retain];
			[timelines removeObjectAtIndex:currentIndex];
			[timelines insertObject:draggingTimeline atIndex:index];
			[draggingTimeline release];
			[self layoutTimelines];
		}
	}
}

-(void)mouseUp:(NSEvent *)theEvent
{
	if(draggingTimeline)
	{
		[self setResizing:NO];
		[[draggingTimeline layer] setZPosition:0];
		[[draggingTimeline layer] setOpacity:1.0];
		[self setDraggingTimeline:nil];
		[self layoutTimelines];
	}
}

- (void)cursorUpdate:(NSEvent *)event 
{
	if([[AppController currentApp] currentTool] == DataPrismZoomTool)
	{
		[magnifyCursor set];
	}
	else
	{
		[[NSCursor arrowCursor] set];
	}
}

- (void)rightMouseDown:(NSEvent *)event {}

- (void)mouseEntered:(NSEvent *)theEvent{}

- (void)mouseExited:(NSEvent *)theEvent {}

- (void)mouseMoved:(NSEvent *)theEvent {}

@end
