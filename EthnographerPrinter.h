//
//  EthnographerPrinter.h
//  ChronoViz
//
//  Created by Adam Fouse on 8/15/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class EthnographerPlugin;
@class EthnographerProject;
@class EthnographerTemplate;
@class EthnographerDataSource;

extern NSString * const DPEthnographerPrintLivescribe;
extern NSString * const DPEthnographerPrintAnotoWithoutControls;
extern NSString * const DPEthnographerPrintAnotoWithControls;

extern NSString * const DPEthnographerPrintPageSizeLetter;
extern NSString * const DPEthnographerPrintPageSizeA4;

extern NSString * const DPEthnographerPrintDotRadius;
extern NSString * const DPEthnographerPrintPageSize;

extern NSString * const DPEthnographerLastPrinterKey;
extern NSString * const DPEthnographerLastPrintTypeKey;

extern NSString * const AFEthnographerDoNotPrint;

@interface EthnographerPrinter : NSObject {

	EthnographerPlugin *plugin;
	
	NSPanel *printPanel;
	NSButton *printButton;
	NSTextField *printLabel;
	NSTextField *printTypeLabel;
	NSPopUpButton *printerList;
	NSPopUpButton *printTypeList;
	NSProgressIndicator *printProgressIndicator;
	NSButton *printOptionsButton;
	
	NSView *advancedOptions;
	NSSlider *dotRadiusSlider;
	NSPopUpButton *paperTypeList;
    NSTextField *copiesField;
    NSNumberFormatter *copiesNumberFormatter;
	
	CGFloat dotRadius;
	NSString *paperFormat;
	NSString *printType;

	NSString *printQueue;
	NSTimer *printMonitor;
	NSString *currentPrintFile;
	NSString *currentPrintError;
	
	NSString *printAnotoClasspath;
	NSString *printAnotoClass;
	NSString *printLivescribeClass;
	NSString *saveTemplateClass;
	NSString *deleteTemplateClass;
    NSString *deleteNotesClass;
    NSString *generatePdfClass;
    
	NSDictionary *currentPrintJob;
	
    NSMutableArray *controls;
    
    NSTask *dataTransferTask;
    NSWindow *dataTransferStartupWindow;
}

@property(nonatomic,retain) IBOutlet NSPanel *printPanel;
@property(nonatomic,retain) IBOutlet NSButton *printButton;
@property(nonatomic,retain) IBOutlet NSTextField *printLabel;
@property(nonatomic,retain) IBOutlet NSTextField *printTypeLabel;
@property(nonatomic,retain) IBOutlet NSPopUpButton *printerList;
@property(nonatomic,retain) IBOutlet NSPopUpButton *printTypeList;
@property(nonatomic,retain) IBOutlet NSProgressIndicator *printProgressIndicator;
@property(nonatomic,retain) IBOutlet NSButton *printOptionsButton;
@property(nonatomic,retain) IBOutlet NSView *advancedOptions;
@property(nonatomic,retain) IBOutlet NSSlider *dotRadiusSlider;
@property(nonatomic,retain) IBOutlet NSPopUpButton *paperTypeList;
@property (assign) IBOutlet NSTextField *copiesField;
@property (assign) IBOutlet NSNumberFormatter *copiesNumberFormatter;

@property(copy) NSString* currentPrintFile;
@property(copy) NSString* currentPrintError;
@property(retain) NSString* paperFormat;
@property(retain) NSString* printType;
@property CGFloat dotRadius;

- (id) initWithPlugin:(EthnographerPlugin*)thePlugin;

- (void)printTemplate:(EthnographerTemplate*)theTemplate fromWindow:(NSWindow*)window;
- (void)printLivescribeTemplate:(EthnographerTemplate*)theTemplate fromWindow:(NSWindow*)window;
- (void)printAnoto:(EthnographerDataSource*)notesSource fromWindow:(NSWindow*)window;

- (void)printControl:(NSString*)control fromWindow:(NSWindow*)window;

- (void)saveTemplate:(NSString*)templateName withBackground:(NSString*)backgroundFile toProject:(EthnographerProject*)project;
- (void)deleteTemplate:(NSString*)templateName fromProject:(EthnographerProject*)project;
- (void)deleteNoteSession:(NSString*)sessionPath fromProject:(EthnographerProject*)project;

- (void)updateSessionPdf:(NSString*)sessionPath inProject:(EthnographerProject*)theProject;

- (void)updatePrintStatus:(NSString*)message percent:(CGFloat)percent;

- (IBAction)closePrintPanel:(id)sender;
- (IBAction)confirmPrint:(id)sender;
- (IBAction)expandPrintOptions:(id)sender;

- (IBAction)showDataTransferWindow:(id)sender;
- (IBAction)closeDataTransferWindow:(id)sender;

@end
