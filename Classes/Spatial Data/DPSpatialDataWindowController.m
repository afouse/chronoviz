//
//  DPSpatialDataWindowController.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/30/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPSpatialDataWindowController.h"
#import "DPSpatialDataView.h"
#import "SpatialTimeSeriesData.h"
#import "AnnotationDocument.h"
#import "VideoProperties.h"
#import "AppController.h"
#import "DataSource.h"
#import "TimelineView.h"
#import "ColorMappedTimeSeriesVisualizer.h"
#import "DPMaskedSelectionView.h"
#import "DPMaskedSelectionArea.h"
#import "DPDataSelectionPanel.h"
#import "DPSelectionDataSource.h"
#import "DPSpatialDataBase.h"
#import <CoreServices/CoreServices.h>

@implementation DPSpatialDataWindowController

@synthesize currentlySelectedDataSet;

- (id)init
{
	if(![super initWithWindowNibName:@"DPSpatialDataWindow"])
		return nil;
	
    selectionTimeline = nil;
    currentlySelectedDataSet = nil;
    
    proxyDataSet = [[SpatialTimeSeriesData alloc] init];
    [proxyDataSet setName:@"All Data Sets"];
    [proxyDataSet setSpatialBase:[[[DPSpatialDataBase alloc] init] autorelease]];
    
    [proxyDataSet.spatialBase addObserver:self
                       forKeyPath:@"xOffset"
                          options:0
                          context:NULL];
    
    [proxyDataSet.spatialBase addObserver:self
                       forKeyPath:@"yOffset"
                          options:0
                          context:NULL];
    
    [proxyDataSet.spatialBase addObserver:self
                   forKeyPath:@"xReflect"
                      options:0
                      context:NULL];
    
    [proxyDataSet.spatialBase addObserver:self
                   forKeyPath:@"yReflect"
                      options:0
                      context:NULL];
    
	return self;
}

- (id<AnnotationView>)annotationView
{
	return [self spatialDataView];
}

- (DPSpatialDataView*)spatialDataView
{
	[self window];
	return spatialDataView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{

    if ([keyPath isEqualToString:@"xReflect"]) {
        
        for(SpatialTimeSeriesData *data in [spatialDataView dataSets])
        {
            data.spatialBase.xReflect = proxyDataSet.spatialBase.xReflect;
        }
        [spatialDataView forceUpdate];
        
    }
    else if ([keyPath isEqualToString:@"yReflect"]) {
        
        for(SpatialTimeSeriesData *data in [spatialDataView dataSets])
        {
            data.spatialBase.yReflect = proxyDataSet.spatialBase.yReflect;
        }
        [spatialDataView forceUpdate];
    }
    else if ([keyPath isEqualToString:@"xOffset"]) {
        
        for(SpatialTimeSeriesData *data in [spatialDataView dataSets])
        {
            data.xOffset = proxyDataSet.xOffset;
        }
        
    }
    else if ([keyPath isEqualToString:@"yOffset"]) {
        
        for(SpatialTimeSeriesData *data in [spatialDataView dataSets])
        {
            data.yOffset = proxyDataSet.yOffset;
        }
        
    }

}

- (IBAction)configureVisualization:(id)sender {
    
    NSString *buttonTitle = @"Select Movie";
    [backgroundMoviesButton removeAllItems];
    [backgroundMoviesButton addItemWithTitle:buttonTitle];
    [backgroundMoviesButton setTitle:buttonTitle];
    
    VideoProperties *primary = [[AnnotationDocument currentDocument] videoProperties];
    [backgroundMoviesButton addItemWithTitle:[primary title]];
    [[backgroundMoviesButton lastItem] setRepresentedObject:primary];
    [[backgroundMoviesButton lastItem] setAction:@selector(setMovieAction:)];
    [[backgroundMoviesButton lastItem] setTarget:self];
    
    for(VideoProperties* props in [[AnnotationDocument currentDocument] mediaProperties])
    {
        [backgroundMoviesButton addItemWithTitle:[props title]];
        [[backgroundMoviesButton lastItem] setRepresentedObject:props];
        [[backgroundMoviesButton lastItem] setAction:@selector(setMovieAction:)];
        [[backgroundMoviesButton lastItem] setTarget:self];
    }
    
    [dataSetsButton removeAllItems];
    [dataSetsButton addItemWithTitle:@"All Data Sets"];
    [[dataSetsButton lastItem] setRepresentedObject:proxyDataSet];
    [[dataSetsButton menu] addItem:[NSMenuItem separatorItem]];
    for(TimeSeriesData *data in [spatialDataView dataSets])
    {
        [dataSetsButton addItemWithTitle:[NSString stringWithFormat:@"%@ (%@)",[data name],[[data source] name]]];
        [[dataSetsButton lastItem] setRepresentedObject:data];
    }

    [self selectConfigurationDataSet:self];
    
    
    [NSApp beginSheet: configurationPanel
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    
}

- (IBAction)closeVisualizationConfiguration:(id)sender {
    
    [configurationPanel makeFirstResponder:nil];
    [NSApp endSheet:configurationPanel];
    [spatialDataView setCurrentTime:[[AppController currentApp] currentTime]];
}

- (IBAction)selectConfigurationDataSet:(id)sender
{
    self.currentlySelectedDataSet = [[dataSetsButton selectedItem] representedObject];
}

- (void) dealloc
{
    [proxyDataSet.spatialBase removeObserver:self forKeyPath:@"xOffset"];
    [proxyDataSet.spatialBase removeObserver:self forKeyPath:@"yOffset"];
    [proxyDataSet.spatialBase removeObserver:self forKeyPath:@"xReflect"];
    [proxyDataSet.spatialBase removeObserver:self forKeyPath:@"yReflect"];
    [proxyDataSet release];
    
    self.currentlySelectedDataSet = nil;
    [dataSelectionPanel release];
	[spatialDataSets release];
	[super dealloc];
}


- (void)windowDidLoad
{
    

    SInt32 major = 0;
    SInt32 minor = 0;   
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);
    if ((major == 10) && (minor <= 6)) {
        for(NSToolbarItem *item in [[[self window] toolbar] items])
        {
            if([[item view] isKindOfClass:[NSSegmentedControl class]])
            {
                [(NSSegmentedControl*)[item view] setSegmentStyle:NSSegmentStyleCapsule];
            }
        }
    }
    

}

- (IBAction)showDataSets:(id)sender
{
    if(!dataSelectionPanel)
    {
        dataSelectionPanel = [[DPDataSelectionPanel alloc] initForView:spatialDataView];
        [dataSelectionPanel setDataClass:[SpatialTimeSeriesData class]];
    }
    
    [dataSelectionPanel showDataSets:self];
    
}


- (IBAction)changeVisualizationAction:(id)sender {
    if([sender isKindOfClass:[NSSegmentedControl class]])
	{
		int clickedSegment = [sender selectedSegment];
		int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
		if(clickedSegmentTag == 0)
		{
			[spatialDataView setShowPosition:!spatialDataView.showPosition];
		}
		else if(clickedSegmentTag == 1)
		{
			[spatialDataView setShowPath:!spatialDataView.showPath];
		}
		else
		{
			[spatialDataView setShowConnections:!spatialDataView.showConnections];
		}
	}
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

- (IBAction)toggleShowPaths:(id)sender
{
	[spatialDataView togglePathVisiblity:self];
}

- (NSImage*)imageWithWindow:(int)wid {
    
     // snag the image
     CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, [[self window] windowNumber], kCGWindowImageBoundsIgnoreFraming);
     
     // little bit of error checking
     if(CGImageGetWidth(windowImage) <= 1) {
         CGImageRelease(windowImage);
         return nil;
     }
     
     // Create a bitmap rep from the window and convert to NSImage...
     NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage: windowImage];
     NSImage *image = [[NSImage alloc] init];
     [image addRepresentation: bitmapRep];
     [bitmapRep release];
     CGImageRelease(windowImage);
     
     return [image autorelease];   
     }

- (IBAction)saveImageSequence:(id)sender
{
    NSTimeInterval interval = 10;
    NSTimeInterval duration = 0;
    QTGetTimeInterval([[AnnotationDocument currentDocument] duration], &duration);
    
    for(NSTimeInterval currentTime = 0; currentTime < duration; currentTime += interval)
    {
        //CGImageRef image = [spatialDataView frameImageAtTime:QTMakeTimeWithTimeInterval(currentTime)];
        
        NSWindow *thewindow = [self window];
        
        NSRect viewFrame = [spatialDataView frame];
        viewFrame = [spatialDataView convertRect:viewFrame toView:nil];
        NSPoint origin = viewFrame.origin;
        origin.y = origin.y + viewFrame.size.height + 65;
        viewFrame.size.height = viewFrame.size.height - 5;
        origin = [thewindow convertBaseToScreen:origin];
        CGRect captureRect = CGRectMake(origin.x, origin.y, viewFrame.size.width, viewFrame.size.height);
        
        [spatialDataView setCurrentTime:QTMakeTimeWithTimeInterval(currentTime)];
        
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
        
             CGImageRef image = CGWindowListCreateImage(captureRect, kCGWindowListOptionIncludingWindow, [[self window] windowNumber], kCGWindowImageBoundsIgnoreFraming);
        
        NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:image];    
        
        //NSBitmapImageRep *bitmap = [spatialDataView bitmapAtTime:QTMakeTimeWithTimeInterval(currentTime)];
        
        //NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
        NSData *imageData = [bitmap representationUsingType:NSPNGFileType properties:nil];
        
        NSString *filename = [[[[AnnotationDocument currentDocument] 
                               annotationsDirectory] 
                               stringByDeletingLastPathComponent]
                              stringByAppendingFormat:@"/spatialdata-%i.png",(int)currentTime];
        
        
        [imageData writeToFile:filename atomically:NO];
        
        CGImageRelease(image);
        
        [bitmap release];
    }
    
    
}

- (IBAction)setBackgroundAction:(id)sender {
    
    if([configurationPanel isVisible])
        [NSApp endSheet:configurationPanel];
    
    NSOpenPanel *openPanel  = [[NSOpenPanel alloc] init];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setAllowedFileTypes:[NSImage imageFileTypes]];
    
    [openPanel beginSheetForDirectory:nil
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
    
}

- (IBAction)setMovieAction:(id)sender {
    
    if([[sender representedObject] isKindOfClass:[VideoProperties class]])
    {
        VideoProperties *props = [sender representedObject];
        [spatialDataView setBackgroundMovie:[props movie]];
    }
    else
    {
        [spatialDataView setBackgroundMovie:[[AnnotationDocument currentDocument] movie]];
    }
    
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
    if(returnCode == NSOKButton)
    {
        SpatialTimeSeriesData *currentSelection = self.currentlySelectedDataSet;
        self.currentlySelectedDataSet = nil;
       [spatialDataView setBackgroundFile:[[[panel URLs] objectAtIndex:0] path]];
        self.currentlySelectedDataSet = currentSelection;
    }
    
    [panel release];
}
   
#pragma mark Selection

- (void)updateSelection:(id)sender
{
    NSArray *dataSets = [selectionTimeline dataSets];
    for(TimeCodedData *dataSet in dataSets)
    {
        [selectionTimeline removeData:dataSet];
    }
	
    NSSet *selectionDataSources = [[spatialDataView selectionView] selectionDataSources];
    DPSelectionDataSource *selectionSource = [selectionDataSources anyObject];
    
    for(DPMaskedSelectionArea *selectionRegion in [selectionSource selectionAreas])
    {
        if(!CGRectIsNull(selectionRegion.area))
        {
            for(DPSelectionDataSource *selectionSource in selectionDataSources)
            {
                TimeCodedData *data = [selectionSource dataForSelection:selectionRegion];
                if(data && [data isKindOfClass:[TimeSeriesData class]])
                    [selectionTimeline addData:(TimeSeriesData*)data];
            }
        }
    }
    
//    for(NSMutableDictionary *selectionRegion in [[spatialDataView selectedTimeSeries] allValues])
//    {
//        for(TimeSeriesData *data in [selectionRegion allValues])
//        {
//            [selectionTimeline addData:data];
//        }
//    }
    
    ColorMappedTimeSeriesVisualizer *viz = [[ColorMappedTimeSeriesVisualizer alloc] initWithTimelineView:selectionTimeline];
    [viz setSubsetMethod:DPSubsetMethodAverage];
    [selectionTimeline setSegmentVisualizer:viz];
    for(TimeSeriesData *data in [selectionTimeline dataSets])
    {
        //NSGradient *colormap = [[NSGradient alloc] initWithStartingColor:[NSColor darkGrayColor] endingColor:[data color]];
        NSGradient *colormap = [[NSGradient alloc] initWithColorsAndLocations:[NSColor darkGrayColor],0.0,[data color],0.3,[data color],1.0,nil];
        [viz setColorMap:colormap forDataID:[data uuid]];
        [colormap release];
    }
    [viz release];
    
}

- (IBAction)saveCurrentSelection:(id)sender
{
    [spatialDataView.selectionView saveCurrentSelection:self];
}

- (IBAction)deleteCurrentSelection:(id)sender
{
    [spatialDataView.selectionView deleteCurrentSelection:self];
}

- (IBAction)toggleSelection:(id)sender
{
    if(!selectionTimeline)
    {
//        NSRect visible = [spatialDataView visibleRect];
//        
//        NSRect scrollFrame = [notesScrollView frame];
//        scrollFrame.size.height = scrollFrame.size.height - 100;
//        scrollFrame.origin.y = 100;
//        [notesScrollView setFrame:scrollFrame];
//        
//        visible.size.height = visible.size.height - 100;
//        
//        [anotoView scrollRectToVisible:visible];
        
        NSRect dataFrame = [spatialDataView frame];
        
        CGFloat totalAddedHeight = 0;
        
        NSRect timelineFrame = dataFrame;
        timelineFrame.size.height = 100;
        timelineFrame.origin.y = 0;
        totalAddedHeight += timelineFrame.size.height;
        
        NSRect selectionFrame = dataFrame;
        selectionFrame.size.height = [selectionManagementView bounds].size.height;
        selectionFrame.origin.y = totalAddedHeight;
        totalAddedHeight += selectionFrame.size.height;
        
        NSRect windowframe = [[self window] frame];
        windowframe.size.height = windowframe.size.height + totalAddedHeight;
        windowframe.origin.y = windowframe.origin.y - totalAddedHeight;
        [[self window] setFrame:windowframe display:NO animate:NO];
        
        dataFrame.origin.y = dataFrame.origin.y + totalAddedHeight;
        [spatialDataView setFrame:dataFrame];
        
        selectionTimeline = [[TimelineView alloc] initWithFrame:timelineFrame];
        [selectionTimeline setMovie:[[AnnotationDocument currentDocument] movie]];
        //[selectionTimeline toggleShowAnnotations];
        [selectionTimeline setShowActionButtons:NO];
        
        [selectionTimeline showTimes:YES];
        [selectionTimeline setAutoresizingMask:(NSViewMaxYMargin | NSViewWidthSizable)];
        
        [[[self window] contentView] addSubview:selectionTimeline];
        [selectionTimeline release];
        
        [selectionManagementView setFrame:selectionFrame];
        [[[self window] contentView] addSubview:selectionManagementView];
        
        [[AppController currentApp] addAnnotationView:selectionTimeline];
        [selectionTimeline reset];
        
        [spatialDataView toggleSelectionMode:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateSelection:)
                                                     name:DPMaskedSelectionChangedNotification
                                                   object:spatialDataView];
            
    }
    else
    {
        NSRect dataFrame = [spatialDataView frame];
        CGFloat totalAddedHeight = [selectionTimeline frame].size.height + [selectionManagementView frame].size.height;
        
        [[AppController currentApp] removeAnnotationView:selectionTimeline];
        [selectionTimeline removeFromSuperview];
        selectionTimeline = nil;
        
        [selectionManagementView removeFromSuperview];
        
        NSRect windowframe = [[self window] frame];
        windowframe.size.height = windowframe.size.height - totalAddedHeight;
        [[self window] setFrame:windowframe display:NO animate:YES];
        
        dataFrame.origin.y = dataFrame.origin.y - totalAddedHeight;
        [spatialDataView setFrame:dataFrame];
        
        
        [spatialDataView toggleSelectionMode:self];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
    }
}




@end