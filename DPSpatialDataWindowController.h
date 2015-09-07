//
//  DPSpatialDataWindowController.h
//  ChronoViz
//
//  Created by Adam Fouse on 8/30/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationViewController.h"
@class DPSpatialDataView;
@class TimelineView;
@class AnnotationCategory;
@class DPDataSelectionPanel;
@class SpatialTimeSeriesData;

@interface DPSpatialDataWindowController : NSWindowController <AnnotationViewController> {
	IBOutlet DPSpatialDataView *spatialDataView;
	IBOutlet NSToolbar *toolbar;
	
    IBOutlet NSPanel *configurationPanel;
    IBOutlet NSPopUpButton *backgroundMoviesButton;
	IBOutlet NSButton *showPathsButton;	

    IBOutlet NSPopUpButton *dataSetsButton;
    IBOutlet SpatialTimeSeriesData *currentlySelectedDataSet;
    
	NSMutableArray *spatialDataSets;
    
    TimelineView *selectionTimeline;
	AnnotationCategory *selectionCategory;
    
    IBOutlet NSView *selectionManagementView;
    IBOutlet NSTextField *selectionNameField;
    IBOutlet NSColorWell *selectionColorWell;
    
    DPDataSelectionPanel *dataSelectionPanel;
    
    SpatialTimeSeriesData *proxyDataSet;
}

@property(readonly) DPSpatialDataView* spatialDataView;
@property(retain) SpatialTimeSeriesData* currentlySelectedDataSet;

- (IBAction)showDataSets:(id)sender;
- (IBAction)changeVisualizationAction:(id)sender;
- (IBAction)configureVisualization:(id)sender;
- (IBAction)closeVisualizationConfiguration:(id)sender;
- (IBAction)selectConfigurationDataSet:(id)sender;

- (IBAction)saveImageSequence:(id)sender;
- (IBAction)setBackgroundAction:(id)sender;
- (IBAction)setMovieAction:(id)sender;

- (IBAction)saveCurrentSelection:(id)sender;
- (IBAction)deleteCurrentSelection:(id)sender;
- (IBAction)toggleSelection:(id)sender;

@end
