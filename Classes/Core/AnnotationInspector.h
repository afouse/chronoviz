//
//  AnnotationInspector.h
//  Annotation
//
//  Created by Adam Fouse on 6/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
@class Annotation;
@class AppController;
@class AnnotationCategory;

@interface AnnotationInspector : NSObject {

	IBOutlet NSWindow *inspector;

	IBOutlet NSTextField *startTimeLabel;
	IBOutlet NSTextField *endTimeLabel;
	IBOutlet NSTextField *startTimeField;
	IBOutlet NSTextField *endTimeField;
	
	IBOutlet NSStepper *startTimeStepper;
	IBOutlet NSButton *startTimeButton;
	IBOutlet NSButton *endTimeButton;
	IBOutlet NSPopUpButton *typeButton;
	IBOutlet NSTextField *titleField;	
	IBOutlet NSTextField *annotationField;	
	IBOutlet NSTokenField *keywordsField;
	IBOutlet NSTextField *colorLabel;
	IBOutlet NSPopUpButton *colorButton;
	
	IBOutlet NSTextField *typeButtonLabel;
	IBOutlet NSTextField *titleFieldLabel;
	IBOutlet NSTextField *annotationFieldLabel;
	IBOutlet NSTextField *keywordsFieldLabel;
	
	IBOutlet NSScrollView *categoriesScrollView;
	IBOutlet NSTableView *categoriesTable;
	IBOutlet NSTextField *categoriesLabel;
	IBOutlet NSButton *addCategoryButton;
	IBOutlet NSButton *removeCategoryButton;
	
	IBOutlet NSButton *useAsCategoryButton;
	IBOutlet NSColorWell *colorWell;
	
	IBOutlet NSWindow *categorySheet;
	IBOutlet NSOutlineView *categoryOutlineView;
	
	IBOutlet NSButton *saveAnnotationButton;
	IBOutlet NSButton *deleteAnnotationButton;
	
	NSArray *colors;
	AnnotationCategory* editingCategory;
	
	NSMutableArray *annotationsInCategory;
	
	Annotation *annotation;
	
	BOOL suppressClose;
	
}

@property(assign) Annotation *annotation;

- (IBAction)changeType:(id)sender;
- (IBAction)setStartTime:(id)sender;
- (IBAction)setEndTime:(id)sender;
- (IBAction)setColor:(id)sender;
- (IBAction)setColorViaWell:(id)sender;
- (IBAction)saveAndContinue:(id)sender;

//- (IBAction)toggleUseAsCategory:(id)sender;

- (IBAction)addCategory:(id)sender;
- (IBAction)removeCategory:(id)sender;
- (IBAction)finishCategorySelection:(id)sender;
- (IBAction)cancelCategorySelection:(id)sender;

- (void)selectAnnotationText;
- (void)saveChanges;

-(NSWindow*)window;
-(void)configureWindow;
-(void)buildCategoryList;

@end
