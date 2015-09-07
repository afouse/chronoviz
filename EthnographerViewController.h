//
//  EthnographerViewController.h
//  ChronoViz
//
//  Created by Adam Fouse on 8/24/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationViewController.h"
@class EthnographerNotesView;
@class TimelineView;
@class AnnotationCategory;
@class AnotoNotesData;
@class DPDataSelectionPanel;

@interface EthnographerViewController : NSWindowController <AnnotationViewController> {
	
	IBOutlet EthnographerNotesView *anotoView;
	IBOutlet NSScrollView *notesScrollView;
	
    DPDataSelectionPanel *dataSelectionPanel;
    
	IBOutlet NSPanel *dataSetsPanel;
	IBOutlet NSTableView *dataSetsTable;
	id colorEditDataSet;
	
    IBOutlet NSView *sessionControlView;
    IBOutlet NSTextField *sessionNameField;
    IBOutlet NSColorWell *sessionColorButton;
	NSMutableArray *notesDataSets;
    
    AnotoNotesData *currentSession;
	
	TimelineView *selectionTimeline;
	AnnotationCategory *selectionCategory;
}

@property(retain) AnotoNotesData *currentSession;

- (EthnographerNotesView*)anotoView;

- (IBAction)changePageButtonClick:(id)sender;
- (IBAction)rotatePageButtonClick:(id)sender;
- (IBAction)zoomButtonClick:(id)sender;
- (IBAction)modeButtonClick:(id)sender;

- (IBAction)showPrintPanel:(id)sender;

- (IBAction)showDataSets:(id)sender;
- (IBAction)closeDataSets:(id)sender;

- (IBAction)newSession:(id)sender;

@end
