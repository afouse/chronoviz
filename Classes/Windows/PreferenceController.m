//
//  PreferenceController.m
//  Annotation
//
//  Created by Adam Fouse on 12/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PreferenceController.h"

#import "SegmentVisualizer.h"
#import "SegmentDualVisualizer.h"

int const AFBlankSegmentViz = 0;
int const AFGradientViz = 1;
int const AFDotViz = 2;
int const AFAreaViz = 3;
int const AFKeyframeViz = 5;
int const AFInitialKeyframeAreaViz = 6;
int const AFCentralKeyframeViz = 7;
int const AFEvenAreaViz = 9;
int const AFEvenKeyframeViz = 10;
int const AFDualViz = 12;


@implementation PreferenceController

- (id)init
{
	if(![super initWithWindowNibName:@"Preferences"])
		return nil;
	
	return self;
}

- (void)setAppController:(AppController *)appController
{
	app = appController;
}

- (void)windowDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//[showMouseButton setState:[defaults integerForKey:AFShowMouseKey]];
	//[showKeyframesButton setState:[defaults integerForKey:AFShowKeyframesKey]];
	//[clickToMovePlayhead setState:[defaults integerForKey:AFClickToMovePlayheadKey]];
	
	
	[pauseWhileAnnotatingButton setState:[app pauseWhileAnnotating]];
	
	[automaticFileButton setState:[defaults boolForKey:AFAutomaticAnnotationFileKey]];
	[openVideosHalfSizeButton setState:[app openVideosHalfSize]];
	
	NSString* stepKey = AFStepValueKey;
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:stepKey
											   options:0
											   context:NULL];
	
}


-(IBAction)toggleAutomaticFileCreation:(id)sender
{
	BOOL state = [automaticFileButton state];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:state forKey:AFAutomaticAnnotationFileKey];
}

-(IBAction)toggleOpenVideosHalfSize:(id)sender
{
	BOOL state = [openVideosHalfSizeButton state];
	
	[app setOpenVideosHalfSize:state];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:state forKey:AFOpenVideosHalfSizeKey];
}


#pragma mark Visualization

-(IBAction)togglePauseForAnnotations:(id)sender
{
	BOOL state = [pauseWhileAnnotatingButton state];
	[app setPauseWhileAnnotating:state];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:state forKey:AFPauseWhileAnnotatingKey];	
}

-(IBAction)togglePopUpAnnotations:(id)sender
{
	BOOL state = [showPopUpAnnotationsButton state];
	[app setPopUpAnnotations:state];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:state forKey:AFShowPopUpAnnotationsKey];	
}



#pragma mark Change Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if([keyPath isEqualToString:AFStepValueKey])
	{
		float stepsize = [[NSUserDefaults standardUserDefaults] floatForKey:AFStepValueKey];
		[app setStepSize:stepsize];
	}
	else
	{
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
	}
}


@end
