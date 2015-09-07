//
//  VisualizationController.h
//  Annotation
//
//  Created by Adam Fouse on 12/27/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppController.h"
#import "InteractionLog.h"
#import "VideoActivityView.h"


@interface VisualizationController : NSWindowController {
	AppController *app;
	InteractionLog *log;
	
	IBOutlet VideoActivityView *activityView;

}

-(void)setAppController:(AppController *)appController;
-(void)setInteractionLog:(InteractionLog *)interactionLog;

-(void)updateVisualization;

-(void)addSpeedChange:(float)speed atTime:(QTTime)time;

-(void)exportImageToFile:(NSString *)path;

@end
