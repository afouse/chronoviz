//
//  DPViewFactory.m
//  DataPrism
//
//  Created by Adam Fouse on 6/17/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "DPViewManager.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "AnnotationView.h"
#import "AnnotationViewController.h"
#import "AnnotationCategory.h"
#import "VideoProperties.h"
#import "TimeCodedData.h"
#import "TimeSeriesData.h"
#import "GeographicTimeSeriesData.h"
#import "MapController.h"
#import "MapView.h"
#import "TimelineView.h"
#import "MultiTimelineView.h"
#import "SegmentVisualizer.h"
#import "AnnotationTimeSeriesVisualizer.h"
#import "TimeSeriesVisualizer.h"
#import "AnnotationVisualizer.h"
#import "FilmstripVisualizer.h"
#import "AudioVisualizer.h"
#import "AnnotationSet.h"
#import "AnnotationCategoryFilter.h"
#import "TranscriptData.h"
#import "TranscriptView.h"
#import "TranscriptViewController.h"
#import "TimeCodedImageFiles.h"
#import "AFMovieView.h"
#import "ImageSequenceView.h"
#import "ImageSequenceController.h"
#import "MovieViewerController.h"
#import "ActivityFramesVisualizer.h"
#import "DPActivityLog.h"

NSString * const DPKeyframeTimelineMenuTitle = @"Keyframes";
NSString * const DPAudioTimelineMenuTitle = @"Audio Waveform";
NSString * const DPTapestryTimelineMenuTitle = @"Annotation Tapestry";

@interface DPTimelineOption : NSObject {
	NSString *title;
	Class visualizer;
	id data;
	NSArray *options;
}

@property(copy) NSString *title;
@property(assign) Class visualizer;
@property(assign) id data;
@property(retain) NSArray *options;

@end

@implementation DPTimelineOption

@synthesize title;
@synthesize visualizer;
@synthesize data;
@synthesize options;

- (id) init
{
	self = [super init];
	if (self != nil) {
		self.options = [NSArray array];
	}
	return self;
}


- (void) dealloc
{
	self.title = nil;
	self.options = nil;
	[super dealloc];
}

@end

@interface DPViewManager (Timelines)

- (void)finishAddTimeline;

@end

@interface DPViewManager (Videos)

- (void)zoomInVideoAction:(id)sender;
- (void)zoomOutVideoAction:(id)sender;
- (void)updateMediaViews:(NSNotification*)notification;

@end

@implementation DPViewManager


- (id) initForController:(AppController*)appController
{
	self = [super init];
	if (self != nil) {
		controller = appController;
		timelineOptions = [[NSMutableArray alloc] init];
        viewClasses = [[NSMutableDictionary alloc] init];
        controllerClasses = [[NSMutableDictionary alloc] init];
        dataTypeNames = [[NSMutableDictionary alloc] init];
        
        [self registerDataClass:[TimeCodedImageFiles class]
                  withViewClass:[ImageSequenceView class]
                controllerClass:[ImageSequenceController class]
                   viewMenuName:@"Image Sequence"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateMediaViews:)
                                                     name:MediaChangedNotification
                                                   object:nil];
	}
	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [dataTypeNames release];
    [viewClasses release];
    [controllerClasses release];
	[timelineOptions release];
	[super dealloc];
}

- (void)update
{
	[timelineOptions removeAllObjects];
	
	NSMutableArray *general = [NSMutableArray array];
	NSMutableArray *keyframes = [NSMutableArray array];
	NSMutableArray *waveforms = [NSMutableArray array];
	NSMutableArray *timeSeries = [NSMutableArray array];
	
	AnnotationDocument *doc = [AnnotationDocument currentDocument];
	VideoProperties *videoInfo = [doc videoProperties];
	
	DPTimelineOption *option = nil;
	
	option = [[DPTimelineOption alloc] init];
	option.title = @"Annotations Timeline";
	option.visualizer = [AnnotationVisualizer class];
	option.data = nil;
	[general addObject:option];
	[option release];
	
	option = [[DPTimelineOption alloc] init];
	option.title = @"Activity Timeline";
	option.visualizer = [ActivityFramesVisualizer class];
	option.data = [doc activityLog];
	[general addObject:option];
	[option release];
	
	option = [[DPTimelineOption alloc] init];
	option.title = @"General";
	option.visualizer = [NSArray class];
	option.data = nil;
	option.options = general;
	[timelineOptions addObject:option];
	[option release];
	
	NSArray *allVideos = [[NSArray arrayWithObject:videoInfo] arrayByAddingObjectsFromArray:[doc mediaProperties]];
	
	for(VideoProperties *video in allVideos)
	{
		if([video hasVideo])
		{			
			option = [[DPTimelineOption alloc] init];
			option.title = [video title];
			option.visualizer = [FilmstripVisualizer class];
			option.data = video;
			[keyframes addObject:option];
			[option release];
		}
		
		if([video hasAudio])
		{
			option = [[DPTimelineOption alloc] init];
			option.title = [video title];
			option.visualizer = [AudioVisualizer class];
			option.data = video;
			[waveforms addObject:option];
			[option release];
		}
	}		
	
	
	if ([keyframes count] > 0)
	{	
		option = [[DPTimelineOption alloc] init];
		option.title = @"Keyframes";
		option.visualizer = [NSArray class];
		option.options = keyframes;
		[timelineOptions addObject:option];
		[option release];
	}
	
	if ([waveforms count] > 0)
	{
		option = [[DPTimelineOption alloc] init];
		option.title = @"Audio Waveform";
		option.visualizer = [NSArray class];
		option.options = waveforms;
		[timelineOptions addObject:option];
		[option release];
	}
	
	
	for(TimeCodedData *dataSet in [doc dataSets])
	{
		if([dataSet isKindOfClass:[TimeSeriesData class]])
		{
			option = [[DPTimelineOption alloc] init];
			option.title = [dataSet name];
			option.visualizer = [TimeSeriesVisualizer class];
			option.data = dataSet;
			[timeSeries addObject:option];
			[option release];
		}
	}
	
	if([timeSeries count] > 0)
	{
		option = [[DPTimelineOption alloc] init];
		option.title = @"Time Series Graph";
		option.visualizer = [NSArray class];
		option.options = timeSeries;
		[timelineOptions addObject:option];
		[option release];
	}
	
}

- (void)registerDataClass:(Class)dataClass withViewClass:(Class)viewClass controllerClass:(Class)controllerClass viewMenuName:(NSString*)menuName
{
    if([dataClass isSubclassOfClass:[TimeCodedData class]]
       && [viewClass conformsToProtocol:@protocol(AnnotationView)]
       && [viewClass isSubclassOfClass:[NSView class]]
       && [controllerClass conformsToProtocol:@protocol(AnnotationViewController)]
       && [controllerClass isSubclassOfClass:[NSWindowController class]])
    {    
        NSString *dataClassString = NSStringFromClass(dataClass);
        [viewClasses setObject:viewClass forKey:dataClassString];
        [controllerClasses setObject:controllerClass forKey:dataClassString];
        [dataTypeNames setObject:menuName forKey:dataClassString];
    }
}

- (Class)controllerClassForViewClass:(Class)viewClass
{
    for(NSString *dataType in [viewClasses allKeys])
    {
        Class testViewClass = [viewClasses objectForKey:dataType];
        if(testViewClass == viewClass)
        {
            return [controllerClasses objectForKey:dataType];
        }
    }
    return nil;
}

- (void)showData:(TimeCodedData*)dataSet
{
	[self showData:dataSet ifRepeat:NO];
}


- (void)showData:(TimeCodedData*)dataSet ifRepeat:(BOOL)repeat
{
	[self showDataSets:[NSArray arrayWithObject:dataSet] ifRepeats:repeat];
}

- (void)showDataInMainViewAction:(id)sender
{
    if([sender respondsToSelector:@selector(representedObject)]
       && [[sender representedObject] isKindOfClass:[TimeCodedData class]])
    {
        [self showDataInMainView:[sender representedObject]];
    }
}

- (void)showDataInMainView:(TimeCodedData*)dataSet
{
    NSString *dataTypeString = NSStringFromClass([dataSet class]);
    Class ViewClass = [viewClasses objectForKey:dataTypeString];
    // Look for superclasses
    if(!ViewClass)
    {
        for(NSString *dataType in [viewClasses allKeys])
        {
            if([[dataSet class] isSubclassOfClass:NSClassFromString(dataType)])
            {
                ViewClass = [controllerClasses objectForKey:dataType];
                break;
            }
        }
    }
    
    if(ViewClass && [ViewClass isSubclassOfClass:[NSView class]])
    {
        NSView<AnnotationView> *view = [[ViewClass alloc] init];
        [view addData:dataSet];
        [controller addAnnotationView:view];
        [controller replaceMainView:view];
    }
}

- (NSArray*)showDataSets:(NSArray*)dataSets ifRepeats:(BOOL)repeats
{	
	NSArray *dataWindowControllers = [controller dataWindowControllers];
	NSArray *annotationViews = [controller annotationViews];
	
	NSMutableDictionary *dataViewControllers = [[NSMutableDictionary alloc] init]; 
	
	NSMutableArray *result = [NSMutableArray array];
    BOOL tooManyTimelines = NO;
	for(TimeCodedData *dataSet in dataSets)
	{
		if(!repeats)
		{
            BOOL shown = NO;
			for(NSObject<AnnotationView> *view in annotationViews)
			{
				if([[view dataSets] containsObject:dataSet])
				{
					if([view isKindOfClass:[NSView class]])
					{
						[[(NSView*)view window] makeKeyAndOrderFront:self];
					}
					else if([view isKindOfClass:[NSWindowController class]])
					{
						[[(NSWindowController*)view window] makeKeyAndOrderFront:self];
					}
                    shown = YES;
					break;
				}
			}
            if(shown)
            {
                continue;
            }
		}
        
        // Special case for time coded image files to be presented in the main movie viewer space
        // Only if the only thing shown in the movie viewer is the blank "local" video
        if([dataSet isKindOfClass:[TimeCodedImageFiles class]]
           && [[controller mainView] isKindOfClass:[AFMovieView class]]
           && ([[(AFMovieView*)[controller mainView] movies] count] == 1))
        {
            [self showDataInMainView:dataSet];
            continue;
        }
	
        NSString *dataTypeString = NSStringFromClass([dataSet class]);
        Class ControllerClass = [controllerClasses objectForKey:dataTypeString];
        // Look for superclasses
        if(!ControllerClass)
        {
            for(NSString *dataType in [controllerClasses allKeys])
            {
                if([[dataSet class] isSubclassOfClass:NSClassFromString(dataType)])
                {
                    ControllerClass = [controllerClasses objectForKey:dataType];
                    break;
                }
            }
        }
        
        if(ControllerClass)
        {
            NSWindowController<AnnotationViewController> *viewController = [dataViewControllers objectForKey:dataTypeString];
			if(!viewController)
			{
				viewController = [[ControllerClass alloc] init];
				[dataViewControllers setObject:viewController forKey:dataTypeString];
				[viewController release];
				[viewController showWindow:self];
				[[viewController window] makeKeyAndOrderFront:self];
				[controller addDataWindow:viewController];
				[controller addAnnotationView:[viewController annotationView]];
                
			}
			
			[[viewController annotationView] addData:dataSet];
        }
		else if([dataSet isKindOfClass:[GeographicTimeSeriesData class]])
		{
			MapController *mapController = nil;
			
			[controller showMap:self];
			dataWindowControllers = [controller dataWindowControllers];
			
			for(NSWindowController *windowController in dataWindowControllers)
			{
				if([windowController isKindOfClass:[MapController class]])
				{
					mapController = (MapController*)windowController;
					break;
				}
			}
			
			if(!mapController)
			{
				mapController = [[MapController alloc] init];
				[controller addDataWindow:mapController];
			}
			
			[[mapController mapView] addData:(GeographicTimeSeriesData*)dataSet];
			
			if(![annotationViews containsObject:[mapController mapView]])
			{
				[controller addAnnotationView:[mapController mapView]];
			}
			
			[mapController showWindow:self];
			[[mapController window] makeKeyAndOrderFront:self];
            
		}
//		else if([dataSet isKindOfClass:[TimeCodedImageFiles class]])
//		{
//            [controller mainView];
//			[controller showImageSequence:(TimeCodedImageFiles*)dataSet inMainWindow:YES];
//		}
		else if([dataSet isKindOfClass:[AnnotationSet class]])
		{
            
            AnnotationCategory *category = [[controller document] categoryForName:[[dataSet source] name]];
			if(!category)
			{
				category = [[controller document] createCategoryWithName:[[dataSet source] name]];
				[category autoColor];
			}
			
			if([(AnnotationSet*)dataSet useNameAsCategory])
			{
				category = [category valueForName:[dataSet name]];
				[category autoColor];
			}
			
			//[category setColor:[NSColor colorWithCalibratedRed:0.213 green:0.280 blue:0.536 alpha:1.000]];
			for(Annotation *annotation in [(AnnotationSet*)dataSet annotations])
			{
				[annotation addCategory:category];
			}
			[(AnnotationSet*)dataSet setCategory:category];
			
			AnnotationVisualizer *viz = nil;
            
            TimelineView *timeline = [dataViewControllers objectForKey:@"AnnotationSet"];
            
            if(!timeline)
            {
                timeline = [[[AppController currentApp] timelineView] addNewAnnotationTimeline:self];
				AnnotationCategoryFilter *dataFilter = [AnnotationCategoryFilter filterForCategory:category];
				[timeline setAnnotationFilter:dataFilter];
				viz = (AnnotationVisualizer*)[timeline segmentVisualizer];
                
                [dataViewControllers setObject:timeline forKey:@"AnnotationSet"];
                
            }
            else
            {
                [(AnnotationCategoryFilter*)[timeline annotationFilter] showCategory:category];
            }
            
            AnnotationFilter *otherFilter = [[[[AppController currentApp] timelineView] baseTimeline] annotationFilter];
            if(!otherFilter)
                otherFilter = [[[AnnotationCategoryFilter alloc] init] autorelease];
            
            if([otherFilter isKindOfClass:[AnnotationCategoryFilter class]])
            {
                [(AnnotationCategoryFilter*)otherFilter hideCategory:category];
            }
            [[[[AppController currentApp] timelineView] baseTimeline] setAnnotationFilter:otherFilter];
            
			
			if([viz lineUpCategories])
				[viz toggleAlignCategories];
			
			[[controller document] addAnnotations:[(AnnotationSet*)dataSet annotations]];
            
		}
		else if ([dataSet isKindOfClass:[TranscriptData class]])
		{		
			TranscriptViewController *transcriptView = [[TranscriptViewController alloc] init];
			[transcriptView showWindow:self];
			[[transcriptView window] makeKeyAndOrderFront:self];
			[[transcriptView transcriptView] setData:(TranscriptData*)dataSet];
			
			[controller addDataWindow:transcriptView];
			[controller addAnnotationView:[transcriptView transcriptView]];
			[transcriptView release];
            
            
		}
        else if([dataSet isKindOfClass:[TimeSeriesData class]])
		{		
			TimelineView *timeline = [[TimelineView alloc] initWithFrame:[[controller timelineView] frame]];
			[timeline setMovie:[controller mMovie]];
			[timeline setData:(TimeSeriesData*)dataSet];
			
			AnnotationTimeSeriesVisualizer *viz = [[AnnotationTimeSeriesVisualizer alloc] initWithTimelineView:timeline];
			[timeline setSegmentVisualizer:viz];
			[timeline addAnnotations:[[AnnotationDocument currentDocument] annotations]];
			
			tooManyTimelines = ![[controller timelineView] addTimeline:timeline];
			
			[viz release];
			[timeline release];
		}
		else
		{
			[result addObject:dataSet];
		}
	}
	[dataViewControllers release];
    
    if(tooManyTimelines)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Some of the data sets couldn't be displayed because there are too many timelines."];
        [alert runModal];
        [alert release];
    }
    
	return result;
}

- (NSArray*)viewsForData:(TimeCodedData*)dataSet
{
    NSMutableArray *result = [NSMutableArray array];
    for(NSObject<AnnotationView> *view in [controller annotationViews])
	{
		if([[view dataSets] containsObject:dataSet])
		{
            [result addObject:view];
        }
    }
    
    return result;
}

- (void)removeData:(TimeCodedData*)dataSet
{	
	for(NSObject<AnnotationView> *view in [controller annotationViews])
	{
		if([[view dataSets] containsObject:dataSet])
		{
            NSLog(@"found data");
            
            BOOL closeView = NO;
            
			if([view respondsToSelector:@selector(removeData:)])
			{
				NSLog(@"remove data from view");
				[view removeData:dataSet];
                
                if([[view dataSets] count] == 0)
                {
                    closeView = YES;
                }
			}
			else
			{
                closeView = YES;
            }
            
            
            if(closeView)
            {
				if([view isKindOfClass:[NSView class]])
				{
					NSLog(@"close view");
					[controller removeAnnotationView:view];
					[controller removeDataWindow:[[(NSView*)view window] windowController]];
				}
				else if ([view isKindOfClass:[NSWindowController class]])
				{
					NSLog(@"close window");
					[controller removeAnnotationView:view];
					[controller removeDataWindow:(NSWindowController*)view];
				}
			}
		}
	}
}

- (NSArray*)viewMenuItems
{
	NSMutableArray *menuItems = [NSMutableArray arrayWithCapacity:5];
	
	AnnotationDocument *annotationDoc = [controller document];
	MultiTimelineView *timelineView = [controller timelineView];
	VideoProperties *videoInfo = [[controller document] videoProperties];
	
	NSMenuItem *zoomInItem = [[NSMenuItem alloc] initWithTitle:@"Increase Movie Zoom" action:NULL keyEquivalent:@""];
	[menuItems addObject:zoomInItem];
	[zoomInItem setEnabled:YES];
	[zoomInItem release];
	NSMenuItem *zoomOutItem = [[NSMenuItem alloc] initWithTitle:@"Decrease Movie Zoom" action:NULL keyEquivalent:@""];
	[menuItems addObject:zoomOutItem];
	[zoomOutItem setEnabled:YES];
	[zoomOutItem release];
	NSMenuItem *zoomSeparator = [NSMenuItem separatorItem];
	[menuItems addObject:zoomSeparator];
	
	NSMenuItem *addTimelineMenuItem = [[NSMenuItem alloc] initWithTitle:@"Add Timeline" action:NULL keyEquivalent:@""];
	[menuItems addObject:addTimelineMenuItem];
	[addTimelineMenuItem setEnabled:YES];
	NSMenu *addTimelineMenu = [[NSMenu alloc] initWithTitle:@"Add Timeline"];
	[addTimelineMenu setAutoenablesItems:NO];
	[addTimelineMenuItem setSubmenu:addTimelineMenu];
	[addTimelineMenu release];
	[addTimelineMenuItem release];
	
	NSMenuItem* annotationsItem = [addTimelineMenu addItemWithTitle:@"Annotations" action:@selector(addNewAnnotationTimeline:) keyEquivalent:@""];
	[annotationsItem setTarget:timelineView];
	
	NSMenuItem* tapestryItem = [addTimelineMenu addItemWithTitle:DPTapestryTimelineMenuTitle action:@selector(addNewDataTimeline:) keyEquivalent:@""];
	[tapestryItem setRepresentedObject:nil];
	[tapestryItem setTarget:timelineView];
	
	NSMenuItem* keyframesItem = [addTimelineMenu addItemWithTitle:DPKeyframeTimelineMenuTitle action:@selector(addNewKeyframeTimeline:) keyEquivalent:@""];
	[keyframesItem setRepresentedObject:videoInfo];
	[keyframesItem setTarget:timelineView];
	[keyframesItem setSubmenu:nil];
	
	NSMenuItem* audioItem = [addTimelineMenu addItemWithTitle:DPAudioTimelineMenuTitle action:@selector(addNewAudioTimeline:) keyEquivalent:@""];
	[audioItem setRepresentedObject:videoInfo];
	[audioItem setTarget:timelineView];
	[audioItem setSubmenu:nil];
	
	if(![videoInfo hasAudio])
	{
		//NSLog(@"No Audio");
		[audioItem setEnabled:NO];
	}
	
	NSMenuItem *videoItem = nil;
	NSMenu *keyframesMenu = nil;
	NSMenu *audioMenu = nil;
	
	NSMenu *zoomInMenu = nil;
	NSMenu *zoomOutMenu = nil;
	
	if([[annotationDoc mediaProperties] count] > 0)
	{
		
		NSMenuItem *showMovieMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Movie" action:NULL keyEquivalent:@""];
		[menuItems addObject:showMovieMenuItem];
		[showMovieMenuItem setEnabled:YES];
		NSMenu *showMovieMenu = [[NSMenu alloc] initWithTitle:@"Show Movie"];
		[showMovieMenuItem setSubmenu:showMovieMenu];
		[showMovieMenu release];
		[showMovieMenuItem release];
	
		for(VideoProperties *video in [annotationDoc mediaProperties])
		{
			if([video hasVideo])
			{				
				NSMenuItem *showVideoItem = [showMovieMenu addItemWithTitle:[video title] 
																action:@selector(showMediaFromObject:)
														 keyEquivalent:@""];
				[showVideoItem setTarget:controller];
				[showVideoItem setRepresentedObject:video];
				
				if(!zoomInMenu)
				{
					zoomInMenu = [[NSMenu alloc] initWithTitle:@"Zoom Movie In"];
					[zoomInItem setSubmenu:zoomInMenu];
					[zoomInMenu release];
					
					zoomOutMenu = [[NSMenu alloc] initWithTitle:@"Zoom Movie Out"];
					[zoomOutItem setSubmenu:zoomOutMenu];
					[zoomOutMenu release];
					
					videoItem = [zoomInMenu addItemWithTitle:[videoInfo title] 
																		action:@selector(zoomInVideoAction:)
																 keyEquivalent:@""];
					[videoItem setTarget:self];
					[videoItem setRepresentedObject:videoInfo];
					
					NSMenuItem *videoItem = [zoomOutMenu addItemWithTitle:[videoInfo title] 
																		  action:@selector(zoomOutVideoAction:)
																   keyEquivalent:@""];
					[videoItem setTarget:self];
					[videoItem setRepresentedObject:videoInfo];
					
				}
				
				videoItem = [zoomInMenu addItemWithTitle:[video title] 
																	action:@selector(zoomInVideoAction:)
															 keyEquivalent:@""];
				[videoItem setTarget:self];
				[videoItem setRepresentedObject:video];
				
				videoItem = [zoomOutMenu addItemWithTitle:[video title] 
																	  action:@selector(zoomOutVideoAction:)
															   keyEquivalent:@""];
				[videoItem setTarget:self];
				[videoItem setRepresentedObject:video];
				
				if(!keyframesMenu)
				{
					keyframesMenu = [[NSMenu alloc] init];
					[keyframesItem setSubmenu:keyframesMenu];
					[keyframesMenu release];
					
					videoItem = [keyframesMenu addItemWithTitle:[videoInfo title] action:@selector(addNewKeyframeTimeline:) keyEquivalent:@""];
					[videoItem setRepresentedObject:videoInfo];
					[videoItem setTarget:timelineView];
				}
				
				videoItem = [keyframesMenu addItemWithTitle:[video title] action:@selector(addNewKeyframeTimeline:) keyEquivalent:@""];
				[videoItem setRepresentedObject:video];
				[videoItem setTarget:timelineView];
			}
			
			if([video hasAudio])
			{
				
				if(!audioMenu)
				{
					audioMenu = [[NSMenu alloc] init];
					[audioItem setSubmenu:audioMenu];
					[audioItem setEnabled:YES];
					[audioMenu release];
					
					if([videoInfo hasAudio])
					{
						videoItem = [audioMenu addItemWithTitle:[videoInfo title] action:@selector(addNewAudioTimeline:) keyEquivalent:@""];
						[videoItem setRepresentedObject:videoInfo];
						[videoItem setTarget:timelineView];
					}
				}
				videoItem = [audioMenu addItemWithTitle:[video title] action:@selector(addNewAudioTimeline:) keyEquivalent:@""];
				[videoItem setRepresentedObject:video];
				[videoItem setTarget:timelineView];
			}
		}
	}
	else
	{
		[zoomInItem setTarget:self];
		[zoomInItem setAction:@selector(zoomInVideoAction:)];
		[zoomInItem setRepresentedObject:videoInfo];
		
		[zoomOutItem setAction:@selector(zoomOutVideoAction:)];
		[zoomOutItem setTarget:self];
		[zoomOutItem setRepresentedObject:videoInfo];
	}
	
	NSMenuItem *menuItem = nil;
	
    for(NSString *className in [dataTypeNames allKeys])
    {
        BOOL groupBySource = YES;
        NSMutableArray *sources = [[NSMutableArray alloc] init];
        NSString *dataTypeName = [dataTypeNames objectForKey:className];
        NSMenuItem *dataMenuItem = nil;
        Class DataClass = NSClassFromString(className);
        
        for(TimeCodedData *dataSet in [annotationDoc dataSets])
        {
            if([dataSet isKindOfClass:DataClass])
            {
                if(groupBySource && [sources containsObject:[dataSet source]])
                {
                    continue;
                }
                else if(!dataMenuItem)
                {
                    dataMenuItem = [[NSMenuItem alloc] initWithTitle:[@"Show " stringByAppendingString:dataTypeName] action:NULL keyEquivalent:@""];
                    [dataMenuItem setAction:@selector(showDataAction:)];
                    [dataMenuItem setTarget:controller];
                    [dataMenuItem setRepresentedObject:dataSet];
                    [menuItems addObject:dataMenuItem];
                    [dataMenuItem setEnabled:YES];
                    [dataMenuItem release];
                }
                else if(![dataMenuItem submenu])
                {
                    
                    NSMenu* dataMenu = [[NSMenu alloc] initWithTitle:[@"Show " stringByAppendingString:dataTypeName] ];
                    [dataMenuItem setSubmenu:dataMenu];
                    [dataMenu release];
                    
                    
                    TimeCodedData *menuData = (TimeCodedData*)[dataMenuItem representedObject];
                    NSString *menuTitle = nil;
                    if(groupBySource)
                    {
                        menuTitle = [[menuData source] name];
                    }
                    else
                    {
                        menuTitle = [menuData name];
                    }
                    menuItem = [dataMenu addItemWithTitle:menuTitle
                                                    action:@selector(showDataAction:)
                                             keyEquivalent:@""];
                    [menuItem setRepresentedObject:menuData];
                    [menuItem setTarget:controller];
                    
                    if(groupBySource)
                    {
                        menuTitle = [[dataSet source] name];
                    }
                    else
                    {
                        menuTitle = [dataSet name];
                    }
                    menuItem = [dataMenu addItemWithTitle:menuTitle 
                                                    action:@selector(showDataAction:)
                                             keyEquivalent:@""];
                    [menuItem setRepresentedObject:dataSet];
                    [menuItem setTarget:controller];
                }
                else
                {
                    NSMenu* dataMenu = [dataMenuItem submenu];
                    NSString *menuTitle = nil;
                    if(groupBySource)
                    {
                        menuTitle = [[dataSet source] name];
                    }
                    else
                    {
                        menuTitle = [dataSet name];
                    }
                    menuItem = [dataMenu addItemWithTitle:menuTitle
                                                    action:@selector(showDataAction:)
                                             keyEquivalent:@""];
                    [menuItem setRepresentedObject:dataSet];
                    [menuItem setTarget:controller];
                }
                [sources addObject:[dataSet source]];
            }
        }
    }
    
    
    NSMenuItem *transcriptMenuItem = nil;
    
	for(TimeCodedData *dataSet in [annotationDoc dataSets])
	{
		if([dataSet isKindOfClass:[TranscriptData class]])
		{
			if(!transcriptMenuItem)
			{
				transcriptMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Transcript" action:NULL keyEquivalent:@""];
				[transcriptMenuItem setAction:@selector(showDataAction:)];
				[transcriptMenuItem setTarget:controller];
				[transcriptMenuItem setRepresentedObject:dataSet];
				[menuItems addObject:transcriptMenuItem];
				[transcriptMenuItem setEnabled:YES];
				[transcriptMenuItem release];
			}
			else if(![transcriptMenuItem submenu])
			{
				
				NSMenu* notesMenu = [[NSMenu alloc] initWithTitle:@"Show Transcript"];
				[transcriptMenuItem setSubmenu:notesMenu];
				[notesMenu release];
				
				id notesData = [transcriptMenuItem representedObject];
				menuItem = [notesMenu addItemWithTitle:[notesData name] 
												action:@selector(showDataAction:)
										 keyEquivalent:@""];
				[menuItem setRepresentedObject:notesData];
				[menuItem setTarget:controller];
				
				notesData = dataSet;
				menuItem = [notesMenu addItemWithTitle:[notesData name] 
												action:@selector(showDataAction:)
										 keyEquivalent:@""];
				[menuItem setRepresentedObject:notesData];
				[menuItem setTarget:controller];
			}
			else
			{
				NSMenu* notesMenu = [transcriptMenuItem submenu];
				id notesData = dataSet;
				menuItem = [notesMenu addItemWithTitle:[notesData name] 
												action:@selector(showDataAction:)
										 keyEquivalent:@""];
				[menuItem setRepresentedObject:notesData];
				[menuItem setTarget:controller];
			}
		}
	}
	
//	if([controller imageSequenceView])
//	{
//		NSMenuItem *imageMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Image Sequence" action:NULL keyEquivalent:@""];
//		[imageMenuItem setAction:@selector(showWindow:)];
//		[imageMenuItem setTarget:[[[controller imageSequenceView] window] windowController]];
//		[menuItems addObject:imageMenuItem];
//		[imageMenuItem setEnabled:YES];
//		[imageMenuItem release];
//	}
	
	
	for(NSMenuItem *item in menuItems)
	{
		[item setTag:2];
	}
	
	return menuItems;
}


#pragma mark Videos

- (void)zoomInVideoAction:(id)sender
{
	if([[sender representedObject] isKindOfClass:[VideoProperties class]])
	{
		[self zoomInVideo:(VideoProperties*)[sender representedObject]];
	}
}
- (void)zoomOutVideoAction:(id)sender
{
	if([[sender representedObject] isKindOfClass:[VideoProperties class]])
	{
		[self zoomOutVideo:(VideoProperties*)[sender representedObject]];
	}
}

- (void)zoomInVideo:(VideoProperties*)video
{
	AFMovieView *movieView = [self viewForVideo:video];
	if(movieView)
	{
		[movieView zoomInMovie:[video movie]];
	}
}

- (void)zoomOutVideo:(VideoProperties*)video
{
	AFMovieView *movieView = [self viewForVideo:video];
	if(movieView)
	{
		[movieView zoomOutMovie:[video movie]];
	}
}

- (AFMovieView*)viewForVideo:(VideoProperties*)video
{
	NSView *mainView = [controller mainView];
	if([mainView isKindOfClass:[AFMovieView class]])
	{
		for(AVPlayer* movie in [(AFMovieView*)mainView movies])
		{
			if([video movie] == movie)
			{
				return (AFMovieView*)mainView;
			}
		}
	}
	
	NSArray *annotationViews = [controller annotationViews];
	for(id view in annotationViews)
	{
		if([view isMemberOfClass:[MovieViewerController class]])
		{
			if([view videoProperties] == video)
			{
				return [(MovieViewerController*)view movieView];
			}
		}
	}
	return nil;
}

- (void)closeVideo:(VideoProperties*)video
{
    AFMovieView *movieView = [self viewForVideo:video];
    if(movieView == [controller mainView])
    {
        [movieView removeMovie:[video movie]];
    }
    else if(movieView)
    {
        [[movieView window] close];
    }
}

- (void)updateMediaViews:(NSNotification*)notification
{
    NSArray *mediaRemoved = [[notification userInfo] objectForKey:DPMediaRemovedKey];
    NSArray *mediaAdded = [[notification userInfo] objectForKey:DPMediaAddedKey];
    if(mediaRemoved)
    {
        for(VideoProperties* video in mediaRemoved)
        {
            [self closeVideo:video];
        }
    }
    
    if(mediaAdded)
    {
        VideoProperties *mainVideo = [[controller document] videoProperties];
        if([mediaAdded containsObject:mainVideo]
           && [mainVideo hasAudio]
           && ![mainVideo hasVideo])
        {
//            TimelineView *timeline = [[TimelineView alloc] initWithFrame:[[[controller timelineView] baseTimeline] frame]];
//			[timeline setMovie:[controller movie]];
//			AudioVisualizer *viz = [[AudioVisualizer alloc] initWithTimelineView:timeline];
//            [viz setVideoProperties:mainVideo];
//            [timeline setSegmentVisualizer:viz];
//			[[controller timelineView] addTimelines:[NSArray arrayWithObject:timeline]];
        }
    }
}

- (void)createAudioTimeline:(VideoProperties*)movie
{
    if([movie hasAudio])
    {
        TimelineView *timeline = [[TimelineView alloc] initWithFrame:[[[controller timelineView] baseTimeline] frame]];
        [timeline setMovie:[controller movie]];
        
        AudioVisualizer *viz = [[AudioVisualizer alloc] initWithTimelineView:timeline];
        [viz setVideoProperties:movie];
        [timeline setSegmentVisualizer:viz];
        [timeline addAnnotations:[[AnnotationDocument currentDocument] annotations]];
        
        [[controller timelineView] addTimeline:timeline];
        
        [viz release];
        [timeline release];
    }
}

#pragma mark Timelines Outline View

- (void)finishAddTimeline:(id)sender;
{
	[controller cancelAddTimeline:self];
	
	if([sender isKindOfClass:[NSOutlineView class]])
	{
		DPTimelineOption *option = (DPTimelineOption*)[sender itemAtRow:[sender selectedRow]];
		
		if(option && ([option.options count] == 0))
		{
            BOOL filterAnnotations = ([[[controller document] categories] count] > 8);
            
			TimelineView *timeline = [[TimelineView alloc] initWithFrame:[[[controller timelineView] baseTimeline] frame]];
			[timeline setMovie:[controller movie]];
            
            if(filterAnnotations)
            {
                [timeline setAnnotationFilter:[AnnotationCategoryFilter filterForCategory:nil]];
            }
            
			[timeline addAnnotations:[[AnnotationDocument currentDocument] annotations]];
			
			SegmentVisualizer *viz = [[option.visualizer alloc] initWithTimelineView:timeline];
			if([option.data isKindOfClass:[VideoProperties class]])
			{
				[viz setVideoProperties:(VideoProperties*)option.data];
			}
			else if([option.data isKindOfClass:[TimeSeriesData class]])
			{
				[timeline setData:(TimeSeriesData*)option.data];
                [timeline setLabel:[(TimeSeriesData*)option.data name]];
			}
			else if([option.data isKindOfClass:[DPActivityLog class]])
			{
				[(ActivityFramesVisualizer*)viz setActivityLog:(DPActivityLog*)option.data];
				[viz setVideoProperties:[[AnnotationDocument currentDocument] videoProperties]];
			}

			[timeline setSegmentVisualizer:viz];
			[[controller timelineView] addTimelines:[NSArray arrayWithObject:timeline]];
			
            if([viz isKindOfClass:[AnnotationVisualizer class]])
            {
                [timeline editAnnotationFilters:self];
            }
            
			[viz release];
			[timeline release];
		}
	}

}


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	
    return (item == nil) ? [timelineOptions count] : [((DPTimelineOption*)item).options count];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return ([((DPTimelineOption*)item).options count] > 0) ? YES : NO;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	
	if(item == nil)
	{
		return [timelineOptions objectAtIndex:index];
	}
	else if ([((DPTimelineOption*)item).options count] > 0)
    {
        return [((DPTimelineOption*)item).options objectAtIndex:index];
    }
	else
	{
		return nil;
	}

}


- (BOOL)outlineView:(NSOutlineView *)sender isGroupItem:(id)item {
	if ([((DPTimelineOption*)item).options count] > 0)
		return YES;
	else
		return NO;
}

- (void)outlineView:(NSOutlineView *)sender willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if ([((DPTimelineOption*)item).options count] > 0) {
		NSMutableAttributedString *newTitle = [[cell attributedStringValue] mutableCopy];
		[newTitle replaceCharactersInRange:NSMakeRange(0,[newTitle length]) withString:[[newTitle string] uppercaseString]];
		[cell setAttributedStringValue:newTitle];
		[newTitle release];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	if ([((DPTimelineOption*)item).options count] > 0)
		return NO;
	else
		return YES;
}

//- (NSIndexSet *)outlineView:(NSOutlineView *)outlineView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
//{
//	if([[(AnnotationCategory*)[categoryOutlineView itemAtRow:[proposedSelectionIndexes firstIndex]] values] count] > 0)
//	{
//		return [NSIndexSet indexSetWithIndex:[proposedSelectionIndexes firstIndex] + 1];
//	}
//	else
//	{
//		return proposedSelectionIndexes;
//	}
//	
//}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	if([item isKindOfClass:[DPTimelineOption class]])
	{
		return ((DPTimelineOption*)item).title;
	}
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	[self finishAddTimeline:outlineView];
	return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	[self finishAddTimeline:[aNotification object]];
}



@end
