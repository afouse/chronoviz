//
//  VideoPropertiesController.h
//  Annotation
//
//  Created by Adam Fouse on 6/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class VideoProperties;
@class AnnotationCategory;
@class AnnotationDocument;

@interface VideoPropertiesController : NSWindowController {
	
	IBOutlet NSTextField *videoFileField;
	IBOutlet NSTextField *titleField;
	IBOutlet NSTextField *descriptionField;
	IBOutlet NSDatePicker *startTimePicker;
//	IBOutlet NSTableView *tableView;
//	IBOutlet NSButton *removeCategoryButton;

    IBOutlet NSButton *alignmentButton;
	VideoProperties *videoProperties;
	
	AnnotationDocument *annotationDoc;
	
//	AnnotationCategory *editingCategory;
	
}

@property(assign) AnnotationDocument* annotationDoc;
@property(assign) VideoProperties* videoProperties;

-(void)setVideoProperties:(VideoProperties *)properties;

-(IBAction)changeTitle:(id)sender;
-(IBAction)changeDescription:(id)sender;
-(IBAction)changeStartTime:(id)sender;
//-(IBAction)addCategory:(id)sender;
//-(IBAction)removeCategory:(id)sender;

-(IBAction)autoAlign:(id)sender;

@end
