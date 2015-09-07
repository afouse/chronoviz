//
//  VisualizationController.m
//  Annotation
//
//  Created by Adam Fouse on 12/27/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "VisualizationController.h"


@implementation VisualizationController

- (id)init
{
	if(![super initWithWindowNibName:@"Visualization"])
		return nil;
	
	return self;
}

- (void)windowDidLoad
{
	if(log)
		[activityView setInteractionLog:log];
	if(app)
		[activityView setMovie:[app movie]];
}

- (IBAction)showWindow:(id)sender
{
	[activityView updatePath];
	[super showWindow:sender];
}

- (void)setAppController:(AppController *)appController
{
	app = appController;
}

- (void)exportImageToFile:(NSString *)path 
{
	[activityView exportImageToFile:path];
}

- (void)setInteractionLog:(InteractionLog *)interactionLog
{
	log = interactionLog;
	[activityView setInteractionLog:interactionLog];
}

- (void)addSpeedChange:(float)speed atTime:(QTTime)time
{
	[activityView addSpeedChange:speed atTime:time];
}

- (void)updateVisualization
{
	[activityView updatePath];
}

@end
