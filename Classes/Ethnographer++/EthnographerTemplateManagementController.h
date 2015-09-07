//
//  EthnographerTemplateManagementController.h
//  ChronoViz
//
//  Created by Adam Fouse on 8/11/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
@class EthnographerPlugin;
@class EthnographerProject;
@class EthnographerTemplate;

@interface EthnographerTemplateManagementController : NSWindowController <NSSplitViewDelegate> {

	EthnographerPlugin *plugin;
	EthnographerProject *currentProject;
	EthnographerTemplate *selectedTemplate;
    NSString *selectedSessionFile;
    NSString *selectedControl;
	PDFPage *selectedTemplatePage;
    
    NSArray *splitViewDelegates;
	
    IBOutlet NSSplitView *templatesSplitView;
    IBOutlet NSSplitView *sessionsSplitView;
    IBOutlet NSSplitView *controlsSplitView;
    
	IBOutlet NSPopUpButton *projectButton;
	IBOutlet NSButton *newProjectButton;
	
    IBOutlet NSTabView *tabView;
    
	IBOutlet NSTableView *templateList;
	IBOutlet NSButton *newTemplateButton;
	
	IBOutlet PDFView *templatePreview;
	IBOutlet NSButton *nextPageButton;
	IBOutlet NSButton *previousPageButton;
	IBOutlet NSTextField *pageLabel;
	IBOutlet NSButton *deleteTemplateButton;
	IBOutlet NSButton *printTemplateButton;
    
    IBOutlet NSTableView *sessionsList;
    IBOutlet PDFView *sessionPreview;
	IBOutlet NSButton *nextSessionPageButton;
	IBOutlet NSButton *previousSessionPageButton;
	IBOutlet NSTextField *sessionPageLabel;
	IBOutlet NSButton *deleteSessionButton;
	IBOutlet NSButton *importSessionButton;
    IBOutlet NSProgressIndicator *previewLoadingProgress;
    
    IBOutlet NSTableView *controlsList;
    IBOutlet PDFView *controlsPreview;
    IBOutlet NSButton *controlsPrintButton;
    
}

@property(assign) EthnographerPlugin *plugin;
@property(assign) EthnographerProject *currentProject;
@property(retain) NSString* selectedSessionFile;

- (IBAction)selectTemplatesPane:(id)sender;
- (IBAction)selectSessionsPane:(id)sender;
- (IBAction)selectControlsPane:(id)sender;

- (IBAction)newProjectAction:(id)sender;
- (IBAction)changeProjectAction:(id)sender;
- (IBAction)newTemplateAction:(id)sender;
- (IBAction)deleteTemplateAction:(id)sender;
- (IBAction)printTemplateAction:(id)sender;
- (IBAction)nextPageAction:(id)sender;
- (IBAction)previousPageAction:(id)sender;
- (IBAction)loadSessionAction:(id)sender;
- (IBAction)printControlAction:(id)sender;
- (IBAction)rotateTemplateCCW:(id)sender;
- (IBAction)rotateTemplateCW:(id)sender;
- (IBAction)deleteSessionAction:(id)sender;

- (void)reloadPreview;
- (void)cancelPreview;

@end
