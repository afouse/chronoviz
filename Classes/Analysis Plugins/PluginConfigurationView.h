//
//  PluginConfigurationView.h
//  Annotation
//
//  Created by Adam Fouse on 9/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class PluginConfiguration;

@interface PluginConfigurationView : NSView {

	PluginConfiguration *configuration;
	
	NSButton *okayButton;
	NSButton *cancelButton;
	
}

- (id)initWithPluginConfiguration:(PluginConfiguration*)theConfiguration;

- (IBAction)changeDataSet:(id)sender;

- (IBAction)closeWindow:(id)sender;

- (IBAction)changeAnnotationSet:(id)sender;

- (void)setRunButtonsHidden:(BOOL)hideButtons;

@end
