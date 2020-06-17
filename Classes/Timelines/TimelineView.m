//
//  TimelineView.m
//  Annotation
//
//  Created by Adam Fouse on 1/22/09.
//  Copyright 2009 Adam Fouse. All rights reserved.
//

#import "TimelineView.h"
#import "SegmentBoundary.h"
#import "TimelineMarker.h"
#import "DPConstants.h"
#import "TimeVisualizer.h"
#import "DateVisualizer.h"
#import "AnnotationFilmstripVisualizer.h"
#import "AnnotationTimeSeriesVisualizer.h"
#import "TimeSeriesVisualizer.h"
#import "MultipleTimeSeriesVisualizer.h"
#import "ColorMappedTimeSeriesVisualizer.h"
#import "AudioVisualizer.h"
#import "LayeredVisualizer.h"
#import "TimeSeriesData.h"
#import "Annotation.h"
#import "AnnotationFilter.h"
#import "AnnotationCategoryFilter.h"
#import "TimelinePlayhead.h"
#import "MultiTimelineView.h"
#import "AnnotationDocument.h"
#import "AppController.h"
#import "VideoProperties.h"
#import "DataSource.h"
#import "AnnotationFiltersController.h"
#import "NSImage-Extras.h"
#import "NSMenuPopUpMenu.h"
#import "DPExportMovieClips.h"
#import "DPExportFrameImages.h"

@implementation TimelineView

@synthesize resizing;
@synthesize showActionButtons;
@synthesize clickToMovePlayhead;
@synthesize recordClickPosition;
@synthesize linkedToMovie;
@synthesize linkedToMouse;
@synthesize range;
@synthesize label;
@synthesize highlightedMarker;
@synthesize superTimelineView;
@synthesize subTimelineView;
@synthesize visualizationLayer;
@synthesize annotationsLayer;
@synthesize timesLayer;
@synthesize visualizeMultipleTimeSeries;
@synthesize whiteBackground;

#pragma mark Initialization

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {	
		superTimelineView = nil;
		
		backgroundColor = [NSColor grayColor];
		backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.7 alpha:1.0] 
														   endingColor:[NSColor colorWithDeviceWhite:0.5 alpha:1.0]];

		borderColor = [NSColor blackColor];
		//playheadColor = [[NSColor colorWithDeviceWhite:0.25 alpha:0.5] retain];
		playheadColor = [[NSColor colorWithDeviceRed:1.0 green:0.8 blue:0.4 alpha:0.5] retain];
		playheadWidth = 15;
		
		clickToMovePlayhead = YES;
		showPlayhead = YES;
		playheadPosition = 0;
		//clickToMovePlayhead = [[NSUserDefaults standardUserDefaults] boolForKey:AFClickToMovePlayheadKey];
		
		movingLeftMarker = NO;
		movingRightMarker = NO;
		draggingTimelineMarker = nil;
		
		[self setLinkedToMovie:YES];
		[self setLinkedToMouse:NO];
		[self setShowPlayhead:YES];
		[self setResizing:NO];
		[self setShowActionButtons:YES];
		
		setup = NO;
		filterAnnotations = NO;
		annotationFilter = nil;
		
		dataSets = [[NSMutableArray alloc] init];
		
		annotations = [[NSMutableArray alloc] init];
		segmentVisualizer = nil;
		selectedMarker = nil;
		movie = nil;
		basisAnnotation = nil;
		contextualObjects = nil;
		labelLayer = nil;

        whiteBackground = NO;
        
		timePoints = [[NSMutableArray alloc] init];
		snapThreshold = 600;
		
		magnifyCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"MagnifyingGlassGray.png"]
												hotSpot:NSMakePoint(7, 10)];
		
		[self setRange:CMTimeRangeMake(CMTimeMake(0,600),CMTimeMake(600,600))];
    }
    return self;
}

- (void)awakeFromNib
{
	[self setup];
}

-(void)setup
{
	if(!setup)
	{
		timeSeriesVisualizerClass = [TimeSeriesVisualizer class];
		
		[[AppController currentApp] addObserver:self forKeyPath:@"selectedAnnotation" options:0 context:nil];
		[self addObserver:self forKeyPath:@"range" options:0 context:nil];
		[self addObserver:self forKeyPath:@"label" options:0 context:nil];
		
		rootLayer = [[CALayer layer] retain];
		rootLayer.frame = CGRectMake(0,0,[self frame].size.width,[self frame].size.height);
		//rootLayer = [[CATiledLayer layer] retain];
		//((CATiledLayer*)rootLayer).tileSize = CGSizeMake(1024, 512);
		rootLayer.shadowOpacity = 0.8;
		[rootLayer setDelegate:self];
		[self setLayer:rootLayer];
		[self setWantsLayer:YES];
		[self showTimes:NO];
		
		visualizationLayer = [[CALayer layer] retain];
		visualizationLayer.anchorPoint = CGPointMake(0, 0);
		visualizationLayer.frame = CGRectMake(0,0,[self frame].size.width,[self frame].size.height);
		[rootLayer addSublayer:visualizationLayer];
		// For an unknown reason, the using autoresizing doesn't work correctly, so the visualizationLayer
		// is resized in setFrame
		// visualizationLayer.autoresizingMask = (kCALayerHeightSizable | kCALayerWidthSizable);
		
		
        annotationsLayer = [[CALayer layer] retain];
        [annotationsLayer setMasksToBounds:YES];
		annotationsLayer.anchorPoint = CGPointMake(0, 0);
		annotationsLayer.frame = CGRectMake(0,0,[self frame].size.width,[self frame].size.height);
		[rootLayer addSublayer:annotationsLayer];
        
		selectionMask = [[CALayer layer] retain];
		selectionMask.backgroundColor = CGColorCreateGenericGray(0.8, 0.5);
		
		playheadLayer = [[CALayer layer] retain];
		playheadLayer.anchorPoint = CGPointMake(0.5, 0.0);
		playheadLayer.bounds = CGRectMake(0.0, 0.0, playheadWidth, rootLayer.bounds.size.height);
		playheadLayer.position = CGPointMake(0, 0);
		playhead = [[TimelinePlayhead alloc] initWithLayer:playheadLayer];
		[rootLayer addSublayer:playheadLayer];
		[playheadLayer setNeedsDisplay];
		
		// setup some shared values for the navigation buttons
		CGColorRef bgColor = CGColorCreateGenericRGB( 1, 1, 1, 0.6 );
		CGColorRef shadowColor = CGColorCreateGenericRGB( 0.2, 0.2, 0.2, 1 );
		CGRect buttonContainer = CGRectMake( 0, 0, 70, 60 );
		CGRect navButtonBounds = CGRectMake( 0, 0, 60, 50 );
		CGRect actionIconBounds = CGRectMake( 0, 0, 25, 25 );
		
		
		// Create controls layer
        
		actionLayer = [[CALayer layer] retain];
		actionLayer.delegate = self;
		
		NSImage* actionNSImage = [NSImage imageNamed:NSImageNameActionTemplate];
		CGImageRef actionImage = [actionNSImage cgImage];
		
		NSImage* listNSImage = [NSImage imageNamed:NSImageNameListViewTemplate];
		CGImageRef listImage = [listNSImage cgImage];
		
		
		// setup control pop-up layer
		
		actionLayer.bounds               = buttonContainer;
		actionLayer.masksToBounds		 = YES;
		actionLayer.anchorPoint          = CGPointMake( 0.0, 0.0 );
		actionLayer.position             = CGPointMake( [self bounds].size.width - actionLayer.bounds.size.width - 8.0, 
													   [self bounds].size.height - actionLayer.bounds.size.height );
		actionLayer.hidden               = YES;
		
		CALayer *actionLayerBackground = [CALayer layer];
		actionLayerBackground.bounds               = navButtonBounds;
		actionLayerBackground.cornerRadius         = 12.0;
		actionLayerBackground.anchorPoint          = CGPointMake( 0.0, 0.0 );
		actionLayerBackground.position             = CGPointMake( 2.0, [actionLayer bounds].size.height - 25 );
		actionLayerBackground.backgroundColor      = bgColor;
		actionLayerBackground.shadowOffset         = CGSizeMake( 3, -3 );
		actionLayerBackground.shadowOpacity        = 0.6;
		
		[actionLayer addSublayer:actionLayerBackground];
		
		
		listLayer = [[CALayer layer] retain];
		listLayer.bounds				= actionIconBounds;
		listLayer.anchorPoint			= CGPointMake( 0.0, 0.0 );
		listLayer.position				= CGPointMake( 5.0, 0.0 );
		listLayer.shadowColor			= shadowColor;
		listLayer.shadowOffset			= CGSizeMake( 0, 0 );
		listLayer.shadowOpacity			= 0;
		listLayer.shadowRadius			= 5.0;
		listLayer.contentsGravity		= kCAGravityCenter;
		listLayer.contents				= (id)listImage;
		
		menuLayer = [[CALayer layer] retain];
		menuLayer.bounds				= actionIconBounds;
		menuLayer.anchorPoint			= CGPointMake( 0.0, 0.0 );
		menuLayer.position				= CGPointMake( 30.0, 0.0 );
		menuLayer.shadowColor			= shadowColor;
		menuLayer.shadowOffset			= CGSizeMake( 0, 0 );
		menuLayer.shadowOpacity			= 0;
		menuLayer.shadowRadius			= 5.0;
		menuLayer.contentsGravity		= kCAGravityCenter;
		menuLayer.contents				= (id)actionImage;
		
		[actionLayerBackground addSublayer:listLayer];
		[actionLayerBackground addSublayer:menuLayer];
		
		[rootLayer addSublayer:actionLayer];
		
		CGColorRelease ( bgColor );
		CGColorRelease ( shadowColor );
		CGImageRelease ( actionImage );
		
		[rootLayer setNeedsDisplay];

		setup = YES;
	}
}

-(void)reset
{
	[self setSelected:nil];
	[annotations removeAllObjects];
	[dataSets removeAllObjects];
	[self setAnnotationFilter:nil];
	[self redrawAllSegments];
}

- (void)dealloc
{
	[[AppController currentApp] removeObserver:self	forKeyPath:@"selectedAnnotation"];
	[self removeObserver:self forKeyPath:@"label"];
	[self removeObserver:self forKeyPath:@"range"];
	if(basisAnnotation)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}
	
	[segmentVisualizer release];
	[timesVisualizer release];
	[backgroundGradient release];
	[playheadColor release];
	[playheadLayer release];
	
	[rootLayer release];
	[visualizationLayer release];
    [annotationsLayer release];
	[actionLayer release];
	[labelLayer release];
	[listLayer release];
	[menuLayer release];
	[selectionMask release];
	
	[playhead release];
	if(movie)
		[movie release];
	[annotations release];
	[dataSets release];
	[magnifyCursor release];
	
	[contextualObjects release];
	
	[super dealloc];
}

- (void)removeFromSuperTimeline
{
    if([[[AppController currentApp] annotationFiltersController] currentAnnotationView] == self)
    {
        [[[AppController currentApp] annotationFiltersController] closeWindowAction:self];
    }
    
	if(superTimelineView)
	{
		[(MultiTimelineView*)superTimelineView removeTimeline:self];
	}
}

- (BOOL)setRangeFromBeginTime:(CMTime)begin andEndTime:(CMTime)end
{
	if(CMTimeCompare(begin, end) == NSOrderedAscending)
	{
		CMTimeRange newRange = CMTimeRangeMake(begin, CMTimeSubtract(end, begin));
		if(!CMTimeRangeEqual(range, newRange))
		{
			[self setRange:newRange];
			return YES;
		}
	}
	return NO;
}

- (void)updateRange
{
	if(![basisTimeline resizingAnnotation])
	{
		Annotation *annotation = basisAnnotation;
		BOOL change = [self setRangeFromBeginTime:[annotation startTime] andEndTime:[annotation endTime]];
		if(change)
			[[[AppController currentApp] timelineView] layoutTimelines];
	}
	
}

- (void)setBasisMarker:(TimelineMarker*)marker
{
	Annotation *annotation = [marker annotation];
	if(annotation && [annotation isDuration])
	{
		if(basisAnnotation)
		{
			[[NSNotificationCenter defaultCenter] removeObserver:self];
		}
		basisAnnotation = annotation;
		basisTimeline = [marker timeline];
		[self setRangeFromBeginTime:[annotation startTime] andEndTime:[annotation endTime]];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateRange)
													 name:AnnotationUpdatedNotification
												   object:annotation];
	}
}

-(Annotation*)basisAnnotation
{
	return basisAnnotation;
}


- (void)setMovie:(AVPlayer *)mov
{
	[self setSelected:nil];
	[mov retain];
	[movie release];
	movie = mov;
	
    if(timesVisualizer)
    {
        [self showTimes:NO];
        [self showTimes:YES];
    }
    
	[self setRange:CMTimeRangeMake(kCMTimeZero, [[movie currentItem] duration])];
	
	[self redrawAllSegments];
}

- (AVPlayer*)movie
{
	return movie;
}

-(NSData*)currentState:(NSDictionary*)stateFlags
{
	NSString *visualizerClass = [segmentVisualizer className];
	
	NSString *secondVisualizerClass;
	if([segmentVisualizer isKindOfClass:[LayeredVisualizer class]])
	{
		secondVisualizerClass = [[(LayeredVisualizer*)segmentVisualizer dataVisualizer] className];
	}
	else
	{
		secondVisualizerClass = @"";
	}
	
	NSString *timelineLabel;
	if([self label])
	{
		timelineLabel = [self label];;
	}
	else
	{
		timelineLabel = @"";
	}
	
    NSMutableArray *dataSetIDs = [NSMutableArray array];
    for(TimeSeriesData *dataSet in dataSets)
	{
		[dataSetIDs addObject:[dataSet uuid]];
	}
	
//	NSMutableArray *dataSetNames = [NSMutableArray array];
//	for(TimeSeriesData *dataSet in dataSets)
//	{
//		[dataSetNames addObject:[dataSet name]];
//	}
	
//	NSString *dataSetName;
//	if([dataSets count] > 0)
//	{
//		dataSetName = [[dataSets objectAtIndex:0] name];
//	}
//	else
//	{
//		dataSetName = @"";
//	}
	
	NSObject *filter;
	if(annotationFilter)
	{
		filter = annotationFilter;
	}
	else
	{
		filter = [NSNull null];
	}
	
    NSObject *vizVideoID;
	if([segmentVisualizer videoProperties])
	{
		vizVideoID = [[segmentVisualizer videoProperties] uuid];
	}
	else
	{
		vizVideoID = [NSNull null];
	}
    
	NSObject *vizVideo;
	if([segmentVisualizer videoProperties])
	{
		vizVideo = [[segmentVisualizer videoProperties] title];
	}
	else
	{
		vizVideo = [NSNull null];
	}
		
	NSNumber *showLabels;
	NSNumber *alignCategories;
	
	if([segmentVisualizer isKindOfClass:[AnnotationVisualizer class]])
	{
		showLabels = [NSNumber numberWithBool:[(AnnotationVisualizer*)segmentVisualizer drawLabels]];
		alignCategories = [NSNumber numberWithBool:[(AnnotationVisualizer*)segmentVisualizer lineUpCategories]];
	}
	else
	{
		showLabels = [NSNumber numberWithBool:NO];
		alignCategories = [NSNumber numberWithBool:NO];
	}
	
	return [NSKeyedArchiver archivedDataWithRootObject:[NSDictionary dictionaryWithObjectsAndKeys:
														dataSetIDs,@"DataSetIDs",
														visualizerClass,@"VisualizerClass",
														secondVisualizerClass,@"SecondVisualizerClass",		
														filter,@"AnnotationFilter",
														showLabels,@"ShowLabels",
														alignCategories,@"AlignCategories",
														vizVideo,@"VisualizerVideo",
                                                        vizVideoID,@"VisualizerVideoID",
														timelineLabel,@"TimelineLabel",
														nil]];
}

-(BOOL)setState:(NSData*)stateData
{
	NSDictionary *stateDict;
	@try {
		stateDict = [NSKeyedUnarchiver unarchiveObjectWithData:stateData];
	}
	@catch (NSException *e) {
		NSLog(@"Invalid archive, %@", [e description]);
		return NO;
	}
	
	[dataSets removeAllObjects];
	
    NSArray *dataSetIDs = [stateDict objectForKey:@"DataSetIDs"];
    
    if(!dataSetIDs)
    {
        // Look for older tags for backward compatibility
        
        NSArray* dataSetNames = [stateDict objectForKey:@"DataSetNames"];
        
        // Older versions included a single data set name
        if(!dataSetNames)
        {
            NSString* storedDataSetName = [stateDict objectForKey:@"DataSetName"];
            if([storedDataSetName length] > 0)
            {
                dataSetNames = [NSArray arrayWithObject:storedDataSetName];
            }
        }
        
        for(NSString* dataSetName in dataSetNames)
        {
            for(NSObject* dataSet in [[AnnotationDocument currentDocument] dataSets])
            {
                if([dataSet isKindOfClass:[TimeSeriesData class]] && [[(TimeSeriesData*)dataSet name] isEqualToString:dataSetName])
                {
                    [self addData:(TimeSeriesData*)dataSet];
                    break;
                }
            }
        }
    }
    else
    {
        for(NSString* dataSetID in dataSetIDs)
        {
            for(TimeCodedData* dataSet in [[AnnotationDocument currentDocument] dataSets])
            {
                if([[dataSet uuid] isEqualToString:dataSetID])
                {
                    [self addData:(TimeSeriesData*)dataSet];
                    break;
                }
            }
        }
    }
	
	NSObject *filter = [stateDict objectForKey:@"AnnotationFilter"];
	if(filter != [NSNull null])
	{
		NSLog(@"set annotation filter");
		[self setAnnotationFilter:(AnnotationFilter*)filter];
	}
	
	NSString *timelineLabel = [stateDict objectForKey:@"TimelineLabel"];
	[self setLabel:timelineLabel];
	
    VideoProperties *videoProps = nil;
    NSObject *vizVideoID= [stateDict objectForKey:@"VisualizerVideoID"];
    if(vizVideoID && (vizVideoID != [NSNull null]))
    {
        NSString *videoID = (NSString*)vizVideoID;
        for(VideoProperties* props in [[AnnotationDocument currentDocument] allMediaProperties])
        {
            if([videoID isEqualToString:[props uuid]])
            {
                videoProps = props;
                break;
            }
        }
    }
    
    if(!videoProps)
    {
        NSObject *vizVideo = [stateDict objectForKey:@"VisualizerVideo"];
        if(vizVideo != [NSNull null])
        {
            NSString *videoTitle = (NSString*)vizVideo;
            
            if([videoTitle isEqualToString:[[[AnnotationDocument currentDocument] videoProperties] title]])
            {
                videoProps = [[AnnotationDocument currentDocument] videoProperties];
            }
            else
            {
                for(VideoProperties* props in [[AnnotationDocument currentDocument] mediaProperties])
                {
                    if([videoTitle isEqualToString:[props title]])
                    {
                        videoProps = props;
                        break;
                    }
                }
            }
        }
    }
	
	SegmentVisualizer *viz;
	Class visualizerClass = NSClassFromString([stateDict objectForKey:@"VisualizerClass"]);
	NSString *secondVisualizerClassName = [stateDict objectForKey:@"SecondVisualizerClass"];
	if([secondVisualizerClassName length] > 0)
	{
		NSLog(@"Set Timeline State: Layered Visualizer: %@ %@",[stateDict objectForKey:@"VisualizerClass"],secondVisualizerClassName);
		SegmentVisualizer *secondViz = [[NSClassFromString(secondVisualizerClassName) alloc] initWithTimelineView:self];
		viz = [(LayeredVisualizer*)[visualizerClass alloc] initWithTimelineView:self andSecondVisualizer:secondViz];
		[secondViz release];
	}
	else
	{
		NSLog(@"Set Timeline State: Visualizer: %@ ",[stateDict objectForKey:@"VisualizerClass"]);
		viz = [[visualizerClass alloc] initWithTimelineView:self];
	}
	
	if([viz isKindOfClass:[AnnotationVisualizer class]])
	{
		NSNumber *showLabels = [stateDict objectForKey:@"ShowLabels"];
		NSNumber *alignCategories = [stateDict objectForKey:@"AlignCategories"];
		
		if([showLabels boolValue] != [(AnnotationVisualizer*)viz drawLabels])
		{
			[(AnnotationVisualizer*)viz toggleShowLabels];
		}
		
		if([alignCategories boolValue] != [(AnnotationVisualizer*)viz lineUpCategories])
		{
			[(AnnotationVisualizer*)viz toggleAlignCategories];
		}
	}
	
	[viz setVideoProperties:videoProps];
	
	[self setSegmentVisualizer:viz];
	[viz release];
	[viz updateMarkers];
	
	return YES;
}

-(IBAction)setLabelAction:(id)sender
{
	NSAlert* alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Please enter a new label for the timeline."];
	[alert addButtonWithTitle:@"Set Label"];
	[alert addButtonWithTitle:@"Cancel"];
	
	NSTextField *nameInputField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 22)];
	
	if([self label])
	{
		[nameInputField setStringValue:[self label]];
	}
	else
	{
		[nameInputField setStringValue:@"Timeline"];
	}
	
	[alert setAccessoryView:nameInputField];
	[nameInputField release];
	
	//[[alert window] makeFirstResponder:nameInputField];
	
	[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	[nameInputField selectText:self];
}

-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSTextField *labelField = (NSTextField*)[alert accessoryView];
	if (returnCode == NSAlertFirstButtonReturn) {
		[self setLabel:[labelField stringValue]];
	}
	[alert release];	
}

#pragma mark Drawing

- (void)setFrame:(NSRect)boundsRect
{	
	[super setFrame:boundsRect];
	
	CGFloat edgePadding = 8.0;
	
	//Annotation* selectedAnnotation = [selectedMarker annotation];
	
	if(![self inLiveResize])
	{
		[self resetTrackingAreas];
	}
	
	if(segmentVisualizer || showPlayhead)
	{
		
		//[CATransaction flush];
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];
		

		CGRect vizFrame = visualizationLayer.bounds;
		vizFrame.size.height = boundsRect.size.height;
		vizFrame.size.width = boundsRect.size.width;
		visualizationLayer.bounds = vizFrame;

		annotationsLayer.bounds = vizFrame;
        
		[self redrawAllSegments];
		[playhead setHeight:boundsRect.size.height];
		actionLayer.position = CGPointMake( [self bounds].size.width - actionLayer.bounds.size.width - edgePadding, 
											[self bounds].size.height - actionLayer.bounds.size.height );
		
		[CATransaction commit];
		
	}
		
	[[[AppController currentApp] selectedAnnotation] setSelected:YES];
	
	[playheadLayer setNeedsDisplay];
	//NSLog(@"New Bounds Width: %f",boundsRect.size.width);
	
	[self cursorUpdate:nil];
	
	//NSLog(@"Root layer frame: %f %f %f %f",rootLayer.position.x, rootLayer.position.y, rootLayer.bounds.size.width, rootLayer.bounds.size.height);
	//NSLog(@"Visualization layer frame: %f %f %f %f",visualizationLayer.position.x, visualizationLayer.position.y,visualizationLayer.bounds.size.width, visualizationLayer.bounds.size.height);
}

- (void)resetTrackingAreas
{
	// Reset remnants of segments in this TimelineView
	//NSArray *trackingAreas = [[self trackingAreas] copy];
	for(NSTrackingArea* ta in [self trackingAreas])
	{
		[self removeTrackingArea:ta];
	}
	//[trackingAreas release];
	if(linkedToMouse)
	{
		int options = NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingCursorUpdate | NSTrackingActiveInActiveApp;
		NSTrackingArea *ta;
		ta = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
		[self addTrackingArea:ta];
		[ta release];
	}
	else
	{
		int options = NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingCursorUpdate | NSTrackingActiveInActiveApp;
		NSTrackingArea *ta;
		ta = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
		[self addTrackingArea:ta];
		[ta release];
	}
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	
	if(layer == labelLayer)
	{
		
	}
	else
	{
		CGRect boundingBox = CGContextGetClipBoundingBox(ctx);
		//NSLog(@"Draw layer in context: width %f, x coord %f",boundingBox.size.width,boundingBox.origin.x);
		//NSLog(@"Draw Layer");
		NSGraphicsContext *nsGraphicsContext;
		nsGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx
																	   flipped:NO];
		[NSGraphicsContext saveGraphicsState];
		[NSGraphicsContext setCurrentContext:nsGraphicsContext];
		
		//NSRect bounds = [self bounds];
		NSRect bounds = NSRectFromCGRect(boundingBox);
		
        if(whiteBackground)
        {
            [[NSColor whiteColor] drawSwatchInRect:bounds];
        }
        else
        {
            //NSLog(@"draw background");
            [backgroundGradient drawInRect:bounds angle:270];
        }
		
		[NSGraphicsContext restoreGraphicsState];
		
		[self updatePlayheadPosition];
	}
}


// All drawing should happen directly through Core Animation
// See drawLayer: method
- (void)drawRect:(NSRect)rect { }

-(BOOL)inLiveResize
{
	return (resizing || [super inLiveResize]);
}

-(void)viewDidEndLiveResize
{
	[self resetTrackingAreas];
	
	[super viewDidEndLiveResize];
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	[self redrawAllSegments];
	
	[CATransaction commit];
//	[CATransaction flush];

}

-(void)update
{
	[self redraw];
}

- (void)redraw
{
	if(showPlayhead)
	{
		[self updatePlayheadPosition];
	}
	else
	{
		[playheadLayer setHidden:YES];
		[actionLayer setHidden:YES];
	}	
}


#pragma mark Playhead

- (CALayer*)playheadLayer
{
	return playheadLayer;
}

- (BOOL)showPlayhead
{
    return showPlayhead;
}

- (void)setShowPlayhead:(BOOL)show
{
    showPlayhead = show;
    [playheadLayer setHidden:!showPlayhead];
}

- (double)playheadPosition
{
	if(linkedToMovie && movie)
	{
		NSTimeInterval movieTime = CMTimeGetSeconds([[AppController currentApp] currentTime]);
		NSTimeInterval rangeStart = CMTimeGetSeconds([self range].start);
		NSTimeInterval rangeDuration = CMTimeGetSeconds([self range].duration);
		
		return (movieTime - rangeStart)/rangeDuration;
		
	} else 
	{
		return playheadPosition;
	}
}

- (void)setPlayheadPosition:(double)position
{
	playheadPosition = position;
	[self updatePlayheadPosition];
}

- (void)updatePlayheadPosition
{
	
	CGFloat x = [self playheadPosition] * [self bounds].size.width;	
	
//	if(x < 0)
//		x = 0;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	[playheadLayer setPosition:CGPointMake(x, [playheadLayer position].y)];
	
	[CATransaction commit];
}


#pragma mark Visualization

- (void)setSegmentVisualizer:(SegmentVisualizer *)visualizer
{
	
	if(!setup)
		[self setup];
	
	[visualizer retain];
	
	//[self setWantsLayer:YES];
		
	[playhead setBounds:CGRectMake(0.0, 0.0, playheadWidth, [self bounds].size.height)];
	//[rootLayer addSublayer:playheadLayer];

	[self resetTrackingAreas];
	
	[segmentVisualizer release];
	[self setSelected:nil];
	
	segmentVisualizer = visualizer;
	
	[segmentVisualizer setup];
	[self redrawSegments];
}

- (SegmentVisualizer *)segmentVisualizer
{
	return segmentVisualizer;
}


- (void)redrawAllSegments
{
	BOOL updated = NO;
	
	[timesVisualizer updateMarkers];
	
	if([segmentVisualizer autoSegments] || ([annotations count] >= [[segmentVisualizer markers] count]))
	{
		// First, make sure all segments have markers
		[self redrawSegments];
		// Next make sure all markers are updated
		updated = [segmentVisualizer updateMarkers];
	}
	
	// If the visualizer doesn't support updating, or we need to clear
	// stray markers and reset the whole visualizer
	if(!updated)
	{
		[segmentVisualizer reset];
		[self setSegmentVisualizer:segmentVisualizer];		
	}
}

- (void)redrawSegments
{	
	//NSLog(@"redraw segments");
	for(Annotation* segment in annotations)
	{
		[self displayAnnotation:segment];
	}

	[rootLayer setNeedsDisplay];
}

- (BOOL)shouldHighlightMarker:(TimelineMarker*)marker
{
	if(![marker isDuration] && ([[AppController currentApp] currentTool] == DataPrismZoomTool))
	{
		return NO;
	}
	else
	{
		return YES;
	}
}

-(NSPoint)pointFromTime:(CMTime)time
{
	NSTimeInterval startInterval = CMTimeGetSeconds([self range].start);
	NSTimeInterval durationInterval = CMTimeGetSeconds([self range].duration);
	NSTimeInterval timeInterval = CMTimeGetSeconds(time);
	
	return NSMakePoint(((timeInterval - startInterval)/durationInterval) * [self bounds].size.width,0);
}

-(CMTime)timeFromPoint:(NSPoint)point
{
	NSTimeInterval durationInterval = CMTimeGetSeconds([self range].duration);
	NSTimeInterval rangeStartInterval = CMTimeGetSeconds([self range].start);
	durationInterval = rangeStartInterval + durationInterval * (point.x / [self bounds].size.width);
	
    return CMTimeMakeWithSeconds(durationInterval, [self range].duration.timescale);
}

-(void)showTimes:(BOOL)showTimes
{
	if(showTimes && !timesVisualizer)
	{
		timesLayer = [[CALayer layer] retain];
		timesLayer.bounds = rootLayer.bounds;
		timesLayer.anchorPoint = CGPointMake(0, 0);
		timesLayer.position = CGPointMake(0,0);
		timesLayer.autoresizingMask = (kCALayerHeightSizable | kCALayerWidthSizable);
		[rootLayer insertSublayer:timesLayer below:visualizationLayer];
		
        NSTimeInterval interval = CMTimeGetSeconds([[movie currentItem] duration]);
        if(interval > (60*60*6))
        {
            timesVisualizer = [[DateVisualizer alloc] initWithTimelineView:self];
        }
        else
        {
            timesVisualizer = [[TimeVisualizer alloc] initWithTimelineView:self];
        }
		[timesVisualizer setup];
	}
	else if(!showTimes && timesVisualizer)
	{
		[timesVisualizer release];
		timesVisualizer = nil;
	}
}

- (IBAction)toggleShowTimes:(id)sender
{
	[self showTimes:!timesVisualizer];
}

-(void)visualizeKeyframes:(id)sender
{
	[self setData:nil];
	AnnotationFilmstripVisualizer *viz = [[AnnotationFilmstripVisualizer alloc] initWithTimelineView:self];
	VideoProperties* videoProps = [sender representedObject];
	if(videoProps)
	{
		[viz setVideoProperties:videoProps];
	}
	[self setSegmentVisualizer:viz];
	[viz release];
}

-(void)visualizeAudio:(id)sender
{
	[self setData:nil];
	AudioVisualizer* viz = [[AudioVisualizer alloc] initWithTimelineView:self];
	VideoProperties* videoProps = [sender representedObject];
	if(videoProps)
	{
		[viz setVideoProperties:videoProps];
	}
	[self setSegmentVisualizer:viz];
	[viz release];
}

-(void)visualizeData:(id)sender
{
	TimeSeriesData *data = [sender representedObject];
	if(data)
	{
		if([self visualizeMultipleTimeSeries] && ([[self dataSets] count] > 0))
		{
			if([[self dataSets] containsObject:data])
			{
				[self removeData:data];
			}
			else
			{
				[self addData:data];
			}
		}
		else
		{
			[self setData:data];
		}
		SegmentVisualizer *viz = (SegmentVisualizer*)[[timeSeriesVisualizerClass alloc] initWithTimelineView:self];
		[self setSegmentVisualizer:viz];
		[viz release];
	}
	else
	{
		[self setData:nil];
		AnnotationTimeSeriesVisualizer *viz = [[AnnotationTimeSeriesVisualizer alloc] initWithTimelineView:self andVisualizer:nil];
		[self setSegmentVisualizer:viz];
		[viz release];
	}
}

-(void)toggleShowAnnotations
{
	if([segmentVisualizer isKindOfClass:[LayeredVisualizer class]])
	{
		SegmentVisualizer *dataViz = [[(LayeredVisualizer*)segmentVisualizer dataVisualizer] retain];
		[self setSegmentVisualizer:dataViz];
		[dataViz release];
	}
	else if([segmentVisualizer isKindOfClass:[TimeSeriesVisualizer class]])
	{
		AnnotationTimeSeriesVisualizer *viz = [[AnnotationTimeSeriesVisualizer alloc] initWithTimelineView:self andVisualizer:(TimeSeriesVisualizer*)segmentVisualizer];
		[self setSegmentVisualizer:viz];
		[viz release];
	}
	else if([segmentVisualizer isKindOfClass:[FilmstripVisualizer class]])
	{
		AnnotationFilmstripVisualizer *viz = [[AnnotationFilmstripVisualizer alloc] initWithTimelineView:self andSecondVisualizer:segmentVisualizer];
		[self setSegmentVisualizer:viz];
		[viz release];
	}
	else if([segmentVisualizer isKindOfClass:[AudioVisualizer class]])
	{
		LayeredVisualizer *viz = [[LayeredVisualizer alloc] initWithTimelineView:self andSecondVisualizer:segmentVisualizer];
		[viz setOverlayAnnotations:YES];
		[self setSegmentVisualizer:viz];
		[viz release];
	}
	else if(segmentVisualizer == nil)
	{
		AnnotationVisualizer *viz = [[AnnotationVisualizer alloc] initWithTimelineView:self];
		[self setSegmentVisualizer:viz];
		[viz release];
	}
	else
	{
		LayeredVisualizer *viz = [[LayeredVisualizer alloc] initWithTimelineView:self andSecondVisualizer:segmentVisualizer];
		[viz setOverlayAnnotations:YES];
		[self setSegmentVisualizer:viz];
		[viz release];
	}
}

-(void)toggleVisualizeMultipleTimeSeries:(id)sender
{
	[self setVisualizeMultipleTimeSeries:![self visualizeMultipleTimeSeries]];
	
	if(![self visualizeMultipleTimeSeries])
	{
		if([segmentVisualizer isKindOfClass:[LayeredVisualizer class]]
		   && [[[(LayeredVisualizer*)segmentVisualizer dataVisualizer] class] isKindOfClass:[MultipleTimeSeriesVisualizer class]])
		{
			AnnotationTimeSeriesVisualizer *viz = [[AnnotationTimeSeriesVisualizer alloc] initWithTimelineView:self andVisualizer:(TimeSeriesVisualizer*)segmentVisualizer];
			[self setSegmentVisualizer:viz];
			[viz release];
		}
		else if([segmentVisualizer isKindOfClass:[TimeSeriesVisualizer class]])
		{
			TimeSeriesVisualizer *viz = [[TimeSeriesVisualizer alloc] initWithTimelineView:self];
			[self setSegmentVisualizer:viz];
			[viz release];
		}
		
		if([[self dataSets] count] > 1)
		{
			TimeSeriesData *dataSet = [[[self dataSets] objectAtIndex:0] retain];
			[dataSets removeAllObjects];
			[dataSets addObject:dataSet];
			[dataSet release];
		}
	}
	else
	{
		timeSeriesVisualizerClass = [MultipleTimeSeriesVisualizer class];
	}
}

-(void)toggleTimeSeriesVisualization:(id)sender
{
	Class newViz = [sender representedObject];
	
	if(newViz && (newViz != timeSeriesVisualizerClass))
	{
		timeSeriesVisualizerClass = newViz;
		SegmentVisualizer *viz = (SegmentVisualizer*)[[timeSeriesVisualizerClass alloc] initWithTimelineView:self];
		[self setSegmentVisualizer:viz];
		[viz release];
		
		if(timeSeriesVisualizerClass != [TimeSeriesVisualizer class])
		{
			[self setVisualizeMultipleTimeSeries:YES];
		}
		else
		{
			[self setVisualizeMultipleTimeSeries:NO];
		}
	}
	
}

#pragma mark Time Series Data


-(NSArray*)dataSets
{
	return [[dataSets copy] autorelease];	
}

-(void)setData:(TimeSeriesData*)data
{
	[dataSets removeAllObjects];
    if(data != nil)
        [dataSets addObject:data];
}

-(void)addData:(TimeSeriesData*)data
{
	[dataSets addObject:data];
}

-(BOOL)removeData:(TimeCodedData*)data
{
	if([dataSets containsObject:data])
	{
		[dataSets removeObject:data];
		return YES;
	}
	else
	{
		return NO;
	}
}

-(IBAction)alignToPlayhead:(id)sender
{	
	if([[sender representedObject] isKindOfClass:[TimelineMarker class]])
	{
		Annotation *annotation = [(TimelineMarker*)[sender representedObject] annotation];
		
		DataSource *dataSource = [[AnnotationDocument currentDocument] dataSourceForAnnotation:annotation];
		
		if(dataSource)
		{
			CMTime clickedTime = [annotation startTime];
			CMTime playheadTime = [[AppController currentApp] currentTime];
			CMTime diff = CMTimeSubtract(playheadTime, clickedTime);
			
			CMTimeRange dataRange = [dataSource range];
			
			dataRange.start = CMTimeAdd(dataRange.start, diff);
			
			[dataSource setRange:dataRange];
		}
		
	}
	else if([[sender representedObject] isKindOfClass:[NSEvent class]])
	{		
		NSEvent *event = [sender representedObject];
		NSPoint curPoint = [self convertPoint:[event locationInWindow] fromView:nil];
		long long timeValue = ([self range].duration.value * (curPoint.x / [self bounds].size.width)) + [self range].start.value;
		int timeScale = range.duration.timescale;
		
		CMTime clickedTime = CMTimeMake(timeValue,timeScale);
		CMTime playheadTime = [[AppController currentApp] currentTime];
		
		if([dataSets count] == 1)
		{
			TimeSeriesData *timeSeriesData = [dataSets objectAtIndex:0];
			if([[timeSeriesData source] timeCoded])
			{
				CMTime diff = CMTimeSubtract(playheadTime, clickedTime);
				CMTimeRange dataRange = [[timeSeriesData source] range];
				dataRange.start = CMTimeAdd(dataRange.start, diff);
				[[timeSeriesData source] setRange:dataRange];
			}
			else if(timeSeriesData)
			{
				CMTimeRange newRange = CMTimeRangeMake(CMTimeMake(timeValue,timeScale),
													   CMTimeMake(range.duration.value - timeValue,timeScale));
				
				[timeSeriesData scaleFromRange:newRange toRange:range];	
			}
		}
		else if([segmentVisualizer movie] != [self movie])
		{
			for(VideoProperties *properties in [[AppController currentDoc] mediaProperties])
			{
				if([segmentVisualizer movie] == [properties movie])
				{
					CMTime oldOffset = [properties offset];
					CMTime newOffset = CMTimeAdd(oldOffset, CMTimeSubtract(clickedTime,playheadTime));
					[properties setOffset:newOffset];
					//NSLog(@"offset: %qi",[properties offset].value);
					[[AppController currentDoc] saveVideoProperties:properties];
				}
			}
		}
		[self redrawAllSegments];
	}
}


//-(IBAction)setDataStart:(id)sender
//{
//	NSEvent *event = [sender representedObject];
//	NSPoint curPoint = [self convertPoint:[event locationInWindow] fromView:nil];
//	long long timeValue = ([self range].duration.value * (curPoint.x / [self bounds].size.width)) + [self range].time.value;
//	long timeScale = range.duration.timescale;
//	
//	CMTimeRange newRange = CMTimeRangeMake(CMTimeMake(timeValue,timeScale),
//										   CMTimeMake(range.duration.value - timeValue,timeScale));
//	
//	[timeSeriesData scaleFromRange:newRange toRange:range];
//	
//	[self redrawAllSegments];
//}
//
//
//-(IBAction)setDataEnd:(id)sender
//{
//	NSEvent *event = [sender representedObject];
//	NSPoint curPoint = [self convertPoint:[event locationInWindow] fromView:nil];
//	long long timeValue = ([self range].duration.value * (curPoint.x / [self bounds].size.width)) + [self range].time.value;
//	long timeScale = range.duration.timescale;
//	
//	CMTimeRange newRange = CMTimeRangeMake(CMTimeMake(0,timeScale),
//										   CMTimeMake(timeValue,timeScale));
//	
//	[timeSeriesData scaleFromRange:newRange toRange:range];
//	
//	[self redrawAllSegments];
//}

-(IBAction)resetAlignment:(id)sender
{
	if([dataSets count] == 1)
	{
		TimeSeriesData *timeSeriesData = [dataSets objectAtIndex:0];
		[timeSeriesData scaleToRange:range];
	}
}

-(void)startTimelineShift
{
	shiftingTimeline = YES;
	int options = NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp;
	shiftingTracker = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
	[self addTrackingArea:shiftingTracker];
	[shiftingTracker release];
}

-(void)endTimelineShift
{
	if(shiftingTimeline)
	{
		shiftingTimeline = NO;
		[self removeTrackingArea:shiftingTracker];
	}
}

#pragma mark Annotations

-(void)setAnnotationFilter:(AnnotationFilter*)filter
{
	if(filter)
	{
		[filter retain];
		[annotationFilter release];
		annotationFilter = filter;
		filterAnnotations = YES;
	}
	else
	{
		[annotationFilter release];
		annotationFilter = nil;
		filterAnnotations = NO;
	}
	[segmentVisualizer reset];
	[self redrawAllSegments];
    [self updateTimePoints];
}

-(AnnotationFilter*)annotationFilter
{
	return annotationFilter;
}

-(IBAction)editAnnotationFilters:(id)sender
{
	AnnotationFiltersController* filtersController = [[AppController currentApp] annotationFiltersController];
	//[filtersController setAnnotationView:self];
    [filtersController attachToAnnotationView:self];
	//[filtersController showWindow:self];
	//[[filtersController window] makeKeyAndOrderFront:self];
}

-(IBAction)setCategoryFilter:(id)sender
{
	AnnotationCategory *category = [sender representedObject];
	if(!category)
	{
		[self setAnnotationFilter:nil];
	}
	else
	{
		[self setAnnotationFilter:[AnnotationCategoryFilter filterForCategory:category]];
		//[self setAnnotationFilter:[NSPredicate predicateWithFormat:@"category == %@",category]];
	}	
}

- (void)setFilterAnnotations:(BOOL)filter
{
	if(filter)
	{
		[self setAnnotationFilter:[AnnotationCategoryFilter filterForCategory:[basisAnnotation category]]];
		//[self setAnnotationFilter:[NSPredicate predicateWithFormat:@"category == %@",[basisAnnotation category]]];
	}
	else
	{
		filterAnnotations = NO;
		//[self setAnnotationFilter:nil];
	}
	//[self redrawAllSegments];
}

- (BOOL)filterAnnotations
{
	return filterAnnotations;
}

-(void)updateTimePoints
{
	[timePoints removeAllObjects];
	for(Annotation *annotation in annotations)
	{
        if(!filterAnnotations
           || [[annotationFilter predicate] evaluateWithObject:annotation])
        {
            NSTimeInterval timeInterval = CMTimeGetSeconds([annotation startTime]);
            
            [timePoints addObject:[NSNumber numberWithFloat:timeInterval]];
            if([annotation isDuration])
            {
                [timePoints addObject:[NSNumber numberWithFloat:CMTimeGetSeconds([annotation endTime])]];
            }
            [timePoints sortUsingSelector:@selector(compare:)];
        }
	}
}

-(NSTimeInterval)closestTimePoint:(NSTimeInterval)timeValue
{
	//float distance = fabs([[timePoints objectAtIndex:0] floatValue] - timeValue);
	//NSNumber *currentVal = [timePoints objectAtIndex:0];
	
	float distance = FLT_MAX;
	NSNumber *currentVal = nil;
	for(NSNumber *num in timePoints)
	{
		if((fabs([num floatValue] - originalStartTime) < .0001)
			|| (fabs([num floatValue] - originalStartTime) < .0001))
		{
			continue;
		}
		
		if(fabs([num floatValue] - timeValue) <= distance)
		{
			distance = fabs([num floatValue] - timeValue);
			currentVal = num;
		}
		else
		{
			break;
		}
	}
	if(!currentVal)
	{
		currentVal = [NSNumber numberWithFloat:FLT_MAX];
	}
	return [currentVal floatValue];
}

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
    TimelineMarker *removedMarker = [segmentVisualizer removeSegmentBoundary:annotation];
    if(removedMarker == selectedMarker)
    {
        [[AppController currentApp] setSelectedAnnotation:nil];
    }
    if(!filterAnnotations
	   || [[annotationFilter predicate] evaluateWithObject:annotation])
	{
        [self updateTimePoints];
    }
}

-(void)updateAnnotation:(Annotation*)annotation
{
	if(!movingLeftMarker && !movingRightMarker)
	{
		BOOL displayed = [self displayAnnotation:annotation];
        if(displayed)
            [self updateTimePoints];
		if([selectedMarker annotation] == annotation)
		{
			[self setSelected:selectedMarker];
		}
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
			[timePoints addObject:[NSNumber numberWithFloat:[annotation startTimeSeconds]]];
			if([marker isDuration])
			{
				[timePoints addObject:[NSNumber numberWithFloat:[annotation endTimeSeconds]]];
			}
			[timePoints sortUsingSelector:@selector(compare:)];
			
			if(annotation == [[AppController currentApp] selectedAnnotation])
			{
				[self setSelected:marker];
			}
            return YES;
		}
	}
    return NO;
}

// For legacy support in visualizers
- (NSArray*)segments
{
	return annotations;
}

- (NSArray*)annotations
{
	return annotations;
}

-(void)setSelected:(TimelineMarker*)segment
{
	
	selectedMarker = segment;
	
	[self redraw];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"selectedAnnotation"]) {
		if(![object selectedAnnotation])
		{
			[self setSelected:nil];
		}
    }
	else if ([keyPath isEqual:@"range"]) {
		NSTimeInterval rangeDuration = CMTimeGetSeconds(range.duration);
		float width = ([self frame].size.width);
		snapThreshold = 5.0*(rangeDuration/width);
    }
	else if ([keyPath isEqual:@"label"])
	{
		if(!labelLayer)
		{
			
			labelLayer = [[CATextLayer layer] retain];
			labelLayer.font = @"Helvetica-Bold";
			labelLayer.fontSize = 16.0;
			labelLayer.alignmentMode = kCAAlignmentRight;
			labelLayer.autoresizingMask = (kCALayerMaxYMargin | kCALayerMinXMargin);
			labelLayer.bounds = CGRectMake(0.0, 0.0, [self frame].size.width - 2.0, 20.0);
			labelLayer.anchorPoint = CGPointMake(0.0, 0.0);
			labelLayer.position = CGPointMake(0.0,0.0);
			CGColorRef darkgrey = CGColorCreateGenericGray(0.1, 1.0);
			labelLayer.foregroundColor = darkgrey;
			CGColorRelease(darkgrey);
			labelLayer.opacity = 1.0;
//			
//			NSMutableDictionary *customActions=[NSMutableDictionary dictionaryWithDictionary:[labelLayer actions]];
//			
//			// add the new action for sublayers
//			[customActions setObject:[NSNull null] forKey:@"bounds"];
//			[customActions setObject:[NSNull null] forKey:@"position"];
//			
//			// set theLayer actions to the updated dictionary
//			labelLayer.actions=customActions;
			
			[rootLayer insertSublayer:labelLayer below:playheadLayer];
		}

		labelLayer.string = [self label];
	}
	else
	{
    [super observeValueForKeyPath:keyPath
						 ofObject:object
						   change:change
						  context:context];
	}
}

#pragma mark Mouse Events

//- (void)rightMouseDown:(NSEvent *)event
//{
//	[[AppController currentApp] 
//}

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

- (void)mouseEntered:(NSEvent *)theEvent
{
	if([self showActionButtons])
	{
		actionLayer.hidden = NO;		
	}

	if(labelLayer)
	{
		labelLayer.opacity = 0.3;
	}
	
//	if(linkedToMouse)
//	{
//		NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
//		[self setPlayheadPosition:(curPoint.x / [self bounds].size.width)];
//		[self setShowPlayhead:YES];
//		[self setNeedsDisplay:YES];
//	}

}

- (void)mouseExited:(NSEvent *)theEvent
{
	if(![(MultiTimelineView*)[self superTimelineView] draggingTimeline])
		actionLayer.hidden = YES;

	if(labelLayer)
	{
		labelLayer.opacity = 1.0;
	}
	
//	if(linkedToMouse)
//	{
//		[self setShowPlayhead:NO];
//		[self setNeedsDisplay:YES];	
//	}
}


- (void)mouseMoved:(NSEvent *)theEvent
{
	//NSLog(@"Mouse moved");
	
	NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	if([listLayer containsPoint:[listLayer convertPoint:NSPointToCGPoint(pt) fromLayer:rootLayer]])
	{
		listLayer.shadowOpacity = 0.9;
		menuLayer.shadowOpacity = 0;
	}
	else if([menuLayer containsPoint:[menuLayer convertPoint:NSPointToCGPoint(pt) fromLayer:rootLayer]])
	{
		listLayer.shadowOpacity = 0;
		menuLayer.shadowOpacity = 0.9;
	}
	else
	{
		listLayer.shadowOpacity = 0;
		menuLayer.shadowOpacity = 0;
	}
	
	
	if(linkedToMouse)
	{
		NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		[self setPlayheadPosition:(curPoint.x / [self bounds].size.width)];
		[self setNeedsDisplay:YES];
	}
}


- (void)mouseDragged:(NSEvent *)theEvent
{
	if([[AppController currentApp] currentTool] == DataPrismZoomTool)
	{
		return;
	}
	
	MultiTimelineView *multi = (MultiTimelineView *)[self superTimelineView];
	if([multi draggingTimeline])
	{
		[multi mouseDragged:theEvent];
		return;
	}
	
	if(draggingTimelineMarker)
	{
		[segmentVisualizer dragMarker:draggingTimelineMarker forDragEvent:theEvent];
	}
	if(movingPlayhead)
	{
		NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		if(curPoint.x < 0)
		{
			curPoint.x = 0;
		}
		else if(curPoint.x > [self bounds].size.width)
		{
			curPoint.x = [self bounds].size.width;
		}
		
		[self setPlayheadPosition:(curPoint.x / [self bounds].size.width)];
		
		[[AppController currentApp] moveToTime:[self timeFromPoint:curPoint]
									fromSender:self];
	}
	if(movingLeftMarker)
	{
		linkedToMovie = NO;
		NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		long long timeValue = ([self range].duration.value * (curPoint.x / [self bounds].size.width)) + [self range].start.value;
		CMTimeScale timeScale = [self range].duration.timescale;
		NSTimeInterval timeInterval = (double)timeValue/(double)timeScale;
		
		// Make sure the start time doesn't go past the end time
		if([selectedMarker isDuration] && (timeInterval >= originalEndTime))
		{
			timeValue = originalEndTime - 1;
			curPoint.x = ((double)timeValue/[[movie currentItem] duration].value) * [self bounds].size.width;
		}
		// Snap to existing points on the timeline
		else
		{
			float timePoint = [self closestTimePoint:timeInterval];
			if((fabs(timePoint - timeInterval) < snapThreshold)
			   && (timePoint != originalStartTime)
			   && (timePoint != originalEndTime))
			{
				timeValue = timePoint * timeScale;
				
				NSTimeInterval rangeStart = CMTimeGetSeconds([self range].start);
				NSTimeInterval rangeDuration = CMTimeGetSeconds([self range].duration);
				float newPlayheadPos = (timePoint - rangeStart)/rangeDuration;
				
				//curPoint.x = ((double)timePoint/[movie duration].value) * [self bounds].size.width;
				curPoint.x = newPlayheadPos * [self bounds].size.width;
			}
		}

		
		[[AppController currentApp] moveToTime:CMTimeMake(timeValue,timeScale) fromSender:self];
		playheadPosition = (curPoint.x / [self bounds].size.width);
		
		//[CATransaction flush];
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];
		
		[playheadLayer setPosition:CGPointMake(curPoint.x, [playheadLayer position].y)];
		[[selectedMarker annotation] setStartTime:CMTimeMake(timeValue,timeScale)];
		
		[CATransaction commit];
		
	}
	else if(movingRightMarker)
	{
		linkedToMovie = NO;
		NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		long long timeValue = ([self range].duration.value * (curPoint.x / [self bounds].size.width)) + [self range].start.value;
		CMTimeScale timeScale = [self range].duration.timescale;
		NSTimeInterval timeInterval = (double)timeValue/(double)timeScale;

		// Make sure the end time doesn't go past the start time
		if(timeInterval <= originalStartTime)
		{
			timeValue = originalStartTime + 1;
			curPoint.x = ((double)timeValue/[[movie currentItem] duration].value) * [self bounds].size.width;
		}
		// Snap to existing points on the timeline
		else
		{
			float timePoint = [self closestTimePoint:timeInterval];
			if((fabs(timePoint - timeInterval) < snapThreshold)
			   && (timePoint != originalStartTime)
			   && (timePoint != originalEndTime))
			{
				timeValue = timePoint * timeScale;
				
				NSTimeInterval rangeStart = CMTimeGetSeconds([self range].start);
				NSTimeInterval rangeDuration = CMTimeGetSeconds([self range].duration);
				
				float newPlayheadPos = (timePoint - rangeStart)/rangeDuration;
				
				//curPoint.x = ((double)timePoint/[movie duration].value) * [self bounds].size.width;
				curPoint.x = newPlayheadPos * [self bounds].size.width;
			}
			
			
		}
		
		[[AppController currentApp] moveToTime:CMTimeMake(timeValue,timeScale) fromSender:self];
		playheadPosition = (curPoint.x / [self bounds].size.width);
		
		//[CATransaction flush];
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];
		
		[playheadLayer setPosition:CGPointMake(curPoint.x, [playheadLayer position].y)];
		[[selectedMarker annotation] setEndTime:CMTimeMake(timeValue,timeScale)];
		
		[CATransaction commit];
		
	}
}

-(void)mouseUp:(NSEvent *)theEvent
{
	listLayer.filters = nil;
	menuLayer.filters = nil;
	
	MultiTimelineView *multi = (MultiTimelineView *)[self superTimelineView];
	if([multi draggingTimeline])
	{
		[multi mouseUp:theEvent];
		return;
	}
	
	if(draggingTimelineMarker)
	{
		// refresh the selected marker
		[self setSelected:selectedMarker];
		draggingTimelineMarker = nil;
	}
	if(movingPlayhead)
	{
		movingPlayhead = NO;
		[self setLinkedToMouse:NO];
		[self setLinkedToMovie:YES];
		[[AppController currentApp] resumePlaying];
	}
	if(movingLeftMarker || movingRightMarker)
	{
		
		if(movingLeftMarker)
		{
	
			NSUndoManager* undoManager = [[AppController currentApp] undoManager];
			[undoManager enableUndoRegistration];
			[(Annotation*)[undoManager prepareWithInvocationTarget:[selectedMarker annotation]] setStartTime:originalStartCMTime];
			[undoManager setActionName:@"Change Annotation Position"];
		}
		
		if(movingRightMarker)
		{
			
			NSUndoManager* undoManager = [[AppController currentApp] undoManager];
			[undoManager enableUndoRegistration];
			[[undoManager prepareWithInvocationTarget:[selectedMarker annotation]] setEndTime:originalEndCMTime];
			[undoManager setActionName:@"Change Annotation Position"];
		}
		
		linkedToMovie = YES;
		movingLeftMarker = NO;
		movingRightMarker = NO;
		[self updateAnnotation:[selectedMarker annotation]];
		[[selectedMarker annotation] setUpdated];
		
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[(MultiTimelineView*)superTimelineView setActiveTimeline:self];
	
	NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	//
	// First check for timeline controls interaction
	//
	
	if([listLayer containsPoint:[listLayer convertPoint:NSPointToCGPoint(pt) fromLayer:rootLayer]])
	{
		[[AppController currentApp] closeHoverForMarker:nil];
		CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
		listLayer.filters = [NSArray arrayWithObject:filter];
		
		[(MultiTimelineView*)[self superTimelineView] setDraggingTimeline:self];
		[(MultiTimelineView*)[self superTimelineView] mouseDown:theEvent];
		return;
	}
	else if([menuLayer containsPoint:[menuLayer convertPoint:NSPointToCGPoint(pt) fromLayer:rootLayer]])
	{
		[[AppController currentApp] closeHoverForMarker:nil];
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];
		CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
		menuLayer.filters = [NSArray arrayWithObject:filter];
		[CATransaction commit];
		
		[NSMenu popUpMenu:[self menuForEvent:nil] 
				  forView:self 
				 atOrigin:NSPointFromCGPoint([rootLayer convertPoint:CGPointMake(0.0, -10.0) fromLayer:menuLayer]) 
				pullsDown:YES];
		return;
	}
	
	//
	// Next check for whether we're zooming
	//
	
	if([[AppController currentApp] currentTool] == DataPrismZoomTool)
	{
		if(highlightedMarker && [highlightedMarker isDuration])
		{
			[[AppController currentApp] closeHoverForMarker:highlightedMarker];
			[highlightedMarker setHighlighted:NO];
			[[AppController currentApp] zoomToTimeRange:[[highlightedMarker annotation] range]];
			[[AppController currentApp] setTool:DataPrismSelectTool];
		}
		else
		{
			long long timeValue = ([self range].duration.value * (pt.x / [self bounds].size.width)) + [self range].start.value;
			CMTimeScale timeScale = [self range].duration.timescale;
			[[AppController currentApp] zoomInToTime:CMTimeMake(timeValue,timeScale)];
		}
		return;
	}

	
	//
	// Next handle dragging a timeline marker left or right
	//
	
	if(selectedMarker && ([theEvent clickCount] == 1))
	{
		CGPoint markerPoint = [[selectedMarker layer] convertPoint:CGPointMake(pt.x, pt.y) fromLayer:rootLayer];
		
		if([selectedMarker startResizeLeft:markerPoint])
		{
			NSLog(@"move left");
			movingLeftMarker = YES;
			NSUndoManager* undoManager = [[AppController currentApp] undoManager];
			[undoManager disableUndoRegistration];
			originalStartCMTime = [[selectedMarker annotation] startTime];
			originalEndCMTime = [[selectedMarker annotation] endTime];
            originalStartTime = CMTimeGetSeconds(originalStartCMTime);
            originalEndTime = CMTimeGetSeconds(originalEndCMTime);
			return;
		}
		else if([selectedMarker startResizeRight:markerPoint])
		{
			NSLog(@"move right %f",markerPoint.x);
			movingRightMarker = YES;
			NSUndoManager* undoManager = [[AppController currentApp] undoManager];
			[undoManager disableUndoRegistration];
            originalStartCMTime = [[selectedMarker annotation] startTime];
            originalEndCMTime = [[selectedMarker annotation] endTime];
            originalStartTime = CMTimeGetSeconds(originalStartCMTime);
            originalEndTime = CMTimeGetSeconds(originalEndCMTime);
			return;
		}
	}
	
	//
	// Next handle dragging a marker up or down
	//
	
	if(highlightedMarker && [segmentVisualizer canDragMarkers])
	{
		CGPoint markerPoint = [[highlightedMarker layer] convertPoint:CGPointMake(pt.x, pt.y) fromLayer:rootLayer];
		
		if([[highlightedMarker layer] containsPoint:markerPoint])
		{
			draggingTimelineMarker = highlightedMarker;	
		}
		else
		{
			[highlightedMarker setHighlighted:NO];
			highlightedMarker = nil;
		}
	}
	
	//
	// Timeline marker selection
	//
	
	if(highlightedMarker)
	{
		[[AppController currentApp] moveToTime:[[highlightedMarker annotation] startTime] fromSender:highlightedMarker];
		if([theEvent clickCount] > 1)
		{
			[[AppController currentApp] selectTimelineMarker:highlightedMarker];
		}
		else
		{
			[[AppController currentApp] setSelectedAnnotation:[highlightedMarker annotation]];
		}
		return;
	}
	
	//
	// Deselection by double-clicking on the empty timeline
	//
	
	if([theEvent clickCount] > 1)
	{
		[[AppController currentApp] setSelectedAnnotation:nil];
	}
	
	//
	// Finally, deal with moving the playhead
	//
	
	if(showPlayhead && clickToMovePlayhead)
	{
		[[AppController currentApp] setRate:0.0 fromSender:self];
		NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		[self setPlayheadPosition:(curPoint.x / [self bounds].size.width)];
		movingPlayhead = YES;
		[self setLinkedToMouse:YES];
		[self setLinkedToMovie:NO];

		[[AppController currentApp] moveToTime:[self timeFromPoint:curPoint]
									fromSender:self];
	}
	
	
	if(!recordClickPosition && !clickToMovePlayhead)
	{
		// If the timeline isn't responding to this click, pass it on.
		[super mouseDown:theEvent];
	}
}


-(BOOL)resizingAnnotation
{
	return (movingRightMarker || movingLeftMarker);
}

- (void)menuDidClose:(NSMenu *)menu
{
	menuLayer.filters = nil;
}

#pragma mark Contextual Menus

+ (NSMenu *)defaultMenu {
    NSMenu *theMenu = [[[NSMenu alloc] initWithTitle:@"Contextual Menu"] autorelease];
	[theMenu setAutoenablesItems:NO];
    return theMenu;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenu *theMenu = [[self class] defaultMenu];
	[theMenu setDelegate:self];
	
	VideoProperties *videoInfo = [[AppController currentDoc] videoProperties];
	
	NSMenuItem *item = nil;
	
	item = [theMenu addItemWithTitle:@"Remove Timeline" action:@selector(removeFromSuperTimeline) keyEquivalent:@""];
	[item setTarget:self];
	
	//if(superTimelineView && (self == [(MultiTimelineView*)superTimelineView baseTimeline]))
	if(superTimelineView && ([[(MultiTimelineView*)superTimelineView timelines] count] > 1))
    {
		[item setEnabled:YES];
	}
    else
    {
        [item setEnabled:NO];
    }
	
	
	[theMenu addItem:[NSMenuItem separatorItem]];

	// Data Alignment
	
	if(highlightedMarker && [[highlightedMarker annotation] source])
	{
        DataSource *source = [[AnnotationDocument currentDocument] dataSourceForAnnotation:[highlightedMarker annotation]];
		item = [theMenu addItemWithTitle:[NSString stringWithFormat:@"Align %@ To Playhead",[source name]]
															 action:@selector(alignToPlayhead:) 
													  keyEquivalent:@""];
		[item setRepresentedObject:highlightedMarker];
		[item setTarget:self];
		[theMenu addItem:[NSMenuItem separatorItem]];
	}
	else if(([dataSets count] == 1) || ([segmentVisualizer movie] != [self movie]))
	{
		if(theEvent)
		{
			item = [theMenu addItemWithTitle:@"Align To Playhead" action:@selector(alignToPlayhead:) keyEquivalent:@""];
			[item setRepresentedObject:theEvent];
		}
		
		item = [theMenu addItemWithTitle:@"Reset Alignment" action:@selector(resetAlignment:) keyEquivalent:@""];
		[theMenu addItem:[NSMenuItem separatorItem]];
		[item setTarget:self];
	}
	
	item = [theMenu addItemWithTitle:@"Set Label…" action:@selector(setLabelAction:) keyEquivalent:@""];
	[item setTarget:self];
	
	item = [theMenu addItemWithTitle:@"Show Times" action:@selector(toggleShowTimes:) keyEquivalent:@""];
	[item setTarget:self];
	if(timesVisualizer)
	{
		[item setState:1];	
	}
	else
	{
		[item setState:0];
	}
	
	
	item = [theMenu addItemWithTitle:@"Show Annotations" action:@selector(toggleShowAnnotations) keyEquivalent:@""];
	[item setTarget:self];
	[item setState:[segmentVisualizer isKindOfClass:[AnnotationVisualizer class]]];
	
	if([segmentVisualizer isKindOfClass:[AnnotationVisualizer class]])
	{
		item = [theMenu addItemWithTitle:@"Show Annotation Labels" action:@selector(toggleShowLabels) keyEquivalent:@""];
		[item setTarget:segmentVisualizer];
		[item setState:[(AnnotationVisualizer*)segmentVisualizer drawLabels]];
		
		item = [theMenu addItemWithTitle:@"Align Sub-Categories" action:@selector(toggleAlignCategories) keyEquivalent:@""];
		[item setTarget:segmentVisualizer];
		[item setState:[(AnnotationVisualizer*)segmentVisualizer lineUpCategories]];
	}
	
	item = [theMenu addItemWithTitle:@"Annotation Filters…" action:@selector(editAnnotationFilters:) keyEquivalent:@""];	
	[item setTarget:self];

	[theMenu addItem:[NSMenuItem separatorItem]];
		
	if([segmentVisualizer respondsToSelector:@selector(configureVisualization:)])
	{
		NSMenuItem *configure = [theMenu addItemWithTitle:@"Configure Visualization…" action:@selector(configureVisualization:) keyEquivalent:@""];
		[configure setTarget:segmentVisualizer];
	}
	
	NSMenuItem *keyframes = [theMenu addItemWithTitle:@"Visualize Keyframes" action:@selector(visualizeKeyframes:) keyEquivalent:@""];
	[keyframes setRepresentedObject:videoInfo];
	[keyframes setTarget:self];
	
	NSMenuItem *audio = [theMenu addItemWithTitle:@"Visualize Audio Waveform" action:@selector(visualizeAudio:) keyEquivalent:@""];
	[audio setRepresentedObject:videoInfo];
	[audio setTarget:self];
	if(![videoInfo hasAudio])
	{
		[audio setEnabled:NO];
	}
	
	NSMenuItem *videoItem = nil;
	NSMenu *keyframesMenu = nil;
	NSMenu *audioMenu = nil;
	
	for(VideoProperties *video in [[AppController currentDoc] mediaProperties])
	{
		if([video hasVideo])
		{
			if(!keyframesMenu)
			{
				keyframesMenu = [[NSMenu alloc] init];
				[keyframes setSubmenu:keyframesMenu];
				[keyframesMenu release];
				
				videoItem = [keyframesMenu addItemWithTitle:[videoInfo title] action:@selector(visualizeKeyframes:) keyEquivalent:@""];
				[videoItem setRepresentedObject:videoInfo];
				[videoItem setTarget:self];
			}
			
			videoItem = [keyframesMenu addItemWithTitle:[video title] action:@selector(visualizeKeyframes:) keyEquivalent:@""];
			[videoItem setRepresentedObject:video];
			[videoItem setTarget:self];
		}
		
		if([video hasAudio])
		{
			if(!audioMenu)
			{
				audioMenu = [[NSMenu alloc] init];
				[audio setSubmenu:audioMenu];
				[audioMenu release];
				
				videoItem = [audioMenu addItemWithTitle:[videoInfo title] action:@selector(visualizeAudio:) keyEquivalent:@""];
				[videoItem setRepresentedObject:videoInfo];
				[videoItem setTarget:self];
			}
			videoItem = [audioMenu addItemWithTitle:[video title] action:@selector(visualizeAudio:) keyEquivalent:@""];
			[videoItem setRepresentedObject:video];
			[videoItem setTarget:self];
		}
	}
	
	
	// Visualize Time Series
	NSArray *allDataSets = [[AppController currentDoc] timeSeriesData];
	if([allDataSets count] > 0)
	{
		
		NSMenuItem *timeSeriesItem = [theMenu addItemWithTitle:@"Visualize Time Series" action:NULL keyEquivalent:@""];
		NSMenu* timeSeriesMenu = [[NSMenu alloc] init];
		[timeSeriesItem setSubmenu:timeSeriesMenu];
		[timeSeriesMenu release];
		
		if((timeSeriesVisualizerClass != [TimeSeriesVisualizer class])
            && (timeSeriesVisualizerClass != [MultipleTimeSeriesVisualizer class]))
		{
			NSMenuItem *vizmethod = [timeSeriesMenu addItemWithTitle:@"Visualize as Line Graph" 
															 action:@selector(toggleTimeSeriesVisualization:) 
													  keyEquivalent:@""];
			[vizmethod setTarget:self];
			[vizmethod setRepresentedObject:[TimeSeriesVisualizer class]];	
		}
		else
		{
			NSMenuItem *vizmethod = [timeSeriesMenu addItemWithTitle:@"Visualize as Color Map" 
															 action:@selector(toggleTimeSeriesVisualization:) 
													  keyEquivalent:@""];
			[vizmethod setTarget:self];
			[vizmethod setRepresentedObject:[ColorMappedTimeSeriesVisualizer class]];	
			
			
			NSMenuItem *multiple = [timeSeriesMenu addItemWithTitle:@"Allow Multiple Time Series" 
															 action:@selector(toggleVisualizeMultipleTimeSeries:) 
													  keyEquivalent:@""];
			[multiple setTarget:self];
			
			if([self visualizeMultipleTimeSeries])
			{
				[multiple setState:NSOnState];
			}
			else
			{
				[multiple setState:NSOffState];
			}
			
		}
		
		[timeSeriesMenu addItem:[NSMenuItem separatorItem]];
		
		for(TimeSeriesData *data in allDataSets)
		{
            if([data name])
            {
                NSMenuItem *item = [timeSeriesMenu addItemWithTitle:[data name] action:@selector(visualizeData:) keyEquivalent:@""];
                [item setTarget:self];
                [item setRepresentedObject:data];
                if([[self dataSets] containsObject:data])
                {
                    [item setState:NSOnState];
                }
                else
                {
                    [item setState:NSOffState];
                }
            }
		}
	}
	
	
	// Exporting video clips
	if(highlightedMarker && [highlightedMarker isDuration])
	{
		[theMenu addItem:[NSMenuItem separatorItem]];
		
		if(keyframesMenu)
		{
			item = [theMenu addItemWithTitle:@"Export Video Clip" action:@selector(export:) keyEquivalent:@""];
			
			NSMenu *exportMenu = [[NSMenu alloc] init];
			[item setSubmenu:exportMenu];
			[exportMenu release];
			
			DPExportMovieClips *clipExport = nil;
			NSMutableArray *exporters = [NSMutableArray array];
			
			for(NSMenuItem *item in [keyframesMenu itemArray])
			{
				videoItem = [exportMenu addItemWithTitle:[[item title] stringByAppendingString:@"…"] action:@selector(export:) keyEquivalent:@""];
				
				clipExport = [[DPExportMovieClips alloc] init];
				[clipExport setAnnotation:[highlightedMarker annotation]];
				[clipExport setVideo:[item representedObject]];
				[exporters addObject:clipExport];
				[clipExport release];
				
				[videoItem setRepresentedObject:clipExport];
				[videoItem setTarget:[AppController currentApp]];
			}
			
			[contextualObjects release];
			contextualObjects = [exporters retain];
		}
		else
		{
			item = [theMenu addItemWithTitle:@"Export Video Clip…" action:@selector(export:) keyEquivalent:@""];
			[item setTarget:[AppController currentApp]];
			
			DPExportMovieClips *clipExport = [[DPExportMovieClips alloc] init];
			[clipExport setAnnotation:[highlightedMarker annotation]];
			[clipExport setVideo:videoInfo];
			[item setRepresentedObject:clipExport];
			
			[contextualObjects release];
			contextualObjects = [[NSArray alloc] initWithObjects:clipExport,nil];
			
			[clipExport release];	
		}
		
	}
    else if(highlightedMarker && ![highlightedMarker isDuration])
	{
		[theMenu addItem:[NSMenuItem separatorItem]];
		
		if(keyframesMenu)
		{
			item = [theMenu addItemWithTitle:@"Export Frame Image" action:@selector(export:) keyEquivalent:@""];
			
			NSMenu *exportMenu = [[NSMenu alloc] init];
			[item setSubmenu:exportMenu];
			[exportMenu release];
			
			DPExportFrameImages *clipExport = nil;
			NSMutableArray *exporters = [NSMutableArray array];
			
			for(NSMenuItem *item in [keyframesMenu itemArray])
			{
				videoItem = [exportMenu addItemWithTitle:[[item title] stringByAppendingString:@"…"] action:@selector(export:) keyEquivalent:@""];
				
				clipExport = [[DPExportFrameImages alloc] init];
				[clipExport setAnnotation:[highlightedMarker annotation]];
				[clipExport setVideo:[item representedObject]];
				[exporters addObject:clipExport];
				[clipExport release];
				
				[videoItem setRepresentedObject:clipExport];
				[videoItem setTarget:[AppController currentApp]];
			}
			
			[contextualObjects release];
			contextualObjects = [exporters retain];
		}
		else
		{
			item = [theMenu addItemWithTitle:@"Export Frame Image…" action:@selector(export:) keyEquivalent:@""];
			[item setTarget:[AppController currentApp]];
			
			DPExportFrameImages *clipExport = [[DPExportFrameImages alloc] init];
			[clipExport setAnnotation:[highlightedMarker annotation]];
			[clipExport setVideo:videoInfo];
			[item setRepresentedObject:clipExport];
			
			[contextualObjects release];
			contextualObjects = [[NSArray alloc] initWithObjects:clipExport,nil];
			
			[clipExport release];	
		}
		
	}
	
	return theMenu;
}

@end
