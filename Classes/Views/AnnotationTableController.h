//
//  AnnotationTableController.h
//  Annotation
//
//  Created by Adam Fouse on 11/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationView.h"
#import "DPStateRecording.h"
@class AnnotationTableView;
@class AnnotationFilter;

@interface AnnotationTableController : NSWindowController <AnnotationView,DPStateRecording> {

	IBOutlet AnnotationTableView* tableView;
	IBOutlet NSSearchField* searchField;
	
	NSMutableArray* annotations;
	NSMutableArray* allAnnotations;
	
	AnnotationFilter* filter;
	
	BOOL inlineEdit;
	int rowSpacing;
}

- (NSArray*)annotationForIndexSet:(NSIndexSet*)theIndices;

- (IBAction)updateSearchTerm:(id)sender;

- (IBAction)editSelectedAnnotation:(id)sender;

- (IBAction)changeTableSpacing:(id)sender;

@end
