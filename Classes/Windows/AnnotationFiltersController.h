//
//  AnnotationFiltersController.h
//  Annotation
//
//  Created by Adam Fouse on 12/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationView.h"

@interface AnnotationFiltersController : NSWindowController {
	
    IBOutlet NSBox *dividerLine;
    IBOutlet NSPopUpButton *filterTypeButton;
    
    IBOutlet NSView *categoriesView;
	IBOutlet NSOutlineView *filtersView;
	IBOutlet NSPopUpButton *booleanButton;
	
    IBOutlet NSView *searchView;
    IBOutlet NSSearchField *searchField;
   
    IBOutlet NSTextField *filtersTitle;
    NSView *currentView;
    
	id<AnnotationView> annotationView;
    
    NSWindow *attachedWindow;
    NSPoint currentAttachedPoint;
    
    NSView *windowView;
	
}

-(void)setAnnotationView:(id<AnnotationView>) theAnnotationView;
-(void)attachToAnnotationView:(NSView<AnnotationView>*)theAnnotationView;
-(id<AnnotationView>)currentAnnotationView;

- (IBAction)changeFilterType:(id)sender;

-(IBAction)changeBoolean:(id)sender;

-(IBAction)selectAll:(id)sender;
-(IBAction)selectNone:(id)sender;

- (IBAction)changeSearchTerm:(id)sender;
- (IBAction)closeWindowAction:(id)sender;

@end
