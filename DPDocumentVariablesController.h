//
//  DPDocumentVariablesController.h
//  ChronoViz
//
//  Created by Adam Fouse on 7/29/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class AnnotationDocument;

@interface DPDocumentVariablesController : NSWindowController {

	IBOutlet NSButton *addVariableButton;
	IBOutlet NSButton *removeVariableButton;
	
	IBOutlet NSTableView *variablesTableView;
	
	NSMutableDictionary *variables;
	
	AnnotationDocument *annotationDocument;
}

@property(assign) AnnotationDocument* annotationDocument;

- (id)initForDocument:(AnnotationDocument*)theDocument;

-(IBAction)addVariable:(id)sender;
-(IBAction)removeVariable:(id)sender;

@end
