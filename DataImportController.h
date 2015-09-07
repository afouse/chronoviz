//
//  DataImportController.h
//  Annotation
//
//  Created by Adam Fouse on 8/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DataSource.h"

@interface DataImportController: NSWindowController<DataSourceDelegate>  {

	IBOutlet NSTextField *dataSourceNameField;
	IBOutlet NSTextField *dataSourceTypeField;
	
	IBOutlet NSTextField* timeOffsetField;
	IBOutlet NSPopUpButton* timeColumnButton;
	IBOutlet NSMatrix* timeCodingButtons;
	IBOutlet NSView* timeCodingView;
	
	IBOutlet NSTextField* labelField;
	
	IBOutlet NSTabView* tabView;
	IBOutlet NSTableView* dataView;
	IBOutlet NSScrollView* scrollView;
	
    IBOutlet NSButton *importButton;
    IBOutlet NSButton *selectNoneButton;
    IBOutlet NSButton *selectAllButton;
	IBOutlet NSTableView* variablesTable;
	IBOutlet NSScrollView* variablesView;
	NSArray *possibleDataTypes;
	NSMutableArray *headings;
	NSMutableDictionary *labels;
	NSMutableDictionary *types;
	NSMutableArray *variablesToImport;
	NSMutableArray *variablesToDisplay;
    NSMutableArray *variablesToDelete;
    NSMutableArray *existingVariables;
	
	IBOutlet NSWindow* loadingWindow;
	IBOutlet NSProgressIndicator* loadingBar;
	IBOutlet NSTextField* loadingLabel;
	BOOL cancelLoad;
	
	DataSource *dataSource;
	
	NSTextFieldCell *lockedTypeCell;
	
	NSArray *data;
}

- (void)setDataSource:(DataSource*)theDataSource;
- (IBAction)changeTimeCoding:(id)sender;
- (IBAction)selectTimeColumn:(id)sender;

- (IBAction)selectAllDataColumns:(id)sender;
- (IBAction)selectNoDataColumns:(id)sender;

- (IBAction)import:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)cancelLoad:(id)sender;

- (IBAction)saveDefaults:(id)sender;

- (void)importVariables:(NSArray*)variables asTypes:(NSArray*)variableTypes withLabels:(NSDictionary*)variableLabels;

-(void)dataSourceLoadStatus:(CGFloat)percentage;
-(BOOL)dataSourceCancelLoad;
-(void)dataSourceLoadFinished;

@end
