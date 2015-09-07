//
//  AnotoViewController.h
//  DataPrism
//
//  Created by Adam Fouse on 2/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class EthnographerNotesView;
@class TimelineView;
@class AnnotationCategory;

@interface AnotoViewController : NSWindowController {

	IBOutlet EthnographerNotesView *anotoView;
	IBOutlet NSScrollView *notesScrollView;
	
	IBOutlet NSPanel *printPanel;
	IBOutlet NSButton *printButton;
	IBOutlet NSTextField *printLabel;
	IBOutlet NSPopUpButton *printerList;
	IBOutlet NSProgressIndicator *printProgressIndicator;
	
	IBOutlet NSPanel *dataSetsPanel;
	IBOutlet NSTableView *dataSetsTable;
	id colorEditDataSet;
	
    IBOutlet NSView *sessionControlView;
    IBOutlet NSTextField *sessionNameField;
    IBOutlet NSColorWell *sessionColorButton;
	NSMutableArray *notesDataSets;
	
	TimelineView *selectionTimeline;
	AnnotationCategory *selectionCategory;
	
	NSString *printQueue;
	NSTimer *printMonitor;
    NSButton *newSession;
}

- (EthnographerNotesView*)anotoView;

- (IBAction)changePageButtonClick:(id)sender;
- (IBAction)rotatePageButtonClick:(id)sender;
- (IBAction)zoomButtonClick:(id)sender;
- (IBAction)modeButtonClick:(id)sender;

- (IBAction)showPrintPanel:(id)sender;
- (IBAction)closePrintPanel:(id)sender;
- (IBAction)print:(id)sender;

- (IBAction)showDataSets:(id)sender;
- (IBAction)closeDataSets:(id)sender;

- (IBAction)newSession:(id)sender;
@end
