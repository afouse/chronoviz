//
//  PreferenceController.h
//  Annotation
//
//  Created by Adam Fouse on 12/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppController.h"
#import "TimelineView.h"

extern int const AFBlankSegmentViz;
extern int const AFGradientViz;
extern int const AFDotViz;
extern int const AFAreaViz;
extern int const AFKeyframeViz;
extern int const AFInitialKeyframeAreaViz;
extern int const AFCentralKeyframeViz;
extern int const AFEvenKeyframeViz;
extern int const AFEvenAreaViz;
extern int const AFDualViz;

extern int const AFSaveInteractionsNo;
extern int const AFSaveInteractionsYes;
extern int const AFSaveInteractionsUndefined;

@interface PreferenceController : NSWindowController {
	IBOutlet NSTextField *speed1;
	IBOutlet NSTextField *speed2;
	IBOutlet NSTextField *speed3;
	IBOutlet NSTextField *speed4;
	IBOutlet NSTextField *speed5;
	IBOutlet NSTextField *speed6;
	IBOutlet NSTextField *speed7;
	IBOutlet NSTextField *speed8;
	IBOutlet NSTextField *speed9;
	IBOutlet NSTextField *speed10;
	IBOutlet NSTextField *speed11;
	IBOutlet NSTextField *speed12;
	IBOutlet NSTextField *speed13;
	IBOutlet NSTextField *speed14;
	IBOutlet NSTextField *speed15;
	
	IBOutlet NSButton *automaticFileButton;
	
	IBOutlet NSButton *openVideosHalfSizeButton;
	
	IBOutlet NSButton *pauseWhileAnnotatingButton;
	IBOutlet NSButton *showPopUpAnnotationsButton;
	
	IBOutlet NSButton *saveInteractionsButton;
	IBOutlet NSButton *saveTimePositionButton;
	IBOutlet NSButton *saveAnnotationEditsButton;
	IBOutlet NSButton *saveVizConfigButton;
	IBOutlet NSButton *saveScreenCapsButton;
	IBOutlet NSTextField *screenCapsIntervalField;
	IBOutlet NSButton *uploadInteractionsButton;
	
	AppController *app;
}

-(void)setAppController:(AppController *)appController;

-(IBAction)toggleAutomaticFileCreation:(id)sender;

-(IBAction)toggleOpenVideosHalfSize:(id)sender;

-(IBAction)togglePauseForAnnotations:(id)sender;
-(IBAction)togglePopUpAnnotations:(id)sender;

-(IBAction)toggleSaveInteractions:(id)sender;
-(IBAction)toggleSaveTimePosition:(id)sender;
-(IBAction)toggleSaveAnnotationEdits:(id)sender;
-(IBAction)toggleSaveState:(id)sender;
-(IBAction)toggleSaveScreenCaptures:(id)sender;
-(IBAction)toggleUploadInteractions:(id)sender;
-(IBAction)uploadNow:(id)sender;

@end
