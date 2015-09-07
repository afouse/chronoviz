//
//  ActivityFramesConfigurationController.m
//  ChronoViz
//
//  Created by Adam Fouse on 10/26/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "ActivityFramesConfigurationController.h"
#import "DPActivityLog.h"

@implementation ActivityFramesConfigurationController

- (id)initForVisualizer:(ActivityFramesVisualizer*)vis
{
	if(![super initWithWindowNibName:@"ActivityFramesConfigurationWindow"])
		return nil;
	
	visualizer = vis;
	
	return self;
}

- (IBAction)changeVisMethodAction:(id)sender {
    NSInteger option = [[sender selectedCell] tag];
    
    [visualizer setVisualizationMethod:option];
}


- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
