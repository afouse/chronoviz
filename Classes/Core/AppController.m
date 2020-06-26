//
//  AppController.m
//  Annotation
//
//  Created by Adam Fouse on 10/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import "PreferenceController.h"
#import "TimelineMarker.h"
#import "TimelineView.h"
#import "MultiTimelineView.h"
#import "OverviewTimelineView.h"
#import "Annotation.h"
#import "AnnotationCategory.h"
#import "AnnotationXMLParser.h"
#import "AnnotationInspector.h"
#import "AnnotationHover.h"
#import "AnnotationFileType.h"
#import "AnnotationView.h"
#import "MAAttachedWindow.h"
#import "VideoProperties.h"
#import "VideoPropertiesController.h"
#import "VideoDataSource.h"
#import "DateToRelativeTimeStringTransformer.h"
#import "DPTimeIntervalToStringTransformer.h"
#import "AnnotationVisualizer.h"
#import "VideoFrameLoader.h"
#import "NSStringParsing.h"
#import "NSString+NDCarbonUtilities.h"
#import "MapController.h"
#import "MapView.h"
#import "AnnotationDocument.h"
#import "DPDocumentTemplate.h"
#import "PluginManager.h"
#import "AnnotationDataAnalysisPlugin.h"
#import "PluginScriptController.h"
#import "ImageSequenceController.h"
#import "ImageSequenceView.h"
#import "AnnotationTableController.h"
#import "AnnotationFiltersController.h"
#import "MovieViewerController.h"
#import "MediaWindowController.h"
#import "CategoriesWindowController.h"
#import "DateVisualizer.h"
#import "LayeredVisualizer.h"
#import "AnnotationOverviewVisualizer.h"
#import "ProtoVisExport.h"
#import "DataSource.h"
#import "InternalDataSource.h"
#import "AnnotationSet.h"
#import "TimeCodedImageFiles.h"
#import "DPExport.h"
#import "DPExportMovieClips.h"
#import "DPExportSimileTimeline.h"
#import "DPExportPDF.h"
#import "DPExportCategories.h"
#import "DPExportTimeSeries.h"
#import "DPExportTranscript.h"
#import "DPExportAnnotationsTimeSeries.h"
#import "AnnotationQuickEntry.h"
#import "PrioritySplitViewDelegate.h"
#import "TranscriptViewController.h"
#import "AFMovieView.h"
#import "DPViewManager.h"
#import "DPConsoleWindowController.h"
#import "NSStringTimeCodes.h"
#import "SpatialAnnotationOverlay.h"
#import "DPMappedValueTransformer.h"
#import "NSMenuPopUpMenu.h"
#import "DPURLHandler.h"
#import "DPActivityLog.h"
#import "LinkedFilesController.h"
#import "DPDocumentVariablesController.h"
#import "DPSpatialDataView.h"
#import "DPSpatialDataWindowController.h"
#import "AnnotationViewController.h"
#import "DPPluginManager.h"

NSString * const KeyframeTimelineMenuTitle = @"Keyframes";
NSString * const AudioTimelineMenuTitle = @"Audio Waveform";
NSString * const TapestryTimelineMenuTitle = @"Annotation Tapestry";

//NSString * const DataPrismLogState = @"DataPrismLogState";
//
//int const DataPrismSelectTool = 0;
//int const DataPrismZoomTool = 1;

@interface AppController (PrivateMethods)

- (void)handleUpdateAnnotationNotification:(NSNotification*)notification;
- (void)openFilename:(NSString*)filename;
- (NSWindow*)documentLoadingWindow:(NSString*)filename;
- (BOOL)closeDocument;
- (void)reset;

- (void)showHoverAfterDelay:(NSTimer*)hoveTimer;

- (void)receiveMediaChanged:(NSNotification*)notification;

- (NSString*)processInteractionSource:(id)source;

- (void)refreshSavedStatesMenu;

@end

@implementation AppController

@synthesize hideMouse;
@synthesize autoSave;
@synthesize movieFileName;
@synthesize pauseWhileAnnotating;
@synthesize stepSize;
@synthesize playbackRate;
@synthesize popUpAnnotations;
@synthesize uploadInteractions;
@synthesize frameLoader;
@synthesize undoManager;
@synthesize newDocumentDuration;
@synthesize animating;
@synthesize currentTool;
@synthesize openVideosHalfSize;
@synthesize absoluteTime;

static AppController *currentApp = nil;

+ (void)initialize
{
	if ( self == [AppController class] ) {
		NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
		
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AFUploadInteractionsKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AFShowPlayheadKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AFClickToMovePlayheadKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AFPauseWhileAnnotatingKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AFShowPopUpAnnotationsKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AFHierarchicalTimelinesKey];
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:AFFilterTimelinesKey];
		[defaultValues setObject:[NSNumber numberWithInt:123456] forKey:AFRandomSeedKey];
		[defaultValues setObject:[NSNumber numberWithFloat:0.5] forKey:AFStepValueKey];
		[defaultValues setObject:[NSNumber numberWithFloat:1.0] forKey:AFPlaybackRateKey];
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:AFOpenVideosHalfSizeKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AFAutomaticAnnotationFileKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AFSaveTimePositionKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AFSaveAnnotationEditsKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AFSaveVizConfigKey];
		[defaultValues setObject:[NSNumber numberWithInt:0] forKey:AFTableEditActionKey];
		[defaultValues setObject:[NSNumber numberWithInt:0] forKey:AFAnnotationShortcutActionKey];
		[defaultValues setObject:[NSNumber numberWithInt:5] forKey:AFMaxPlaybackRateKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AFCreateFileBackupKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AFDeleteFileBackupKey];
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:AFOverwriteFileBackupKey];
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:AFUseQuickTimeXKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"AllowPenAnnotations"];
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:AFUseStaticMapKey];
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:AFTrackActivityKey];
        [defaultValues setObject:[NSNumber numberWithInteger:600] forKey:AFTimebaseKey];
		
		[defaultValues setObject:@"" forKey:AFUserIDKey];
		[defaultValues setObject:@"" forKey:AFUserNameKey];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
		//NSLog(@"Registered defaults: %@", defaultValues);
		
		// create an autoreleased instance of our value transformer
		DateToRelativeTimeStringTransformer *dateTimeTransformer = [[[DateToRelativeTimeStringTransformer alloc] init] autorelease];
		
		// register it with the name that we refer to it with
		[NSValueTransformer setValueTransformer:dateTimeTransformer
										forName:@"DateToRelativeTimeStringTransformer"];
		
        // create an autoreleased instance of our value transformer
		DPTimeIntervalToStringTransformer *timeIntervalTransformer = [[[DPTimeIntervalToStringTransformer alloc] init] autorelease];
		
		// register it with the name that we refer to it with
		[NSValueTransformer setValueTransformer:timeIntervalTransformer
										forName:@"TimeIntervalToStringTransformer"];
        
		
		DPMappedValueTransformer *speedTransformer = [[[DPMappedValueTransformer alloc] init] autorelease];
		
		[speedTransformer setOutputValues:[NSArray arrayWithObjects:
										 [NSNumber numberWithInt:-2],
										 [NSNumber numberWithInt:-1],
										 [NSNumber numberWithInt:0],
										 [NSNumber numberWithInt:1],
										 [NSNumber numberWithInt:2],
							  nil]];
		[speedTransformer setInputValues:[NSArray arrayWithObjects:
										  [NSNumber numberWithFloat:0.25],
										  [NSNumber numberWithFloat:0.5],
										  [NSNumber numberWithFloat:1.0],
										  [NSNumber numberWithFloat:2.0],
										  [NSNumber numberWithFloat:5.0],
							   nil]];
		
		[NSValueTransformer setValueTransformer:speedTransformer
										forName:@"DPSpeedTransformer"];
        
        DPMappedValueTransformer *negativeTransformer = [[[DPMappedValueTransformer alloc] init] autorelease];
		
		[negativeTransformer setOutputValues:[NSArray arrayWithObjects:
                                           [NSNumber numberWithInt:-4],
                                           [NSNumber numberWithInt:-3],
                                           [NSNumber numberWithInt:-2],
                                           [NSNumber numberWithInt:-1],
                                           [NSNumber numberWithInt:0],
                                           nil]];
		[negativeTransformer setInputValues:[NSArray arrayWithObjects:
										  [NSNumber numberWithFloat:4],
										  [NSNumber numberWithFloat:3],
										  [NSNumber numberWithFloat:2],
										  [NSNumber numberWithFloat:1],
										  [NSNumber numberWithFloat:0],
                                          nil]];
		
		[NSValueTransformer setValueTransformer:negativeTransformer
										forName:@"DPNegativeTransformer"];
		
	}
}
 
+ (AppController*)currentApp
{
	return currentApp;
}

+ (AnnotationDocument*)currentDoc
{
	return [currentApp document];
}


+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
	BOOL automatic = NO;
	
    if ([theKey isEqualToString:@"selectedAnnotation"]
		|| [theKey isEqualToString:@"mMovie"]) {
        automatic=NO;
    } else {
        automatic=[super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}

- (void)keyDown:(NSEvent *)event
{
    NSLog(@"AppController key down");
}

#pragma mark Initialization and Closing

- (id)init {
	[super init];
	
	undoManager = [[NSUndoManager alloc] init];
	
	viewManager = [[DPViewManager alloc] initForController:self];
	
	mMovie = nil;
	activeMovies = [[NSMutableArray alloc] init];
	// log = nil;
    // TODO: The `log` is never declared in this code. What did it do?
	rateLock = [[NSLock alloc] init];
	autoSave = NO;
	fullScreen = NO;
    visibleOverviewTimeline= NO;
	paused = NO;
	loopPlayback = NO;
	annotationPlayback = NO;
	zoomFactor = 1.0;
	playbackRate = 1.0;
	
	backupAnnotationFile = nil;
	
	currentTool = DataPrismSelectTool;
	
	[self setNewDocumentDuration:10.0];
	
	forceKeyframeUpdate = NO;

	videoPropertiesController = nil;

	annotationViews = [[NSMutableArray alloc] init];
	dataWindowControllers = [[NSMutableArray alloc] init];
	
	frameLoader = [[VideoFrameLoader alloc] init];
	
	[self setStepSize:[[NSUserDefaults standardUserDefaults] floatForKey:AFStepValueKey]];
	[self setPauseWhileAnnotating:[[NSUserDefaults standardUserDefaults] boolForKey:AFPauseWhileAnnotatingKey]];
	[self setPopUpAnnotations:[[NSUserDefaults standardUserDefaults] boolForKey:AFShowPopUpAnnotationsKey]];
	[self setUploadInteractions:[[NSUserDefaults standardUserDefaults] boolForKey:AFUploadInteractionsKey]];
	[self setOpenVideosHalfSize:[[NSUserDefaults standardUserDefaults] boolForKey:AFOpenVideosHalfSizeKey]];
	
	currentApp = self;
	
	[PluginManager defaultPluginManager];
	
	return self;
}

- (void) dealloc
{
	[appPluginManager release];
	[viewManager release];
	[urlHandler release];
	[consoleWindowController release];
	[activeMovies release];
	[[splitView delegate] release];
	[categoriesWindowController release];
	[mediaWindowController release];
	[linkedFilesController release];
	[documentVariablesController release];
	[frameLoader release];
	[mMovie release];
	[mMovieView release];
	[annotationDoc release];
	[annotationViews release];
	[dataWindowControllers release];
	[feedbackController release];
	[prefController release];
	[AnnotationFileType releaseAllTypes];
	[super dealloc];
}


- (void)awakeFromNib {
    
	urlHandler = [[DPURLHandler alloc] initForAppController:self];
	
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:urlHandler 
													   andSelector:@selector(handleURLEvent:withReplyEvent:) 
													 forEventClass:kInternetEventClass 
														andEventID:kAEGetURL];
	
    appPluginManager = [[DPPluginManager alloc] init];
    [appPluginManager loadPlugins];
	
	absoluteTime = NO;
	
	[mMovieWindow setDelegate:self];
	
	// Set up timeline
	[timelineView setRecordClickPosition:NO];
	[timelineView setFilterAnnotations:[[NSUserDefaults standardUserDefaults] boolForKey:AFFilterTimelinesKey]];
	[self addAnnotationView:timelineView];
	[self addAnnotationView:overviewTimelineView];
	
	// Set up timeline/movie split view
	float newPosition = [splitView bounds].size.height - ([splitView dividerThickness] + 90);
	[splitView setPosition:newPosition ofDividerAtIndex:0];
	
	PrioritySplitViewDelegate *splitViewDelegate = [[PrioritySplitViewDelegate alloc] init];
	[splitViewDelegate setPriority:0 forViewAtIndex:0];
	[splitViewDelegate setPriority:1 forViewAtIndex:1];
	[splitView setDelegate:splitViewDelegate];
	
	[timelineSelectionView setDelegate:viewManager];
	[timelineSelectionView setDataSource:viewManager];
	
	mainView = [mMovieView retain];
	
	// Initialize export types
	[saveFileTypesButton removeAllItems];
	AnnotationFileType* type = [AnnotationFileType xmlFileType];
	[saveFileTypesButton addItemWithTitle:[type description]];
	[[saveFileTypesButton lastItem] setRepresentedObject:type];
	type = [AnnotationFileType annotationFileType];
	[saveFileTypesButton addItemWithTitle:[type description]];
	[[saveFileTypesButton lastItem] setRepresentedObject:type];
	type = [AnnotationFileType csvFileType];
	[saveFileTypesButton addItemWithTitle:[type description]];
	[[saveFileTypesButton lastItem] setRepresentedObject:type];
	
	NSArray* exporters = [NSArray arrayWithObjects:
						  [[[DPExportSimileTimeline alloc] init] autorelease],
						  [[[ProtoVisExport alloc] init] autorelease],
						  [[[DPExportMovieClips alloc] init] autorelease],
						  [[[DPExportPDF alloc] init] autorelease],
						  [[[DPExportCategories alloc] init] autorelease],
                          //[[[DPExportTimeSeries alloc] init] autorelease],
                          [[[DPExportAnnotationsTimeSeries alloc] init] autorelease],
                          [[[DPExportTranscript alloc] init] autorelease],
						  nil];
	for(DPExport *exporter in exporters)
	{
		NSMenuItem *item = [exportMenu addItemWithTitle:[[exporter name] stringByAppendingString:@"…"] action:@selector(export:) keyEquivalent:@""];
		[item setRepresentedObject:exporter];
		[item setTarget:self];
	}
	
	
	// Initialize analysis plugins
	NSArray* plugins = [[PluginManager defaultPluginManager] plugins];
	for(AnnotationDataAnalysisPlugin *plugin in plugins)
	{
		NSMenuItem *item = [analysisMenu addItemWithTitle:[plugin displayName] action:@selector(runPlugin:) keyEquivalent:@""];
		[item setTarget:[PluginManager defaultPluginManager]];
		[item setRepresentedObject:plugin];
	}
	
	// Set up listeners
	[self addObserver:inspector 
		   forKeyPath:@"selectedAnnotation" 
			  options:0 
			  context:NULL];
	[self addObserver:self
		   forKeyPath:@"playbackRate"
			  options:0
			  context:NULL];
	NSString* maxRateKey = AFMaxPlaybackRateKey;
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:maxRateKey
											   options:0
											   context:NULL];
	
	
	NSString *userID = [[NSUserDefaults standardUserDefaults] stringForKey:AFUserIDKey];
	if([userID length] == 0)
	{
		CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
		CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
		userID = [NSString stringWithString:(NSString*)strRef];
		CFRelease(strRef);
		CFRelease(uuidRef);
		
		[[NSUserDefaults standardUserDefaults] setObject:userID forKey:AFUserIDKey];
		
		NSLog(@"User id: %@",userID);
	}
	
	NSDate *lastUpload = [[NSUserDefaults standardUserDefaults] objectForKey:AFLastUploadKey];
	if(!lastUpload)
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:AFLastUploadKey];
	}
	
	NSString *userName = [[NSUserDefaults standardUserDefaults] stringForKey:AFUserNameKey];
	if([userName length] == 0)
	{
		[[NSUserDefaults standardUserDefaults] setObject:NSFullUserName() forKey:AFUserNameKey];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleUpdateAnnotationNotification:)
												 name:AnnotationUpdatedNotification
											   object:nil];
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	if(annotationDoc == nil)
	{
		[self createNewAnnotationDocument:self];
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	NSApplicationTerminateReply reply = NSTerminateNow;
	
	// First, check whether there is an unsaved document
	if([self windowShouldClose:sender])
	{
		reply = NSTerminateNow;
	}
	else
	{
		reply = NSTerminateCancel;
	}
	
	return reply;
}

- (void)continueTermination
{
	[NSApp replyToApplicationShouldTerminate:YES];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[self setSelectedAnnotation:nil];

	if(annotationDoc)
	{
		[self closeDocument];
	}

	if(playing)
	{
		[self togglePlay:self];
	}
	
	[[PluginManager defaultPluginManager] release];
    
    [appPluginManager release];
    appPluginManager = nil;
    
}

- (void)reset
{
	/////////////////////////////
	// Reset things to base values
	/////////////////////////////
	
	[inspector setAnnotation:nil];
	[[inspector window] close];
	
	[backupAnnotationFile release];
	backupAnnotationFile = nil;
	
    [appPluginManager resetPlugins];
	
	[annotationViews removeAllObjects];
	[self addAnnotationView:timelineView];
	[self addAnnotationView:overviewTimelineView];
	
	[annotationHover reset];
	[timelineView reset];
	[overviewTimelineView reset];
	
	if(mainView != mMovieView)
	{
		[mMovieView setFrame:[mainView frame]];
		[self replaceMainView:mMovieView];
	}
    
    NSArray *existingMovies = [mMovieView movies];
    for(AVPlayer* movie in existingMovies)
    {
        [mMovieView removeMovie:movie];
    }
	
//	[imageSequenceView release];
//	imageSequenceView = nil;
	
	// Reset all of the controllers
	
	[videoPropertiesController close];
	[videoPropertiesController release];
	videoPropertiesController = nil;
	
//	[imageSequenceController close];
//	[imageSequenceController release];
//	imageSequenceController = nil;
	
	[annotationTableController close];
	[annotationTableController release];
	annotationTableController = nil;
	
	[pluginScriptController close];
	[pluginScriptController release];
	pluginScriptController = nil;
	
	[annotationFiltersController close];
	[annotationFiltersController release];
	annotationFiltersController = nil;

	[linkedFilesController close];
	[linkedFilesController release];
	linkedFilesController = nil;
	
	[documentVariablesController close];
	[documentVariablesController release];
	documentVariablesController = nil;
	
	[mediaWindowController close];
	[mediaWindowController release];
	mediaWindowController = nil;
	
	[categoriesWindowController close];
	[categoriesWindowController release];
	categoriesWindowController = nil;
	
	for(NSWindowController* windowController in dataWindowControllers)
	{
		[windowController close];
	}
	[dataWindowControllers removeAllObjects];
	mapController = nil;
	
    NSMenuItem *saveStateItem = [[savedStatesMenu itemAtIndex:0] retain];
    [savedStatesMenu removeAllItems];
    [savedStatesMenu addItem:saveStateItem];
    
//	NSArray *menuItems = [addTimelineMenu itemArray];
//	for(NSMenuItem *item in menuItems)
//	{
//		[addTimelineMenu removeItem:item];
//	}
	
	[timeDisplayTimer invalidate];
	timeDisplayTimer = nil;
	
	[timer invalidate];
	timer = nil;
	
	[frameLoader release];
	frameLoader = [[VideoFrameLoader alloc] init];
	
	absoluteTime = NO;
}

- (BOOL)closeDocument
{
	[self setSelectedAnnotation:nil];
	
	if(!annotationDoc)
	{
		return YES;
	}
	
	if(tempAnnotationDoc)
	{
		NSString *tempDir = [[annotationDoc annotationsDirectory] retain];
		
		if(([[annotationDoc annotations] count] > 0)
		   || ([[annotationDoc dataSources] count] > 0))
		{
			NSAlert *saveAlert = [[NSAlert alloc] init];
			[saveAlert setMessageText:@"Do you want to save the current project before closing?"];
			[saveAlert setInformativeText:@"All annotations and data will be lost if you don't save."];
			[saveAlert addButtonWithTitle:@"Save…"];
			[saveAlert addButtonWithTitle:@"Cancel"];
			[saveAlert addButtonWithTitle:@"Don't Save"];
			
			NSInteger result = [saveAlert runModal];
			
            [saveAlert release];
            
			if(result == NSAlertFirstButtonReturn)
			{
				[self saveAnnotationsAs:self];
			}
			else if (result == NSAlertSecondButtonReturn)
			{
                [tempDir release];
				return NO;
			}
		}
		NSLog(@"Delete %@",tempDir);
		NSError *error;
		[[NSFileManager defaultManager] removeItemAtPath:tempDir error:&error];
		[tempDir release];
	}
	else
	{
		NSLog(@"Saved annotation document");
		[annotationDoc save];
		[annotationDoc saveState:[self currentState:nil]];
	}
	
	if(backupAnnotationFile 
	   && [[NSUserDefaults standardUserDefaults] boolForKey:AFDeleteFileBackupKey]
	   && [[NSFileManager defaultManager] fileExistsAtPath:backupAnnotationFile])
	{
		NSError *err = nil;
		[[NSFileManager defaultManager] removeItemAtPath:backupAnnotationFile error:&err];
		[backupAnnotationFile release];
		backupAnnotationFile = nil;
	}
	
	[self reset];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:nil
												  object:annotationDoc];
	
	[annotationDoc release];
	annotationDoc = nil;
	
	return YES;
}

- (void)setAnnotationDocument:(AnnotationDocument*)doc
{		
	if(doc == nil)
	{
		return;
	}
	
	[self willChangeValueForKey:@"document"];
	
	[doc retain];
	
	if(annotationDoc)
	{
		[self closeDocument];
	}
	
	
	annotationDoc = doc;
	tempAnnotationDoc = NO;
	
    NSTimeInterval interval = CMTimeGetSeconds([[[self movie] currentItem] duration]);
    
    AnnotationVisualizer *viz = [[AnnotationVisualizer alloc] initWithTimelineView:[timelineView baseTimeline]];
    [[timelineView baseTimeline] setSegmentVisualizer:viz];
    [viz release];	
	
	//videoInfo = [annotationDoc videoProperties];
	//[[self window] setTitle:[NSString stringWithFormat:@"ChronoViz: %@",[videoInfo title]]];
	//[videoInfo addObserver:self forKeyPath:@"title" options:0 context:NULL];
    
    if([[annotationDoc annotationsDirectory] rangeOfString:@"tempannotation."].location != NSNotFound)
    {
        [[self window] setTitle:@"Untitled ChronoViz Project"];
    }
    else
    {
        [[self window] setTitle:[[[annotationDoc annotationsDirectory] lastPathComponent] stringByDeletingPathExtension]];
    }
    
	if(videoPropertiesController)
	{
		[videoPropertiesController setAnnotationDoc:annotationDoc];
	}
	
	[timelineView redrawAllSegments];
	[self updateViewMenu];
	
	NSData *stateData = [annotationDoc stateData];
	
	if(stateData)
	{
		[self setState:stateData];
	}
	else
	{
		if(openVideosHalfSize)
		{
			[self zoom:0.5];	
		}
		else
		{
			[self normalSize:self];
		}
	}
		
	for(id <AnnotationView> view in annotationViews)
	{
		[view addAnnotations:[annotationDoc annotations]];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateViewMenu)
												 name:DataSetsChangedNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(receiveMediaChanged:)
												 name:MediaChangedNotification
											   object:annotationDoc];
	
	[self updateViewMenu];
	
    [self refreshSavedStatesMenu];
    
	[mMovieWindow makeKeyAndOrderFront:self];
	
	
    [[AppController currentApp] endDocumentLoading:self];
    
	[self didChangeValueForKey:@"document"];
}

- (void)setMainVideo:(VideoProperties *)video;
{
	[self willChangeValueForKey:@"mMovie"];
	
	loadingMovie = YES;
	
	[inspector setAnnotation:nil];
	
    [video retain];
    [mainVideo release];
    mainVideo = video;
    
    AVPlayer *movie = [mainVideo movie];
    
	[movie retain];
	[mMovie release];
	mMovie = movie;
	
    // Register notification for looping.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[mMovie currentItem]];
    
	[mMovieView setMovie:mMovie];
	
	// Set up the timeline
    NSTimeInterval interval = CMTimeGetSeconds([[[mMovie currentItem] asset] duration]);
	if(absoluteTime && (interval > (60*60*6)))
	{
		DateVisualizer *dateViz = [[DateVisualizer alloc] initWithTimelineView:[timelineView baseTimeline]];
		
		LayeredVisualizer *viz = [[LayeredVisualizer alloc] initWithTimelineView:[timelineView baseTimeline] 
															 andSecondVisualizer:dateViz];
		
		[[timelineView baseTimeline] setSegmentVisualizer:viz];
		[viz release];	
		[dateViz release];
		
		DateVisualizer *timeVisualizer = [[DateVisualizer alloc] initWithTimelineView:overviewTimelineView];
		[overviewTimelineView setSegmentVisualizer:timeVisualizer];
		[timeVisualizer release];
	}
	else
	{
		AnnotationVisualizer *viz = [[AnnotationVisualizer alloc] initWithTimelineView:[timelineView baseTimeline]];
		[[timelineView baseTimeline] setSegmentVisualizer:viz];
		[viz release];	
		
		AnnotationOverviewVisualizer *overviewVisualizer = [[AnnotationOverviewVisualizer alloc] initWithTimelineView:overviewTimelineView];
		[overviewTimelineView setSegmentVisualizer:overviewVisualizer];
		[overviewVisualizer release];
		
	}
	
	[timelineView setMovie:mMovie];
	[overviewTimelineView setMovie:mMovie];	
		
	[timelineView setShowPlayhead:YES];
	[timelineView setClickToMovePlayhead:YES];
	[timelineView setLinkedToMouse:NO];
	[timelineView setLinkedToMovie:YES];
	
	//[frameLoader loadAllFramesForMovie:mMovie];
	
	loadingMovie = NO;
	
	[self updateDisplay:nil];
	
	[self didChangeValueForKey:@"mMovie"];
}

- (NSData*)currentState:(NSDictionary*)stateFlags
{
	NSMutableArray *states = [NSMutableArray arrayWithCapacity:[annotationViews count]];
	NSMutableArray *classes = [NSMutableArray arrayWithCapacity:[annotationViews count]];
	NSMutableArray *rects = [NSMutableArray arrayWithCapacity:[annotationViews count]];
	NSMutableArray *filters = [NSMutableArray arrayWithCapacity:[annotationViews count]];
	NSMutableArray *windowOrder = [NSMutableArray arrayWithCapacity:[annotationViews count]];
    
    NSTimeInterval time = CMTimeGetSeconds([self currentTime]);
	
    NSString *mainViewClass = NSStringFromClass([mainView class]);
    NSData *mainViewStateData = nil;
    if((mainView != mMovieView) && [mainView conformsToProtocol:@protocol(DPStateRecording)])
    {
        mainViewStateData = [(NSView<DPStateRecording>*)mainView currentState:stateFlags];
    }
    else
    {
        mainViewStateData = [NSData data];
    }
    
    NSMutableArray *movieIDs = [NSMutableArray array];
	NSMutableArray *movieTitles = [NSMutableArray array];
    NSMutableArray *movieEnabledStates = [NSMutableArray array];
	for(AVPlayer *movie in [mMovieView movies])
	{
        for(VideoProperties* video in [[AnnotationDocument currentDocument] allMediaProperties])
        {
            if([video movie] == movie)
            {
                [movieIDs addObject:[video uuid]];
                [movieEnabledStates addObject:[NSNumber numberWithBool:[video enabled]]];
                if(movie != mMovie)
                {
                    [movieTitles addObject:[video title]];
                }
            }
        }
	}
    
    NSArray *currentWindowOrder = [NSApp orderedWindows];
    
    NSNumber *mainWindowOrder = [NSNumber numberWithInteger:[currentWindowOrder indexOfObject:mMovieWindow]];
    
    NSObject* storedRange = nil;
    if(visibleOverviewTimeline)
    {
        storedRange = [NSValue valueWithCMTimeRange:[overviewTimelineView selection]];
    }
    else
    {
        storedRange = [NSNull null];
    }
    
	NSDictionary *mainStateDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithFloat:time],@"CurrentTime",
								   movieTitles,@"MovieTitles",
                                   movieIDs,@"MovieIDs",
                                   movieEnabledStates,@"MovieEnabledStates",
                                   storedRange,@"TimelineSelectedRange",
                                   mainViewClass,@"MainViewClass",
                                   mainViewStateData,@"MainViewStateData",
								   nil];
	
	[states addObject:[NSKeyedArchiver archivedDataWithRootObject:mainStateDict]];
	[classes addObject:@"MainViewState"];
	[rects addObject:NSStringFromRect([mMovieWindow frame])];
	[filters addObject:[NSNull null]];
    [windowOrder addObject:mainWindowOrder];
	
	for(NSObject<AnnotationView> *annotationView in annotationViews)
	{
		if(![annotationView conformsToProtocol:@protocol(DPStateRecording)] || ((id)annotationView == (id)mainView))
		{
			continue;
		}
		
		NSObject<AnnotationView,DPStateRecording> *view = (NSObject<AnnotationView,DPStateRecording>*)annotationView;
		
		BOOL visible = YES;
		
		if([view isKindOfClass:[NSView class]])
		{
			visible = [[(NSView*)view window] isVisible];
		}
		else if([view isKindOfClass:[NSWindowController class]])
		{
			visible = [[(NSWindowController*)view window] isVisible];
		}
		
		if(visible)
		{
		
			NSData *state = [view currentState:stateFlags];
            if(state)
            {
                [states addObject:state];
                [classes addObject:NSStringFromClass([view class])];
                if([view isKindOfClass:[NSView class]])
                {
                    [rects addObject:NSStringFromRect([[(NSView*)view window] frame])];
                    [windowOrder addObject:[NSNumber numberWithInteger:[currentWindowOrder indexOfObject:[(NSView*)view window]]]];
                }
                else if([view isKindOfClass:[NSWindowController class]])
                {
                    [rects addObject:NSStringFromRect([[(NSWindowController*)view window] frame])];
                    [windowOrder addObject:[NSNumber numberWithInteger:[currentWindowOrder indexOfObject:[(NSWindowController*)view window]]]];
                }
                else
                {
                    [rects addObject:[NSNull null]];
                    [windowOrder addObject:[NSNull null]];
                }
                
                
                AnnotationFilter *filter = [view annotationFilter];
                if(filter)
                {
                    [filters addObject:filter];
                }
                else
                {
                    [filters addObject:[NSNull null]];
                }
            }
		}
	}
	
	NSDictionary *stateDict = [NSDictionary dictionaryWithObjectsAndKeys:
							   states,@"states",
							   classes,@"classes",
							   rects,@"rects",
							   filters,@"filters",
                               windowOrder,@"windowOrder",
							   nil];
	
	
	return [NSKeyedArchiver archivedDataWithRootObject:stateDict];
}

- (BOOL)setState:(NSData*)stateData
{
	NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:stateData];
	NSArray *states = [dict objectForKey:@"states"];
	NSArray *classes = [dict objectForKey:@"classes"];
	NSArray *rects = [dict objectForKey:@"rects"];
	NSArray *filters = [dict objectForKey:@"filters"];
	
    NSArray *windowOrder = [dict objectForKey:@"windowOrder"];
	
    BOOL mainIsFront = NO;
    
    for(NSWindowController* windowController in dataWindowControllers)
	{
		[windowController close];
	}
	[dataWindowControllers removeAllObjects];
	mapController = nil;
    
	int i;
	for(i = 0; i < [states count]; i++)
	{
		NSString *class = [classes objectAtIndex:i];
		NSData *state = nil;
		if([states objectAtIndex:i] != [NSNull null])
		{
			state = [states objectAtIndex:i];
		}
		AnnotationFilter *filter = nil;
		if([filters objectAtIndex:i] != [NSNull null])
		{
			filter = [filters objectAtIndex:i];
		}
		
		
		if([class isEqualToString:@"MainViewState"])
		{
			//NSLog(@"Set main window frame: %@",[rects objectAtIndex:i]);
			[mMovieWindow setFrame:NSRectFromString([rects objectAtIndex:i]) display:YES];
			NSDictionary *mainStateDict = [NSKeyedUnarchiver unarchiveObjectWithData:state];
			NSTimeInterval time = [[mainStateDict objectForKey:@"CurrentTime"] floatValue];
			[self moveToTime:CMTimeMakeWithSeconds(time, [[mMovie currentItem] duration].timescale) fromSender:self];
			
            NSString* mainViewSavedClass = [mainStateDict objectForKey:@"MainViewClass"];
            NSData* mainViewStateData = [mainStateDict objectForKey:@"MainViewStateData"];
            if(mainViewSavedClass && ([mainViewStateData length] > 0))
            {
                Class MainViewClass = NSClassFromString(mainViewSavedClass);
                
                NSView<AnnotationView,DPStateRecording> *view = [[MainViewClass alloc] init];
                [view setState:mainViewStateData];
                [self addAnnotationView:view];
                [self replaceMainView:view];
                [view release];
            }
            else
            {
                NSArray *movieIDs = [mainStateDict objectForKey:@"MovieIDs"];
                if(movieIDs)
                {
                    NSArray *movieEnabledStates = [mainStateDict objectForKey:@"MovieEnabledStates"];
                    NSArray *existingMovies = [mMovieView movies];
                    for(AVPlayer* movie in existingMovies)
                    {
                        [mMovieView removeMovie:movie];
                    }
                    
                    int enabledIndex = 0;
                    for(NSString *movieID in movieIDs)
                    {
                        for(VideoProperties *video in [[AnnotationDocument currentDocument] allMediaProperties])
                        {
                            if([movieID isEqualToString:[video uuid]])
                            {
                                [mMovieView addMovie:[video movie]];
                                if(movieEnabledStates)
                                {
                                    [video setEnabled:[[movieEnabledStates objectAtIndex:enabledIndex] boolValue]];
                                    enabledIndex++;
                                }
                            }
                        }
                    }	 
                }
                else
                {
                    NSArray *movieTitles = [mainStateDict objectForKey:@"MovieTitles"];
                    if(movieTitles)
                    {
                        for(NSString *title in movieTitles)
                        {
                            for(VideoProperties *video in [[AnnotationDocument currentDocument] mediaProperties])
                            {
                                if([title isEqualToString:[video title]])
                                {
                                    [mMovieView addMovie:[video movie]];
                                }
                            }
                        }	
                    }
                }
            }
            
            NSObject* timelineSelection = [mainStateDict objectForKey:@"TimelineSelectedRange"];
            if(timelineSelection && (timelineSelection != [NSNull null]))
            {
                [self zoomToTimeRange:[(NSValue*)timelineSelection CMTimeRangeValue]];
            }
            else
            {
                [self zoomToTimeRange:[overviewTimelineView range]];
            }
            
            if([[windowOrder objectAtIndex:i] integerValue] == 0)
            {
                mainIsFront = YES;
            }

		}
		else if([class isEqualToString:@"MultiTimelineView"])
		{
			[timelineView setState:state];
			[self resizeTimelineView];
		}
		else if([class isEqualToString:@"MapView"])
		{
			[self showMap:self];
			[[mapController mapView] setState:state];
			[[mapController mapView] setAnnotationFilter:filter];
			[[mapController window] setFrame:NSRectFromString([rects objectAtIndex:i]) display:NO];
		}
		else if([class isEqualToString:@"MovieViewerController"])
		{
			MovieViewerController *movieViewer = [[MovieViewerController alloc] init];
			[movieViewer setState:state];
			[[movieViewer window] setFrame:NSRectFromString([rects objectAtIndex:i]) display:NO];
			[self addAnnotationView:movieViewer];
			[self addDataWindow:movieViewer];
			[movieViewer release];
		}
		else if([class isEqualToString:@"TranscriptView"])
		{
			NSLog(@"Set state: TranscriptView");
			TranscriptViewController *transcriptViewController = [[TranscriptViewController alloc] init];
			[(NSObject<DPStateRecording>*)[transcriptViewController transcriptView] setState:state];
			[[transcriptViewController window] setFrame:NSRectFromString([rects objectAtIndex:i]) display:NO];
			[self addAnnotationView:(NSObject<AnnotationView>*)[transcriptViewController transcriptView]];
			[self addDataWindow:transcriptViewController];
			[transcriptViewController release];
		}
        else if([class isEqualToString:@"DPSpatialDataView"])
		{
			NSLog(@"Set state: Spatial Data View");
			DPSpatialDataWindowController *spatialViewController = [[DPSpatialDataWindowController alloc] init];
			[(NSObject<DPStateRecording>*)[spatialViewController spatialDataView] setState:state];
			[[spatialViewController window] setFrame:NSRectFromString([rects objectAtIndex:i]) display:NO];
			[self addAnnotationView:(NSObject<AnnotationView>*)[spatialViewController annotationView]];
			[self addDataWindow:spatialViewController];
			[spatialViewController release];
		}
        else if([class rangeOfString:@"TimelineView"].location == NSNotFound)
        {
            Class ViewClass = NSClassFromString(class);
            if([ViewClass isSubclassOfClass:[NSView class]])
            {
                Class ControllerClass = [viewManager controllerClassForViewClass:ViewClass];
                if(ControllerClass && [ControllerClass conformsToProtocol:@protocol(AnnotationViewController)])
                {
                    NSWindowController<AnnotationViewController> *viewController = [[ControllerClass alloc] init];
                    [[viewController window] setFrame:NSRectFromString([rects objectAtIndex:i]) display:NO];
                    [[viewController window] makeKeyAndOrderFront:self];
                    [(NSObject<DPStateRecording>*)[viewController annotationView] setState:state];
                    [self addAnnotationView:(NSObject<AnnotationView>*)[viewController annotationView]];
                    [self addDataWindow:viewController];
                    [viewController release];
                }
                
            }
            
        }
		
	}
    
    if(mainIsFront)
    {
        [mMovieWindow makeKeyAndOrderFront:self];
    }
    
	return YES;
}

#pragma mark Open and Save

- (void)newDocument:(id)sender
{
	[newDocumentWindow makeKeyAndOrderFront:self];
}

- (IBAction)createNewAnnotationDocument:(id)sender
{
	NSLog(@"Create New Document");
	
	[newDocumentWindow close];
	
	if(![self closeDocument])
	{
		return;
	}
	
	NSString *tempDirectoryTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tempannotation.XXXXXX"];
	const char *tempDirectoryTemplateCString = [tempDirectoryTemplate fileSystemRepresentation];
	char *tempDirectoryNameCString = (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
	strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);
	
	char *result = mkdtemp(tempDirectoryNameCString);
	NSString* tempDirectoryPath;
	if (!result)
	{
		// handle directory creation failure
		tempDirectoryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tempannotation.annotation"];
	}
	else
	{
		tempDirectoryPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempDirectoryNameCString length:strlen(result)];
	}
	free(tempDirectoryNameCString);
	
	AnnotationDocument *doc = [[AnnotationDocument alloc] initFromFile:tempDirectoryPath];
    [[doc videoProperties] setStartDate:[NSDate date]];
	[[doc videoProperties] setTitle:@"Untitled Project"];
	[self setAnnotationDocument:doc];
	tempAnnotationDoc = YES;
	[doc release];
}

- (void)openDocument:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	//[openPanel setDelegate:self];
	[openPanel setAllowsMultipleSelection:NO];

    NSArray *types = @[@"annotation",@"chronoviztemplate"];
    types = [types arrayByAddingObjectsFromArray:[AVURLAsset audiovisualTypes]];
    [openPanel setAllowedFileTypes:types];
    
	if ([openPanel runModalForTypes:nil] == NSOKButton) {
		NSString* filename = [openPanel filename];
		
		[self application:[NSApplication sharedApplication] openFile:filename];

	}
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{	
	if(![self closeDocument])
	{
		return NO;
	}
	
	backupAnnotationFile = nil;
	
	if(![[filename pathExtension] isEqualToString:@"annotation"]
       && ![[filename pathExtension] isEqualToString:@"chronoviztemplate"])
	{
		AnnotationDocument *doc = [[AnnotationDocument alloc] initForVideo:filename];
		if(doc)
		{
			[self setAnnotationDocument:doc];
			[doc release];
			if([[[doc videoProperties] title] length] < 1)
			{
				[[doc videoProperties] setTitle:[[[[doc videoProperties] videoFile] lastPathComponent] stringByDeletingPathExtension]];
				[self showVideoProperties:self];
			}
		}
		else
		{
			// Failed to open document for some reason, so create a blank document instead
			[self createNewAnnotationDocument:self];
		}
	}
    else if([[filename pathExtension] isEqualToString:@"chronoviztemplate"])
	{
        DPDocumentTemplate *template = [[DPDocumentTemplate alloc] initFromURL:[NSURL fileURLWithPath:filename]];
        if(template)
        {
            [self createNewAnnotationDocument:nil];
            [template applyToDocument:annotationDoc];
            [template release];
        }
		
	}
	else
	{
		if([[NSUserDefaults standardUserDefaults] boolForKey:AFCreateFileBackupKey])
		{
			NSFileManager *manager = [NSFileManager defaultManager];
			NSError *err = nil;
			
			backupAnnotationFile = [[filename stringByDeletingPathExtension] stringByAppendingString:@"-cvBackup.annotation"];
			if([manager fileExistsAtPath:backupAnnotationFile])
			{
				if([[NSUserDefaults standardUserDefaults] boolForKey:AFOverwriteFileBackupKey])
				{
					[manager removeItemAtPath:backupAnnotationFile error:&err];
				}
				else
				{
					int copy = 2;
					while([manager fileExistsAtPath:backupAnnotationFile])
					{
						backupAnnotationFile = [[filename stringByDeletingPathExtension] stringByAppendingFormat:@"-cvBackup-%i.annotation",copy];
						copy++;
					}
				}
			}
			
			if([manager copyItemAtPath:filename toPath:backupAnnotationFile error:&err])
			{
				[backupAnnotationFile retain];
			}
			else
			{
				backupAnnotationFile = nil;
				NSAlert *alert = [[NSAlert alloc] init];
				[alert setMessageText:
				 [NSString stringWithFormat:@"A backup version of %@ could not be created. Would you like to continue opening the file?",[filename lastPathComponent]]];
				[alert addButtonWithTitle:@"Continue Opening"];
				[alert addButtonWithTitle:@"Cancel Opening"];
				
				NSInteger result = [alert runModal];
				[alert release];
				if(result == NSAlertFirstButtonReturn)
				{
				}
				else
				{
					[self createNewAnnotationDocument:self];
					return NO;
				}
			}
		}
		
		NSLog(@"Start loading document");
        
		AnnotationDocument *doc = [[AnnotationDocument alloc] initFromFile:filename];
        
        NSLog(@"Finish loading document");
		if(doc)
		{
			[self setAnnotationDocument:doc];
		}
		else
		{
			// Failed to open document for some reason, so create a blank document instead
			[self createNewAnnotationDocument:self];
		}
		
		[doc release];
	}
	
	return (annotationDoc != nil);
}

- (IBAction)revertToBackup:(id)sender
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Are you sure you want to revert to the backup version?"];
	[alert setInformativeText:@"All changes since opening this file will be lost."];
	[alert addButtonWithTitle:@"Revert to Backup"];
	[alert addButtonWithTitle:@"Cancel"];
	
	NSInteger result = [alert runModal];
	[alert release];
	if(result == NSAlertSecondButtonReturn)
	{
		return;
	}
	
	NSFileManager *manager = [NSFileManager defaultManager];
	if(backupAnnotationFile 
	   && [manager fileExistsAtPath:backupAnnotationFile])
	{
		NSError *err = nil;
		
		NSString *filepath = [[[AnnotationDocument currentDocument] annotationsDirectory] copy];
		NSString *backupFilePath = [backupAnnotationFile copy];
		[backupAnnotationFile release];
		backupAnnotationFile = nil;
		
		[self closeDocument];
		[manager removeItemAtPath:filepath error:&err];
		if(err)
		{
			NSLog(@"%@",[err localizedDescription]);
		}
		[manager moveItemAtPath:backupFilePath toPath:filepath error:&err];
		if(err)
		{
			NSLog(@"%@",[err localizedDescription]);
		}
		[self application:[NSApplication sharedApplication] openFile:filepath];
		
		[filepath release];
		[backupFilePath release];
		
	}
}

- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename
{
	BOOL isDir = NO;
	
	[[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDir];
	
	if(isDir || [filename isAliasFinderInfoFlag])
	{
		return YES;
	}
	else
	{
		return ([[filename pathExtension] isEqualToString:@"annotation"]
                || [[filename pathExtension] isEqualToString:@"chronoviztemplate"]
                || [VideoDataSource validateFileName:filename]);
	}
}

- (IBAction)saveAnnotationsAs:(id)sender
{
	annotationsSavePanel = [NSSavePanel savePanel];
	[annotationsSavePanel setTitle:@"Save Annotations"];
	[annotationsSavePanel setExtensionHidden:NO];
	[annotationsSavePanel setCanSelectHiddenExtension:YES];
	
	AnnotationFileType* type = [AnnotationFileType annotationFileType];
	[annotationsSavePanel setRequiredFileType:[type extension]];
	[annotationsSavePanel setExtensionHidden:YES];
	
	// files are filtered through the panel:shouldShowFilename: method above
	if ([annotationsSavePanel runModalForDirectory:nil file:@"annotations"] == NSOKButton) {
		
		NSString *tempDir = nil;
		if(tempAnnotationDoc)
		{
			tempDir = [[annotationDoc annotationsDirectory] retain];
		}
		
		[annotationDoc saveToPackage:[annotationsSavePanel filename]];
		[annotationDoc saveState:[self currentState:nil]];
		[[self window] setTitle:[[[annotationDoc annotationsDirectory] lastPathComponent] stringByDeletingPathExtension]];
        
		if(tempDir)
		{
			NSLog(@"Delete %@",tempDir);
			NSError *error;
			[[NSFileManager defaultManager] removeItemAtPath:tempDir error:&error];
			[tempDir release];
		}
		
		tempAnnotationDoc = NO;
	}
	annotationsSavePanel = nil;
}

- (void)showDocumentLoading:(id)sender
{
    if(!documentLoadingWindow)
    {
        NSString *documentName = @"";
        if([sender isKindOfClass:[AnnotationDocument class]])
        {
            documentName = [[[(AnnotationDocument*)sender annotationsDirectory] lastPathComponent] stringByDeletingPathExtension];
        }
        
        [NSApp beginSheet:[self documentLoadingWindow:documentName]
           modalForWindow:[self window]
            modalDelegate:nil
           didEndSelector:NULL
              contextInfo:nil];
    }

}

- (void)endDocumentLoading:(id)sender
{
    if(documentLoadingWindow)
    {
        [NSApp endSheet:documentLoadingWindow];
        [documentLoadingWindow orderOut:self];
        [documentLoadingWindow release];
        documentLoadingWindow = nil;
    }
}

- (NSWindow*)documentLoadingWindow:(NSString*)filename
{
	if(documentLoadingWindow)
	{
        [documentLoadingWindow release];
    }
        
    documentLoadingWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(200,400,480,120)
                                                 styleMask:NSTitledWindowMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
    [documentLoadingWindow setReleasedWhenClosed:NO];
    
    NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(18, 56, 444, 20)];
    [progressIndicator setIndeterminate:YES];
    
//		cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(370,12,96,32)];
//		[cancelButton setBezelStyle:NSRoundedBezelStyle];
//		[cancelButton setTitle:@"Cancel"];
//		[cancelButton setAction:@selector(cancelExtraction:)];
//		[cancelButton setTarget:self];
//		[cancelButton setEnabled:NO];
    
    NSTextField *progressTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(17, 84, 444, 17)];
    [progressTextField setStringValue:[NSString stringWithFormat:@"Loading document %@ …",filename]];
    [progressTextField setEditable:NO];
    [progressTextField setDrawsBackground:NO];
    [progressTextField setBordered:NO];
    [progressTextField setAlignment:NSLeftTextAlignment];
    
    [[documentLoadingWindow contentView] addSubview:progressIndicator];
    //[[documentLoadingWindow contentView] addSubview:cancelButton];
    [[documentLoadingWindow contentView] addSubview:progressTextField];
    
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator startAnimation:self];
    
    [progressIndicator release];
    [progressTextField release];
    
	return documentLoadingWindow;
}

#pragma mark Import and Export

- (IBAction)loadXMLAnnotations:(id)sender
{
//	NSAlert *noImportAlert = [[NSAlert alloc] init];
//	[noImportAlert setMessageText:@"Importing annotations is not currently supported"];
//	[noImportAlert runModal];
//	
//	return;
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:@"Select Annotations File"];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"annotation",@"xml", nil]];
	//[openPanel setRequiredFileType:@"annotation"];
	[openPanel setAllowsMultipleSelection:NO];
	
	if([openPanel runModal] == NSOKButton) {
		NSString *file = [openPanel filename];
		[self loadAnnotations:file];
	}
}

- (void)loadAnnotations:(NSString*)filename
{
    NSString *annotationFile = nil;
    if([[filename pathExtension] caseInsensitiveCompare:@"xml"] == NSOrderedSame)
    {
        annotationFile = filename;
    }
    else if ([[filename pathExtension] caseInsensitiveCompare:@"annotation"] == NSOrderedSame)
    {
        annotationFile = [filename stringByAppendingPathComponent:@"annotations.xml"];
    }
	
	AnnotationXMLParser *tempParser = [[AnnotationXMLParser alloc] initWithFile:annotationFile forDocument:annotationDoc];
	
	NSString *categoryName = [[filename lastPathComponent] stringByDeletingPathExtension];
	AnnotationCategory *sourceCategory = [annotationDoc categoryForName:categoryName];
	if(!sourceCategory)
	{
		sourceCategory = [annotationDoc createCategoryWithName:categoryName];
	}
	else
	{
		int i = 0;
		while(sourceCategory)
		{
			i++;
			sourceCategory = [annotationDoc categoryForName:[categoryName stringByAppendingFormat:@" - %i",i]];
		}
		sourceCategory = [annotationDoc createCategoryWithName:[categoryName stringByAppendingFormat:@" - %i",i]];
	}
	[sourceCategory autoColor];
	
    InternalDataSource *source = [[InternalDataSource alloc] initWithPath:@""];
    [source setName:[NSString stringWithFormat:@"Annotations from %@",[[filename lastPathComponent] stringByDeletingPathExtension]]];
    AnnotationSet *annotationSet = [[AnnotationSet alloc] init];
    [source addDataSet:annotationSet];
    
	for(Annotation *annotation in [tempParser annotations])
	{
		[annotation setSource:filename];
		[annotation addCategory:sourceCategory];
        [annotationSet addAnnotation:annotation];
	}
	
    [annotationDoc addDataSource:source];
	[annotationDoc addAnnotations:[tempParser annotations]];
    
	[tempParser release];
	
}

- (IBAction)export:(id)sender
{
	DPExport *exporter = [sender representedObject];
	[exporter export:annotationDoc];
}

- (IBAction)exportAnnotations:(id)sender
{
	annotationsSavePanel = [NSSavePanel savePanel];
	[annotationsSavePanel setTitle:@"Save Annotations"];
	[annotationsSavePanel setExtensionHidden:NO];
	[annotationsSavePanel setCanSelectHiddenExtension:YES];
	
	[saveFileTypesButton selectItemWithTitle:[[AnnotationFileType xmlFileType] description]];
	[annotationsSavePanel setAccessoryView:saveAsView];
	[annotationsSavePanel setRequiredFileType:[[AnnotationFileType xmlFileType] extension]];
	
	// files are filtered through the panel:shouldShowFilename: method above
	if ([annotationsSavePanel runModalForDirectory:nil file:@"annotations.xml"] == NSOKButton) {
		AnnotationFileType* type = (AnnotationFileType*)[[saveFileTypesButton selectedItem] representedObject];
		if(type == [AnnotationFileType xmlFileType])
		{
			[self saveXMLAnnotationsToFile:[annotationsSavePanel filename]];
		}
		else if(type == [AnnotationFileType annotationFileType])
		{
			[annotationDoc saveToPackage:[annotationsSavePanel filename]];
		}
		else if(type == [AnnotationFileType csvFileType])
		{
			[self saveCSVAnnotationsToFile:[annotationsSavePanel filename]];
		}
	}
	annotationsSavePanel = nil;
}

- (IBAction)changeSaveFileType:(id)sender
{
	if(annotationsSavePanel)
	{
		[annotationsSavePanel setRequiredFileType:[[[saveFileTypesButton selectedItem] representedObject] extension]];
	}
}

- (void)saveXMLAnnotationsToFile:(NSString*)filename
{
	AnnotationXMLParser *newData = [[AnnotationXMLParser alloc] init];
	
	// Otherwise, the xmlRepresentation point of the Annotation will change
	[newData setUpdateAnnotations:NO];
	
	for(Annotation* annotation in [annotationDoc annotations])
	{
		[newData addAnnotation:annotation];
	}
	[newData writeToFile:filename];
	[newData release];
}

- (void)saveCSVAnnotationsToFile:(NSString*)filename
{
	NSError *error;
	NSMutableString *output = [NSMutableString string];
	[output appendString:@"StartTime,EndTime,Title,Annotation,MainCategory,Category2,Category3\n"];
	for(Annotation* annotation in [annotationDoc annotations])
	{
		[output appendFormat:@"%@,%@,%@,%@,%@",
		 [annotation startTimeString],
		 [annotation endTimeString],
		 [annotation.title csvEscapedString],
		 [annotation.annotation csvEscapedString],
		 [[annotationDoc identifierForCategory:[annotation category]] csvEscapedString]];
		for(AnnotationCategory *category in [annotation categories])
		{
			if(category != [annotation category])
			{
				[output appendFormat:@",%@",[category name]];
			}
		}
		[output appendString:@"\n"];
	}
	[output writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:&error];
}

- (IBAction)importData:(id)sender
{
	LinkedFilesController *linkedFiles = [self linkedFilesController];
	
	[linkedFiles addData:self];
	
}

//- (IBAction)importMedia:(id)sender
//{
//	if(tempAnnotationDoc)
//	{
//		NSAlert *alert = [[NSAlert alloc] init];
//		[alert setMessageText:@"There are currently no other videos loaded. Do you want to select a main video instead?"];
//		[alert setInformativeText:@"The main video appears above the timelines, while secondary videos appear in a separate window. The main video also determines the duration of the timelines and sets the time basis for annotations and data."];
//		[alert addButtonWithTitle:@"Select Main Video"];
//		[alert addButtonWithTitle:@"Add Secondary Media"];
//		[alert addButtonWithTitle:@"Cancel"];
//		
//		NSInteger result = [alert runModal];
//		if(result == NSAlertFirstButtonReturn)
//		{
//			[self openDocument:nil];
//			return;
//		}
//		else if (result == NSAlertThirdButtonReturn)
//		{
//			return;
//		}
//	}
//	
//	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
//	[openPanel setTitle:@"Select Media File"];
//	[openPanel setAllowsMultipleSelection:NO];
//	[openPanel setDelegate:self];
//	
//	if([openPanel runModalForTypes:nil] == NSOKButton) {
//		
//		if(![[[openPanel filename] pathExtension] isEqualToString:@"annotation"])
//		{
//			VideoProperties *properties = [annotationDoc addMediaFile:[openPanel filename]];
//			[properties setTitle:[[[properties videoFile] lastPathComponent] stringByDeletingPathExtension]];
//			
//			if(properties)
//			{
//				[self registerMedia:properties andDisplay:YES];
//				
//				if(!videoPropertiesController) {
//					videoPropertiesController = [[VideoPropertiesController alloc] init];
//				}
//				
//				[videoPropertiesController setVideoProperties:properties];
//				[videoPropertiesController setAnnotationDoc:annotationDoc];
//				[videoPropertiesController showWindow:self];
//				[[videoPropertiesController window] makeKeyAndOrderFront:self];
//			}
//		}
//	}
//}

- (void)registerMedia:(VideoProperties*)properties andDisplay:(BOOL)show
{
	if(properties && show)
	{
		// If the movie is already being shown, ignore this message.
		for(id view in annotationViews)
		{
			if([view isKindOfClass:[MovieViewerController class]])
			{
				if([view videoProperties] == properties)
				{
					if(show)
					{
						[view showWindow:self];
					}
					return;
				}
			}
		}
		
		if([properties hasVideo])
		{
			MovieViewerController *movieViewer = [[MovieViewerController alloc] init];
			//[[movieViewer movieView] setMovie:[properties movie]];
			[movieViewer setVideoProperties:properties];
			//[[movieViewer window] setContentSize:contentSize];
			[movieViewer showWindow:self];
			[[movieViewer window] makeKeyAndOrderFront:self];
			[self addDataWindow:movieViewer];
			[self addAnnotationView:movieViewer];
			[movieViewer release];
		}
		else if([properties hasAudio])
		{
            [viewManager performSelectorOnMainThread:@selector(createAudioTimeline:)
                                   withObject:properties
                                waitUntilDone:NO
                                        modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
		}
	}
}

- (IBAction)showMediaFromObject:(id)sender
{
	VideoProperties* properties = [sender representedObject];
	if(properties)
	{
		[self showMedia:properties];
	}
}

- (void)showMedia:(VideoProperties*)videoProperties
{
	if([videoProperties hasVideo])
	{
		for(id view in annotationViews)
		{
			if([view isMemberOfClass:[MovieViewerController class]])
			{
				if([view videoProperties] == videoProperties)
				{
					[view showWindow:self];
					[[view window] makeKeyAndOrderFront:self];
					return;
				}
			}
		}
		[self registerMedia:videoProperties andDisplay:YES];
	}
	else if([videoProperties hasAudio])
	{
		for(TimelineView* timeline in [timelineView timelines])
		{
			if([[timeline segmentVisualizer] videoProperties] == videoProperties)
			{
				return;
			}
		}
		[self registerMedia:videoProperties andDisplay:YES];
	}
}

- (void)removeMedia:(VideoProperties*)videoProperties
{
	MovieViewerController *movieView = nil;
	for(id view in annotationViews)
	{
		if([view isMemberOfClass:[MovieViewerController class]])
		{
			if([view videoProperties] == videoProperties)
			{
				movieView = view;
				break;
			}
		}
	}
	if(movieView)
	{
		[movieView close];
		[self removeAnnotationView:movieView];
	}
	
	NSArray *timelines = [[timelineView timelines] copy];
	for(TimelineView* timeline in timelines)
	{
		if([[timeline segmentVisualizer] videoProperties] == videoProperties)
		{
			[timelineView removeTimeline:timeline];
		}
	}
	[timelines release];
	
	//[annotationDoc removeVideo:videoProperties];
}

- (IBAction)showDataAction:(id)sender
{
	NSObject* object = (NSObject*)[sender representedObject];
	if([object isKindOfClass:[TimeCodedData class]])
	{
		[viewManager showData:(TimeCodedData*)object];
	}
}


#pragma mark Annotation

- (IBAction)newAnnotation:(id)sender
{
	if(!mMovie)
	{
		[self openDocument:self];
		return;
	}
	
	if(pauseWhileAnnotating && playing)
	{
		[self togglePlay:self];
		paused = YES;
	}
	
	Annotation *annotation = [[Annotation alloc] initWithCMTime:[mainVideo.playerItem currentTime]];
	[annotation setAnnotation:@"New Annotation…"];

	[annotationDoc addAnnotation:annotation];
	
	[annotation release];
	
	[self setSelectedAnnotation:annotation];
	
	[self showAnnotationInspector:self];
	
}

- (void)handleUpdateAnnotationNotification:(NSNotification*)notification
{
	NSObject *obj = [notification object];
	if([obj isKindOfClass:[Annotation class]] && [[annotationDoc annotations] containsObject:obj])
	{
		[self updateAnnotation:(Annotation*)obj];
	}
}

- (void)updateAnnotation:(Annotation*)annotation
{
	//NSLog(@"update annotation: %@",[annotation title]);
	[[annotationDoc xmlParser] updateAnnotation:annotation];
	for(NSObject<AnnotationView> *view in annotationViews)
	{
		[view updateAnnotation:annotation];
	}
}

- (IBAction)removeCurrentAnnotation:(id)sender
{
	Annotation *annotation = [self selectedAnnotation];
	
	//[inspector annotation];
	//[[inspector window] close];
	
	[self setSelectedAnnotation:nil];
	
	[annotationDoc removeAnnotation:annotation];
}

- (void)setSelectedAnnotation:(Annotation*)annotation
{
	if(!(annotation == selectedAnnotation))
	{
		[self willChangeValueForKey:@"selectedAnnotation"];
		
		// If we're de-selecting, get rid of the timeline
		if(!annotation && selectedAnnotation)
		{				
			TimelineView *subView = [[timelineView baseTimeline] subTimelineView];
			if(subView)
			{
				[timelineView removeTimeline:subView];
			}
		}
		
		[selectedAnnotation setSelected:NO];
		[annotation setSelected:YES];
		[selectedAnnotation release];
		selectedAnnotation = [annotation retain];

//		if(!annotation)
//		{
//			if([[timelineView timelines] count] > 1)
//			{
//				[timelineView removeHighestTimeline];
//				float newPosition = [splitView bounds].size.height - ([splitView dividerThickness] + [timelineView frame].size.height / 1.79);
//				[splitView setPosition:newPosition ofDividerAtIndex:0];
//			}
//		}
		
		[self didChangeValueForKey:@"selectedAnnotation"];

	}
}

- (IBAction)updateAllKeyframes:(id)sender
{
	forceKeyframeUpdate = YES;
	for(Annotation *annotation in [annotationDoc annotations])
	{
		[self updateAnnotationKeyframe:annotation];
	}
	forceKeyframeUpdate = NO;
	
}

- (void)updateAnnotationKeyframe:(Annotation*)annotation
{
	if([annotation keyframeImage])
	{
		double timecode = [annotation startTimeSeconds]*[mainVideo.playerItem currentTime].timescale;
		NSString *imageName = [NSString stringWithFormat:@"%i.jpg",(int)round(timecode)];
		
		// If the file isn't changing, then we're done (unless we're forcing an update)
		if(!forceKeyframeUpdate && [[NSString stringWithFormat:@"images/%@",imageName] isEqualToString:[[annotation image] relativeString]])
			return;
		
		// Otherwise get delete the old file and create a new one
		[self deleteKeyframeFile:annotation];
		
        AVAsset *asset = [[mMovie currentItem] asset];
        CGImageRef imageRef = [VideoFrameLoader generateImageAt:[annotation startTime] for:asset error:nil];
        NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
		[annotation setFrameRepresentation:image];
        
        NSData *imageData = [image TIFFRepresentation];
        NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
        imageData = [imageRep representationUsingType:NSJPEGFileType properties:options];
        [imageData writeToFile:[[annotationDoc annotationsImageDirectory] stringByAppendingPathComponent:imageName] atomically:NO];
        
        [image release];
		[annotation setImage:[NSURL URLWithString:[NSString stringWithFormat:@"images/%@",imageName]]];
	}
}

- (BOOL)deleteKeyframeFile:(Annotation*)annotation
{
	if([annotation image] && ([[[annotation image] relativeString] length] > 0))
	{
		NSString *imageFile = [[annotationDoc annotationsDirectory] stringByAppendingPathComponent:[[annotation image] relativeString]];
		if([[NSFileManager defaultManager] fileExistsAtPath:imageFile])
		{
			NSLog(@"Delete %@",imageFile);
			NSError *error;
			return [[NSFileManager defaultManager] removeItemAtPath:imageFile error:&error];
		}
	}
	return NO;
}

- (void)loadAnnotationKeyframeImage:(Annotation*)annotation
{
	if(![annotation image])
	{
		[self updateAnnotationKeyframe:annotation];
	}
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:[[annotationDoc annotationsDirectory] stringByAppendingPathComponent:[[annotation image] relativeString]]];
	[annotation setFrameRepresentation:image];
	[image release];
}

- (void)addAnnotation:(Annotation*)annotation
{
	
	for(id <AnnotationView> view in annotationViews)
	{
		[view addAnnotation:annotation];
	}
	
	[timelineView showAnnotation:annotation];
	[timelineView redrawSegments];
	
	[undoManager registerUndoWithTarget:self selector:@selector(removeAnnotation:) object:annotation];
	if([undoManager isUndoing])
	{
		[undoManager setActionName:@"Delete Annotation"];
	}
	else 
	{
		[undoManager setActionName:@"Add Annotation"];
	}	
}

- (void)removeAnnotation:(Annotation*)annotation
{
	[undoManager registerUndoWithTarget:annotationDoc selector:@selector(addAnnotation:) object:annotation];
	if([undoManager isUndoing])
	{
		[undoManager setActionName:@"Add Annotation"];
	}
	else 
	{
		[undoManager setActionName:@"Delete Annotation"];
	}	
	
	for(id <AnnotationView> view in annotationViews)
	{
		[view removeAnnotation:annotation];
	}
	
	[self deleteKeyframeFile:annotation];
}


- (IBAction)showAnnotationInspector:(id)sender
{
	[[inspector window] makeKeyAndOrderFront:self];
}

- (IBAction)showAnnotationQuickEntry:(id)sender
{
	[self showAnnotationQuickEntryForCategory:nil];
}

- (void)showAnnotationQuickEntryForCategory:(AnnotationCategory*)category
{
	if(pauseWhileAnnotating && playing)
	{
		[self togglePlay:nil];
		paused = YES;
	}
	
	[quickEntry setEntryTarget:self];
	[quickEntry setEntrySelector:@selector(resumePlaying)];
	[quickEntry displayQuickEntryWindowAtTime:[mainVideo.playerItem currentTime]
								   inTimeline:[timelineView activeTimeline]
								  forCategory:category];
}

- (void)displayHoverForTimelineMarker:(TimelineMarker*)marker
{
	[NSTimer scheduledTimerWithTimeInterval:0.1
									 target:self
								   selector:@selector(showHoverAfterDelay:)
								   userInfo:marker 
									repeats:NO];
}
	 
- (void)showHoverAfterDelay:(NSTimer*)hoverTimer
{
	TimelineMarker *marker = [hoverTimer userInfo];
	if(popUpAnnotations && [marker highlighted])
	{
		[annotationHover displayForTimelineMarker:marker];
	}
}

- (void)closeHoverForMarker:(TimelineMarker*)marker
{
	if(popUpAnnotations)
	{
		if(!marker)
		{
			[annotationHover close];
		}
		else
		{
			[annotationHover closeForTimelineMarker:marker];
		}
	}
}

- (void)selectTimelineMarker:(TimelineMarker*)marker
{
	Annotation *annotation = [marker annotation];
	if(annotation)
	{
		[annotationHover close];
		[self setSelectedAnnotation:annotation];
		[self showAnnotationInspector:self];
	}
}

- (AnnotationFiltersController*)annotationFiltersController
{
	if(!annotationFiltersController)
	{
		annotationFiltersController = [[AnnotationFiltersController alloc] init];
	}
	return annotationFiltersController;
}

#pragma mark Views

- (IBAction)saveCurrentState:(id)sender
{
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Please enter a name for the configuration."];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    
    NSTextField *nameInputField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 22)];
    [nameInputField setStringValue:@"Saved Configuration"];
    [alert setAccessoryView:nameInputField];
    
    //[[alert window] makeFirstResponder:nameInputField];
    
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nameInputField];
    [nameInputField selectText:self];
}

- (IBAction)clearSavedStates:(id)sender
{
    NSAlert *clearStatesAlert = [[NSAlert alloc] init];
    [clearStatesAlert setMessageText:@"Are you sure you want to clear the saved configurations?"];
    [clearStatesAlert setInformativeText:@"Clearing the saved configurations will permanently delete all saved configurations."];
    [clearStatesAlert addButtonWithTitle:@"Clear Configurations"];
    [clearStatesAlert addButtonWithTitle:@"Cancel"];
    
    NSInteger response = [clearStatesAlert runModal];
    
    if(response == NSAlertFirstButtonReturn)
    {
        NSArray *names = [annotationDoc savedStates];
        for(NSString *name in names)
        {
            [annotationDoc removeStateNamed:name];
        }
        
        [self refreshSavedStatesMenu];
    }
}
    
-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    NSTextField *nameInputField = (NSTextField*)contextInfo;
    if (returnCode == NSAlertFirstButtonReturn) {
        NSString *stateName = [nameInputField stringValue];
        [annotationDoc saveState:[self currentState:nil] withName:stateName];
        [self refreshSavedStatesMenu];
    }
    [nameInputField release];
}

- (void)refreshSavedStatesMenu
{
    NSArray *savedStates = [annotationDoc savedStates];
    
    while([[savedStatesMenu itemArray] count] > 1)
    {
        [savedStatesMenu removeItemAtIndex:1];
    }
    
    if([savedStates count] > 0)
    {
        NSMenuItem *clearStatesItem = [savedStatesMenu addItemWithTitle:@"Clear Saved Configurations" action:@selector(clearSavedStates:) keyEquivalent:@""];
        [clearStatesItem setTarget:self];
        [savedStatesMenu addItem:[NSMenuItem separatorItem]];
    }
    
    for(NSString* stateName in savedStates)
    {
        NSMenuItem* menuItem = [savedStatesMenu addItemWithTitle:stateName action:@selector(restoreSavedState:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:[annotationDoc stateForName:stateName]];
    }

}

- (IBAction)restoreSavedState:(id)sender
{
    NSData *stateData = [sender representedObject];
    if(stateData)
    {
        [self setState:stateData];
    }
}

- (void)replaceMainView:(NSView*)view
{
    [view setFrame:[mainView frame]];
	[[mainView superview] replaceSubview:mainView with:view];
	mainView = view;
	[[self window] makeFirstResponder:view];
	
	[self updateDisplay:nil];
}

- (void)resizeTimelineView
{
	int numTimelines = [[timelineView timelines] count];
	float interTimelineSpace = [timelineView interTimelineSpace];
	float timelineHeight = [timelineView timelineHeight];
	
	float totalSize = (numTimelines * timelineHeight) + ((numTimelines - 1) * interTimelineSpace);
	
	float newPosition = [splitView bounds].size.height - ([splitView dividerThickness] + totalSize) - 2;
    if(newPosition < 0)
    {
        newPosition = 0;
        timelineView.timelineHeight = MIN_TIMELINE_HEIGHT/2.0;
    }
	[timelineView setNeedsLayout:YES];
	[splitView setPosition:newPosition ofDividerAtIndex:0];
	// If the split position doesn't change, we still want to force it to re-layout the timelines
	if([timelineView needsLayout])
	{
		[timelineView layoutTimelines];
	}
    
    CGFloat minimumHeight = (numTimelines * (MIN_TIMELINE_HEIGHT + interTimelineSpace)) - interTimelineSpace;
    [(PrioritySplitViewDelegate*)[splitView delegate] setMinimumLength:minimumHeight forViewAtIndex:1];
    
    NSSize minSize = [mMovieWindow minSize];
    minSize.height = ([mMovieWindow frame].size.height - [splitView frame].size.height) + minimumHeight;
    [mMovieWindow setMinSize:minSize];
	
	//NSLog(@"TimelineHeight: %f, Position: %f",timelineHeight, newPosition);
    
}

- (void)addAnnotationView:(id <AnnotationView>)view
{
	[view addAnnotations:[annotationDoc annotations]];
	[annotationViews addObject:view];
}

- (void)removeAnnotationView:(id <AnnotationView>)view
{
	[annotationViews removeObject:view];
}

- (void)addDataWindow:(NSWindowController*)dataWindow
{
	[dataWindowControllers addObject:dataWindow];
}

- (void)removeDataWindow:(NSWindowController*)dataWindow
{
	if([dataWindowControllers containsObject:dataWindow])
	{
		[dataWindow close];
		[dataWindowControllers removeObject:dataWindow];
	}
}

- (IBAction)showMap:(id)sender
{
	if(!mapController)
	{
		mapController = [[MapController alloc] init];
		[self addDataWindow:mapController];
		[mapController release];
	}
	[mapController showWindow:self];
	[[mapController window] makeKeyAndOrderFront:self];
	
	if(![annotationViews containsObject:[mapController mapView]])
	{
		[self addAnnotationView:[mapController mapView]];
	}
}

- (IBAction)showPluginScripts:(id)sender
{
	if(!pluginScriptController)
	{
		pluginScriptController = [[PluginScriptController alloc] init];
	}
	[pluginScriptController showWindow:self];
	[[pluginScriptController window] makeKeyAndOrderFront:self];
}

- (IBAction)showAnnotationTable:(id)sender
{
	if(!annotationTableController)
	{
		annotationTableController = [[AnnotationTableController alloc] init];
		[self addAnnotationView:annotationTableController];
	}
	[annotationTableController showWindow:self];
	[[annotationTableController window] makeKeyAndOrderFront:self];
}

//- (void)showImageSequence:(TimeCodedImageFiles*)sequence inMainWindow:(BOOL)mainWindow;
//{
//	if(mainWindow)
//	{
//		NSRect movieFrame = [mainView frame];
//		
//		if(imageSequenceView)
//		{
//			[imageSequenceView release];
//		}
//			
//		
//		imageSequenceView = [[ImageSequenceView alloc] initWithFrame:movieFrame];
//		[imageSequenceView setTimeCodedImageFiles:sequence];
//		
//		[self replaceMainView:imageSequenceView];
//	}
//	else
//	{
//		if(!imageSequenceController)
//		{
//			imageSequenceController = [[ImageSequenceController alloc] init];
//			imageSequenceView = [[imageSequenceController imageSequenceView] retain];
//		}
//		[[imageSequenceController imageSequenceView] setTimeCodedImageFiles:sequence];
//		[imageSequenceController showWindow:self];
//		[[imageSequenceController window] makeKeyAndOrderFront:self];
//	}
//	
//
//}

- (IBAction)addTimeline:(id)sender
{
    if([[timelineView timelines] count] >= [timelineView maxTimelines])
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Another timeline can't be added because it would make the timelines too small.\n\nTo add another timeline, either increase the size of the window or remove existing timelines."];
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:nil
                         didEndSelector:NULL
                            contextInfo:NULL];
        [alert release];
    }
    else
    {
    
        [timelineSelectionView reloadData];
        [timelineSelectionView expandItem:nil expandChildren:YES];
        [timelineSelectionView deselectAll:self];
        //[timelineSelectionView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
        
        [NSApp beginSheet:timelineSelectionPanel
           modalForWindow:[self window]
            modalDelegate:nil
           didEndSelector:NULL
              contextInfo:nil];
    }
}

- (IBAction)cancelAddTimeline:(id)sender
{
	[NSApp endSheet:timelineSelectionPanel];
	[timelineSelectionPanel orderOut:self];
}

#pragma mark Interface Control

- (IBAction)doubleSize:(id)sender
{
	[self zoom:2];
}

- (IBAction)normalSize:(id)sender
{
	[self zoom:1];
}

- (IBAction)tripleSize:(id)sender
{
	[self zoom:3];
}


- (void)zoom:(float)factor
{
	NSRect currWindowBounds, newWindowBounds;
	NSPoint topLeft;
	static BOOL nowSizing = NO;
	
	zoomFactor = factor;
	
	if(nowSizing) return;
    
	nowSizing = YES;
	
	float timelineHeight = [timelineView bounds].size.height;
	float footer = [[mMovieWindow contentView] bounds].size.height - [splitView bounds].size.height;
    NSSize contentSize = (NSSize)[[[[mainVideo.playerItem asset] tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
	contentSize.width = contentSize.width * zoomFactor;
	contentSize.height = contentSize.height * zoomFactor;
	contentSize.height += (footer + timelineHeight + [splitView dividerThickness]);
	
	currWindowBounds = [[mMovieView window] frame];
	topLeft.x = currWindowBounds.origin.x;
	topLeft.y = currWindowBounds.origin.y + currWindowBounds.size.height;
	
	if(contentSize.width < [mMovieWindow minSize].width)
	{
		contentSize.width = [mMovieWindow minSize].width;
	}
	
	newWindowBounds = [[mMovieView window] frameRectForContentRect:NSMakeRect(0,0,contentSize.width,contentSize.height)];
	
	[[mMovieView window] setFrame:NSMakeRect(topLeft.x, topLeft.y - newWindowBounds.size.height, newWindowBounds.size.width, newWindowBounds.size.height) display:YES];
	
	[timelineView setResizing:YES];
	
	float newPosition = [splitView bounds].size.height - ([splitView dividerThickness] + timelineHeight) - 2;
	[splitView setPosition:newPosition ofDividerAtIndex:0];
	
	[timelineView layoutTimelines];
	[timelineView setResizing:NO];
	[timelineView resetTrackingAreas];
	
	nowSizing = NO;
	
}

- (IBAction)openPluginsFolder:(id)sender
{
	[PluginManager openUserPluginsDirectory];
}

- (IBAction)reloadPlugins:(id)sender
{
	[[PluginManager defaultPluginManager] reloadPlugins];
	
	BOOL after = NO;
	
	for(NSMenuItem *item in [analysisMenu itemArray])
	{
		if(after)
		{
			NSLog(@"remove item");
			[analysisMenu removeItem:item];
		}
		else if([item isSeparatorItem])
		{
			after = YES;
		}
	}
	
	NSArray* plugins = [[PluginManager defaultPluginManager] plugins];
	for(AnnotationDataAnalysisPlugin *plugin in plugins)
	{
		NSLog(@"add item");
		NSMenuItem *item = [analysisMenu addItemWithTitle:[plugin displayName] action:@selector(runPlugin:) keyEquivalent:@""];
		[item setTarget:[PluginManager defaultPluginManager]];
		[item setRepresentedObject:plugin];
	}
}

- (IBAction)openQuickStartGuide:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://chronoviz.com/quickstart.html"]];
}

- (IBAction)sendFeedback:(id)sender
{
    NSString *encodedSubject = @"SUBJECT=ChronoViz%20Feedback";
    NSString *encodedBody = @"BODY=";
    NSString *encodedTo = [@"feedback@chronoviz.com" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedURLString = [NSString stringWithFormat:@"mailto:%@?%@&%@", encodedTo, encodedSubject, encodedBody];
    NSURL *mailtoURL = [NSURL URLWithString:encodedURLString];
    [[NSWorkspace sharedWorkspace] openURL:mailtoURL];
    
	//if(!feedbackController)
	//{
	//	feedbackController = [[FeedbackController alloc] init];
	//}
	//[feedbackController showWindow:self];
	//[[feedbackController window] makeKeyAndOrderFront:self];
}

- (void)bringVideoToFront
{
	[mMovieWindow makeKeyAndOrderFront:self];
}

- (BOOL)windowShouldClose:(id)sender
{
	if(annotationDoc)
	{
		BOOL result = [self closeDocument];
		return result;	
	}
	else
	{
		return YES;
		
	}
}

- (void)windowDidResignKey:(NSNotification *)notification
{
   [annotationHover close]; 
}

- (void)windowWillClose:(NSNotification *)aNotification {
	[self setSelectedAnnotation:nil];
	[NSApp terminate:self];
}

- (void)windowDidResize:(NSNotification *)notification
{
    timelineView.maximumHeight = [splitView frame].size.height - 9;
}

- (void)receiveMediaChanged:(NSNotification*)notification
{
	NSArray *removedMedia = [[notification userInfo] objectForKey:DPMediaRemovedKey];
	for(VideoProperties *videoProperties in removedMedia)
	{
		MovieViewerController *movieView = nil;
		for(id view in annotationViews)
		{
			if([view isMemberOfClass:[MovieViewerController class]])
			{
				if([view videoProperties] == videoProperties)
				{
					movieView = view;
					break;
				}
			}
		}
		if(movieView)
		{
			[movieView close];
			[self removeAnnotationView:movieView];
		}
		
		NSArray *timelines = [[timelineView timelines] copy];
		for(TimelineView* timeline in timelines)
		{
			if([[timeline segmentVisualizer] videoProperties] == videoProperties)
			{
				[timelineView removeTimeline:timeline];
			}
		}
		[timelines release];
	}
	
	NSArray *addedMedia = [[notification userInfo] objectForKey:DPMediaAddedKey];
	for(VideoProperties *properties in addedMedia)
	{
        if(properties != [annotationDoc videoProperties])
        {
            [self registerMedia:properties andDisplay:YES];
        }
	}
	
	[self updateViewMenu];
}

- (void)addMenuItem:(NSMenuItem*)menuItem toMenuNamed:(NSString*)menuName;
{
    
    if([menuName isEqualToString:@"File"])
    {
        [fileMenu addItem:menuItem];
    }
    else if ([menuName isEqualToString:@"Help"])
    {
        NSMenu *help = [[[NSApp mainMenu] itemWithTitle:@"Help"] submenu];
        [help addItem:menuItem];
    }
	
}

- (void)updateViewMenu
{	
	[viewManager update];
	
	NSArray *viewItems = [viewMenu itemArray];
	
	for(NSMenuItem *item in viewItems)
	{
		if([item tag] > 0)
		{
			[viewMenu removeItem:item];
		}
	}
	
	NSUInteger index = [viewMenu indexOfItemWithTitle:@"Show Map"];
	
	NSArray *menuItems = [viewManager viewMenuItems];
	for(NSMenuItem *item in menuItems)
	{
		[viewMenu insertItem:item atIndex:index];
		index++;
	}
	

}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	
	if([item action] == @selector(revertToBackup:))
	{
		return (backupAnnotationFile != nil);
	}
	else
	{
		return YES;
	}
	
//    if (([item action] == @selector(showVideoProperties:))
//		|| ([item action] == @selector(exportSimileTimeline:))
//		|| ([item action] == @selector(showDataSets:))
//		|| ([item action] == @selector(updateAllKeyframes:)))
//	{
//        return (mMovie != nil);
//    }
//	else if ([item action] == @selector(loadXMLAnnotations:))
//	{
//		return NO;
//	}
//	else
//	{
//		return YES;
//	}
}

- (IBAction)showSpatialOverlay:(id)sender
{
	//SpatialAnnotationOverlay *overlay = [[SpatialAnnotationOverlay alloc] initForView:mainView];
	//[overlay showOverlay];
}

- (void)setOverviewVisible:(BOOL)isVisible
{
    if(visibleOverviewTimeline != isVisible)
    {
        visibleOverviewTimeline = isVisible;
    
        // firstView, secondView are outlets
        NSViewAnimation *theAnim;
        NSRect splitViewFrame;
        NSRect overviewFrame;
        NSRect newFrame;
        NSMutableDictionary* splitViewDict;
        NSMutableDictionary* overviewDict;
        
        {
            // Create the attributes dictionary for the first view.
            splitViewDict = [NSMutableDictionary dictionaryWithCapacity:3];
            splitViewFrame = [splitView frame];
            
            // Specify which view to modify.
            [splitViewDict setObject:splitView forKey:NSViewAnimationTargetKey];
            
            // Specify the starting position of the view.
            [splitViewDict setObject:[NSValue valueWithRect:splitViewFrame]
                              forKey:NSViewAnimationStartFrameKey];
            
            // Change the ending position of the view.
            newFrame = splitViewFrame;
            if(isVisible)
            {
                newFrame.origin.y = newFrame.origin.y + 30;
                newFrame.size.height = newFrame.size.height - 30;	
            }
            else
            {
                newFrame.origin.y = newFrame.origin.y - 30;
                newFrame.size.height = newFrame.size.height + 30;
            }
            [splitViewDict setObject:[NSValue valueWithRect:newFrame]
                              forKey:NSViewAnimationEndFrameKey];
        }
        
        {
            // Create the attributes dictionary for the second view.
            overviewDict = [NSMutableDictionary dictionaryWithCapacity:3];
            overviewFrame = [overviewTimelineView frame];
            
            // Set the target object to the second view.
            [overviewDict setObject:overviewTimelineView forKey:NSViewAnimationTargetKey];
            
            // Specify the starting position of the view.
            [overviewDict setObject:[NSValue valueWithRect:overviewFrame]
                              forKey:NSViewAnimationStartFrameKey];
            
            NSRect viewZeroSize = overviewFrame;
            if(isVisible)
            {
                [overviewTimelineView setHidden:NO];
                viewZeroSize.size.height = 30;
            }
            else
            {
                viewZeroSize.size.height = 0;
            }

            [overviewDict setObject:[NSValue valueWithRect:viewZeroSize]
                               forKey:NSViewAnimationEndFrameKey];
            
        }
        
        // Create the view animation object.
        theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray
                                                                   arrayWithObjects:splitViewDict, overviewDict, nil]];
        
        [theAnim setDelegate:self];
        
        // Set some additional attributes for the animation.
    //	[theAnim setDuration:0.8];    // One and a half seconds.
    //	[theAnim setAnimationCurve:NSAnimationEaseInOut];
        
        // Run the animation.
        [theAnim startAnimation];
        
        // The animation has finished, so go ahead and release it.
        [theAnim release];
    }
}

- (IBAction)selectTool:(id)sender
{
	if([sender isKindOfClass:[NSSegmentedControl class]])
	{
		int clickedSegment = [sender selectedSegment];
		int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
		currentTool = clickedSegmentTag;
		[mMovieWindow invalidateCursorRectsForView:timelineView];
	}
}

- (void)setTool:(int)toolID
{
	if(toolID != currentTool)
	{
		if((toolID == DataPrismSelectTool)
		   || (toolID == DataPrismZoomTool))
		{
			currentTool = toolID;
			[toolControl selectSegmentWithTag:toolID];
		}
	}
}

- (IBAction)zoomButtonClicked:(id)sender
{
	if([sender isKindOfClass:[NSSegmentedControl class]])
	{
		int clickedSegment = [sender selectedSegment];
		int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
		if(clickedSegmentTag)
		{
			[self zoomIn:nil];
		}
		else
		{
			[self zoomOut:nil];
		}
	}
}

- (IBAction)zoomIn:(id)sender
{
	CMTimeRange selection = [overviewTimelineView selection];
	selection.start.value = selection.start.value + selection.duration.value/4;
	selection.duration.value = selection.duration.value/2;
	selection = CMTimeRangeGetIntersection(selection, [overviewTimelineView range]);
	[overviewTimelineView setSelection:selection animate:YES];
    
	if(([overviewTimelineView frame].size.height < 10)
	   && !CMTimeRangeEqual(selection, [overviewTimelineView range]))
	{
		[self setOverviewVisible:YES];
	}
}

- (IBAction)zoomOut:(id)sender
{	
	CMTimeRange selection = [overviewTimelineView selection];
	
	if(CMTimeCompare(selection.duration, [[mMovie currentItem] duration]) == NSOrderedAscending)
	{
		selection.duration.value = selection.duration.value * 2;
		selection.start.value = selection.start.value - selection.duration.value/4;
		selection = CMTimeRangeGetIntersection(selection, [overviewTimelineView range]);
		[overviewTimelineView setSelection:selection animate:YES];
		
		if(([overviewTimelineView frame].size.height > 0)
		   && CMTimeRangeEqual(selection, [overviewTimelineView range]))
		{
			[self setOverviewVisible:NO];
		}
	}
}

- (void)zoomInToTime:(CMTime)time
{		
	CMTimeRange selection = [overviewTimelineView selection];
	selection.duration.value = selection.duration.value/2;
	CMTime halfduration = selection.duration;
	halfduration.value = halfduration.value/2;
	selection.start = CMTimeSubtract(time,halfduration);
		
	selection = CMTimeRangeGetIntersection(selection, [overviewTimelineView range]);
	[overviewTimelineView setSelection:selection animate:YES];
	
	if(([overviewTimelineView frame].size.height < 10) 
	   && !CMTimeRangeEqual(selection, [overviewTimelineView range]))
	{
		[self setOverviewVisible:YES];
	}
}

- (void)zoomToTimeRange:(CMTimeRange)timeRange
{
	CMTimeRange selection = CMTimeRangeGetIntersection(timeRange, [overviewTimelineView range]);
	[overviewTimelineView setSelection:selection animate:YES];
	
	if(([overviewTimelineView frame].size.height < 10) 
	   && !CMTimeRangeEqual(selection, [overviewTimelineView range]))
	{
		[self setOverviewVisible:YES];
	}
    else if (CMTimeRangeEqual(selection, [overviewTimelineView range]))
    {
        [self setOverviewVisible:NO];
    }
    
}

- (IBAction)showConsole:(id)sender
{
	if(!consoleWindowController) {
		consoleWindowController = [[DPConsoleWindowController alloc] init];
	}
	[consoleWindowController showWindow:self];
	[[consoleWindowController window] makeKeyAndOrderFront:self];
}

- (IBAction)showVideoProperties:(id)sender
{
	if([annotationDoc videoProperties])
	{
		if(!videoPropertiesController) {
			videoPropertiesController = [[VideoPropertiesController alloc] init];
		}
		[videoPropertiesController setVideoProperties:[annotationDoc videoProperties]];
		[videoPropertiesController setAnnotationDoc:annotationDoc];
		[videoPropertiesController showWindow:self];
		[[videoPropertiesController window] makeKeyAndOrderFront:self];
	}
}

- (IBAction)showLinkedFilesWindow:(id)sender
{
	[[self linkedFilesController] showWindow:self];
	[[[self linkedFilesController] window] makeKeyAndOrderFront:self];
}

- (IBAction)showDocumentVariablesWindow:(id)sender
{
	[[self documentVariablesController] showWindow:self];
	[[[self documentVariablesController] window] makeKeyAndOrderFront:self];	
}

- (IBAction)showMediaWindow:(id)sender
{
	if(!mediaWindowController) {
		mediaWindowController = [[MediaWindowController alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:mediaWindowController
												 selector:@selector(reloadMediaListing:)
													 name:MediaChangedNotification
												   object:annotationDoc];
	}
	[mediaWindowController showWindow:self];
	[[mediaWindowController window] makeKeyAndOrderFront:self];
}

- (IBAction)showCategoriesWindow:(id)sender
{
	if(!categoriesWindowController) {
		categoriesWindowController = [[CategoriesWindowController alloc] init];
	}
	[categoriesWindowController showWindow:self];
	[[categoriesWindowController window] makeKeyAndOrderFront:self];
}

- (IBAction)showPreferencePanel:(id)sender
{
	if(!prefController) {
		prefController = [[PreferenceController alloc] init];
		[prefController setAppController:self];
	}

	[prefController showWindow:self];	

	[[prefController window] makeKeyAndOrderFront:self];
}

- (IBAction)goFullScreen:(id)sender
{
	
}

- (IBAction)exitFullScreen:(id)sender
{	
	
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender
{
	return undoManager; // We created this undo manager manually
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if([keyPath isEqualToString:AFMaxPlaybackRateKey])
	{
		NSInteger speed = [[NSUserDefaults standardUserDefaults] integerForKey:AFMaxPlaybackRateKey];
		
		DPMappedValueTransformer *transformer = (DPMappedValueTransformer*)[NSValueTransformer valueTransformerForName:@"DPSpeedTransformer"];
		NSMutableArray *rates = [[transformer inputValues] mutableCopy];
		float previousRate = [[rates objectAtIndex:4] floatValue];
		[rates replaceObjectAtIndex:4 withObject:[NSNumber numberWithInt:speed]];
		[transformer setInputValues:rates];
        [rates release];
		
		if(fabsf(previousRate - playbackRate) < .01)
		{
			[self setPlaybackRate:speed];
		}
		
		if(fabsf(mRate - previousRate) < .01)
		{
			[self setRate:speed fromSender:self];
		}
		
	}
	else if ((object == self) && [keyPath isEqual:@"playbackRate"])
	{
		if(playing && !paused)
		{
			[self setRate:playbackRate fromSender:self];
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

#pragma mark Accessors

- (AnnotationDocument *)document
{
	return annotationDoc;
}

- (Annotation*)selectedAnnotation
{
	return selectedAnnotation;
}

//- (Annotation*)currentAnnotation
//{
//	return [inspector annotation];
//}

- (MultiTimelineView *)timelineView
{
	return timelineView;
}

//- (ImageSequenceView *)imageSequenceView
//{
//	return imageSequenceView;
//}

- (AVPlayer *)movie
{
	return mMovie;
}

- (AVPlayer *)mMovie
{
	return mMovie;
}

- (NSView*)mainView
{
	return mainView;
}

- (NSWindow *)window
{
	return mMovieWindow;
}

- (DPViewManager*)viewManager
{
	return viewManager;
}

- (DPURLHandler*)urlHandler
{
	return urlHandler;
}

- (NSArray*) annotationViews
{
	return [[annotationViews copy] autorelease];
}

- (NSArray*) dataWindowControllers
{
	return [[dataWindowControllers copy] autorelease];
}

- (LinkedFilesController*)linkedFilesController
{
	if(!linkedFilesController && annotationDoc) {
		linkedFilesController = [[LinkedFilesController alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:linkedFilesController
												 selector:@selector(reloadData)
													 name:DataSetsChangedNotification
												   object:annotationDoc];
		linkedFilesController.annotationDocument = annotationDoc;
	}
	return linkedFilesController;
}

- (DPDocumentVariablesController*)documentVariablesController
{
	if(!documentVariablesController) {
		documentVariablesController = [[DPDocumentVariablesController alloc] initForDocument:annotationDoc];
	}
	return documentVariablesController;
}

- (CMTime)currentTime
{
	return [mainVideo.playerItem currentTime];
}

- (CMTimeRange)currentSelection
{
	return currentSelection;
}

- (CMTime)currentMovieTime
{
	return [self currentTime];
}

#pragma mark Time Control

- (IBAction)playbackModeButtonClicked:(id)sender
{
	if([sender isKindOfClass:[NSSegmentedControl class]])
	{
		if([(NSSegmentedControl*)sender isSelectedForSegment:0])
		{
			loopPlayback = YES;
		}
		else
		{
			loopPlayback = NO;
		}
		
		annotationPlayback = [(NSSegmentedControl*)sender isSelectedForSegment:1];

	}
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    if (loopPlayback)
    {
        AVPlayerItem *p = [notification object];
        [p seekToTime:kCMTimeZero];
        [mMovie play];
    }
}

- (IBAction)changeTimeFormat:(id)sender
{
    NSInteger tag = [sender tag];
    if(tag == 2)
    {
        [NSString setDefaultTimeFormat:([NSString defaultTimeFormat] ^ DPTimeCodeMillisecondsMask)];
    }
    else
    {
        [self setAbsoluteTime:[sender tag]];
    }
    [self updateDisplay:nil];
    [[timelineView baseTimeline] redrawAllSegments];
}

- (IBAction)timeButtonClicked:(id)sender
{
	if([sender respondsToSelector:@selector(frame)])
	{
		NSRect theFrame = [sender frame];
		
		NSMenu *timeMenu = [[[NSMenu alloc] initWithTitle:@"Time Options Menu"] autorelease];
		[timeMenu setAutoenablesItems:NO];
		
		NSMenuItem *item = nil;
		
		item = [timeMenu addItemWithTitle:@"Relative Time" action:@selector(changeTimeFormat:) keyEquivalent:@""];
		[item setTarget:self];
		[item setTag:0];
		if(!self.absoluteTime)
		{
			[item setState:NSOnState];
		}
		
		item = [timeMenu addItemWithTitle:@"Absolute Time" action:@selector(changeTimeFormat:) keyEquivalent:@""];
		[item setTarget:self];
		[item setTag:1];
		if(self.absoluteTime)
		{
			[item setState:NSOnState];
		}
		
        [timeMenu addItem:[NSMenuItem separatorItem]];
        
        item = [timeMenu addItemWithTitle:@"Show Milliseconds" action:@selector(changeTimeFormat:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:2];
        if([NSString defaultTimeFormat] & DPTimeCodeMillisecondsMask)
        {
            [item setState:NSOnState];
        }

		[NSMenu popUpMenu:timeMenu 
				  forView:movieControlsBox
				 atOrigin:NSMakePoint(theFrame.origin.x, theFrame.origin.y - theFrame.size.height) 
				pullsDown:YES];	
	}
	

}

- (IBAction)togglePlay:(id)sender
{
	if(mMovie) {
		if(playing) {
			//[mMovie stop];
			playing = NO;
			[self setRate:0.0 fromSender:sender];
			[playButton setImage:[NSImage imageNamed:@"play"]];
			[playButton setAlternateImage:[NSImage imageNamed:@"playAlt"]];
		} else {
			//[mMovie play];
			playing = YES;
			paused = NO;
			[self setRate:playbackRate fromSender:sender];
			[playButton setImage:[NSImage imageNamed:@"pause"]];
			[playButton setAlternateImage:[NSImage imageNamed:@"pauseAlt"]];
		}
	}	
}

- (IBAction)pause:(id)sender
{
	if(playing)
	{
		[self togglePlay:sender];
	}
}

- (void)resumePlaying
{
	if(paused && !playing)
		[self togglePlay:self];
}

- (IBAction)stepForward:(id)sender
{
	CMTime newTime = CMTimeAdd([mMovie currentTime], CMTimeMakeWithSeconds(stepSize,[mMovie currentTime].timescale));
	if(CMTimeCompare([[mMovie currentItem] duration],newTime) == NSOrderedAscending)
	{
		newTime = [[mMovie currentItem] duration];
	}
	
	[self moveToTime:newTime fromSender:sender];
}

- (IBAction)stepBack:(id)sender
{
	CMTime newTime = CMTimeSubtract([mMovie currentTime], CMTimeMakeWithSeconds(stepSize,[mMovie currentTime].timescale));
	if(CMTimeCompare(kCMTimeZero,newTime) == NSOrderedDescending)
	{
		newTime = kCMTimeZero;
	}	
	[self moveToTime:newTime fromSender:sender];
}

- (IBAction)stepOneFrameForward:(id)sender
{
    [self step:sender byFrames:1];
}

- (IBAction)stepOneFrameBackward:(id)sender
{
    [self step:sender byFrames:-1];
}

- (IBAction)step:(id)sender byFrames:(int)frames
{
    // Unfortunately, we cannot use `[[mMovie currentItem] stepByCount:frames]` because we need to trigger `self`
    // to update the current time via `[self moveToTime:[mMovie currentTime] fromSender:sender]`.
    // But `stepByCount` is not synchronous, so when we call `[self moveToTime]` we will get the old time from
    // `[mMovie currentTime]` effectively reseting the frame we just tried to step forward/backward.
    // Instead we calculate how long a frame is and what the desired new time is.
    AVAsset *asset = [[mMovie currentItem] asset];
    float framerate = [[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] nominalFrameRate];
    CMTime oneFrame = CMTimeMake(frames, framerate);
    CMTime newTime = CMTimeAdd([mMovie currentTime], oneFrame);
    [self moveToTime:newTime fromSender:sender];
    
}

- (IBAction)fastForward:(id)sender
{
	if(mMovie)
		[self setRate:2.0 fromSender:sender];
}

- (IBAction)rewind:(id)sender
{
	if(mMovie)
		[self setRate:-2.0 fromSender:sender];
}

- (void)setRate:(float)rate fromSender:(id)source
{
	if(ignoreRateInput) 
		return;
	
	CMTime currentTime = [mMovie currentTime];
	
	// This accounts for the dial moving back through the values, which would cause the movie to
	// jump to the beginning or end
	if((currentTime.value == 0) && (rate < 0)) 
		return;
	if((currentTime.value == [[mMovie currentItem] duration].value) && (rate > 0))
		return;

	if(rate == 0) {
		if(playing) {
			//rate = 1;
			[self togglePlay:self];
			return;
		}
		else
		{
			[timeDisplayTimer invalidate];
			timeDisplayTimer = nil;
			[timer invalidate];
			timer = nil;
		}
	}
	else
	{
		if((rate == playbackRate) && !playing)
		{
			[self togglePlay:self];
			return;
		}
		if (timer == nil) {
			timeDisplayTimer = [NSTimer scheduledTimerWithTimeInterval:0.045
													 target:self
												   selector:@selector(updateTimeDisplay:)
												   userInfo:nil
													repeats:YES];
			
			timer = [NSTimer scheduledTimerWithTimeInterval:0.1
													 target:self
												   selector:@selector(updateDisplay:)
												   userInfo:nil
													repeats:YES];
			[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
		}
	}
	
	[rateLock lock];
	
	[activeMovies removeAllObjects];
	[activeMovies addObject:mMovie];
	
	//[mMovie setRate:rate];
	
	for(VideoProperties* mediaProperties in [annotationDoc mediaProperties])
	{
		if([mediaProperties enabled])
		{
			CMTime newTime = CMTimeAdd(currentTime, [mediaProperties offset]);
			if((newTime.value > 0)
			   && (CMTimeCompare(newTime, [[[mediaProperties movie] currentItem] duration]) == NSOrderedAscending))
			{
				[[mediaProperties movie] seekToTime:newTime];
				//[[mediaProperties movie] setRate:rate];
				[activeMovies addObject:[mediaProperties movie]];
			}
		}
		else
		{
			[[mediaProperties movie] setRate:0];
		}
	}
	
	for(AVPlayer* movie in activeMovies)
	{
		[movie setRate:rate];
	}
	
	mRate = rate;
	[rateLock unlock];
	
}

- (void)updateTimeDisplay:(NSTimer *)aTimer
{
	if(absoluteTime)
	{
		[movieTimeButton setTitle:[NSString stringWithCMTime:[mMovie currentTime] sinceDate:[annotationDoc startDate]]];
	}
	else
	{
		[movieTimeButton setTitle:[NSString stringWithCMTime:[mMovie currentTime]]];
	}
}

- (void)updateDisplay:(NSTimer *)aTimer
{
	if(loadingMovie) {
		return;
	}
	
	// Check for end points and update time display
	if(mMovie)
	{
        
		if(annotationPlayback && selectedAnnotation && [selectedAnnotation isDuration])
		{
            CMTime currentTime = [mMovie currentTime];
            CMTime normalizedStart = CMTimeConvertScale([selectedAnnotation startTime], currentTime.timescale, kCMTimeRoundingMethod_Default); // TODO: Check if QTMakeTimeScaled is correctly replacesd by CMTimeConvertScale
			if(CMTimeCompare(currentTime,[selectedAnnotation endTime]) == NSOrderedDescending)
			{
				if(loopPlayback)
				{
					[self moveToTime:normalizedStart fromSender:self];
				}
				else
				{
					if(playing)
					{
						[self togglePlay:self];
					}
					[self moveToTime:[selectedAnnotation endTime] fromSender:self];
				}
			}
			else if(CMTimeCompare(currentTime,normalizedStart) == NSOrderedAscending)
			{
                
				if(playing)
				{
					[self moveToTime:normalizedStart fromSender:self];
				}
			}
		}
		
		if([mMovie rate] != mRate){
			if([mMovie rate] == 0.0) {
				playing = YES;
				[self togglePlay:self];
			}  else {
				playing = NO;
				[self togglePlay:self];
			}
		}
		
		for(VideoProperties* mediaProperties in [annotationDoc mediaProperties])
		{
			if([mediaProperties enabled] && ([mMovie rate] != [[mediaProperties movie] rate]))
			{
				CMTime newTime = CMTimeAdd([mMovie currentTime], [mediaProperties offset]);
				if((newTime.value > 0)
				   && (CMTimeCompare(newTime, [[[mediaProperties movie] currentItem] duration]) == NSOrderedAscending))
				{
					[[mediaProperties movie] seekToTime:newTime];
					[[mediaProperties movie] setRate:[mMovie rate]];
				}
				
			}
		}
		
		[self updateTimeDisplay:aTimer];
	}

	
	// Update views
	for(id<AnnotationView> view in annotationViews)
	{
		[view update];
	}
	
//	if(imageSequenceView)
//	{
//		[imageSequenceView update];
//	}
//
//	if(![timelineView isHidden])
//		[timelineView redraw];
//	
//	if([[vizController window] isVisible]){
//		[vizController updateVisualization];
//	}
}

- (void)moveToTime:(CMTime)time fromSender:(id)sender
{
	if(time.value < 0)
	{
		time.value = 0;
	}
    CMTime tolerance = kCMTimeZero;
	[mMovie seekToTime:time toleranceBefore:tolerance toleranceAfter:tolerance];
	for(VideoProperties* mediaProperties in [annotationDoc mediaProperties])
	{
		if([mediaProperties enabled])
		{
			CMTime newTime = CMTimeAdd(time, [mediaProperties offset]);
			if(newTime.value < 0)
			{
				newTime.value = 0;
			}
			if(CMTimeCompare(newTime, [[[mediaProperties movie] currentItem] duration]) == NSOrderedDescending)
			{
				newTime = [[[mediaProperties movie] currentItem] duration];
			}
			[[mediaProperties movie] seekToTime:newTime];
		}
	}
	[self updateDisplay:nil];
}


- (void)setTimeSelection:(CMTimeRange)range
{
	currentSelection = range;
	[self updateDisplay:nil];
}

- (NSString*)processInteractionSource:(id)source
{
	if([source isKindOfClass:[NSString class]])
	{
		return (NSString*)source;
	}
	else if(source == self)
	{
		return @"Internal";
	}
	else if([source isKindOfClass:[TimelineView class]])
	{
		return [NSString stringWithFormat:@"Timeline %i",[[timelineView timelines] indexOfObject:source]];
	}
	else
	{
		return [source className];
	}
}

#pragma mark Logging

- (IBAction)outputLog:(id)sender
{
	//NSLog(@"Interaction Log: %@",[log interactions]);
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setTitle:@"Save Interaction Log"];
	
	// files are filtered through the panel:shouldShowFilename: method above
//    if ([savePanel runModal] == NSOKButton) {
//        [log saveToFile:[savePanel filename]];
//    }
}


#pragma mark Animation Delegate

- (void)animationDidEnd:(NSAnimation *)animation
{
	//[mMovieWindow enableCursorRects];

	animating = NO;
	
}

- (void)animationDidStop:(NSAnimation *)animation
{
	//[mMovieWindow enableCursorRects];

	animating = NO;
	
}

- (BOOL)animationShouldStart:(NSAnimation *)animation
{
	//[mMovieWindow disableCursorRects];
	animating = YES;
	return YES;
}


@end
