//
//  LinkedFilesController.h
//  ChronoViz
//
//  Created by Adam Fouse on 7/11/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class AnnotationDocument;

@interface LinkedFilesController : NSWindowController <NSOpenSavePanelDelegate> {
	
	IBOutlet NSButton *addDataButton;
	IBOutlet NSButton *removeDataButton;
	IBOutlet NSButton *editPropertiesButton;
	IBOutlet NSButton *linkDataButton;
	
	IBOutlet NSOutlineView *linkedFilesView;
	
	AnnotationDocument *annotationDocument;
	
	NSMutableArray *filesArray;
	
	NSMutableArray *propertiesControllers;
		
	id mainVideoSource;
    
    NSPopUpButton *openDataTypeButton;
    NSTextField *openDataTypeLabel;
}

@property(assign) AnnotationDocument* annotationDocument;

+(void)registerDataSourceClass:(Class)dataSourceClass;

-(IBAction)addData:(id)sender;
-(IBAction)removeData:(id)sender;
-(IBAction)editProperties:(id)sender;
-(IBAction)linkDataFiles:(id)sender;
-(IBAction)showFileInFinder:(id)sender;

-(BOOL)openDataFile:(NSString*)filename;
-(BOOL)openDataFile:(NSString*)file asType:(Class)dataSourceClass;

-(void)reloadData;

@end
