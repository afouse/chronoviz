//
//  PluginScriptController.h
//  Annotation
//
//  Created by Adam Fouse on 11/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class PluginConfigurationView;
@class PluginScript;

@interface PluginScriptController : NSWindowController {
	
	IBOutlet NSPopUpButton* scriptsButton;
	IBOutlet NSButton* newScriptButton;
	IBOutlet NSButton* deleteScriptButton;

	IBOutlet NSTableView* pluginConfigurationsView;
	IBOutlet NSButton* addConfigurationButton;
	IBOutlet NSButton* removeConfigurationButton;
	
	IBOutlet PluginConfigurationView* configurationView;
	
	PluginScript* currentScript;
	
	NSTextField* nameInputField;
	NSPopUpButton* pluginSelectionButton;
	
}

-(IBAction)newScript:(id)sender;
-(IBAction)selectScript:(id)sender;
-(IBAction)deleteScript:(id)sender;
-(IBAction)saveScript:(id)sender;

-(IBAction)addConfiguration:(id)sender;
-(IBAction)removeConfiguration:(id)sender;

-(IBAction)runScript:(id)sender;

-(NSRect)newFrameForConfigurationView:(PluginConfigurationView *)view;
-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;


@end
