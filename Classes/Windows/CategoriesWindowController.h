//
//  CategoriesWindowController.h
//  Annotation
//
//  Created by Adam Fouse on 1/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class AnnotationCategory;

@interface CategoriesWindowController : NSWindowController {

	IBOutlet NSTableView *tableView;
	IBOutlet NSButton *removeCategoryButton;
	IBOutlet NSButton *addValueButton;
	
	IBOutlet NSOutlineView *outlineView;
	
	AnnotationCategory *editingCategory;
	
	NSColorPanel* colorPanel;
	
	NSArray *draggedNodes;
	
}

-(IBAction)addCategory:(id)sender;
-(IBAction)addValue:(id)sender;
-(IBAction)removeCategory:(id)sender;
-(IBAction)exportCategories:(id)sender;
-(IBAction)importCategories:(id)sender;

@end
