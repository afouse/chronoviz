//
//  ColorMappedTimeSeriesConfigurationController.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/18/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "ColorMappedTimeSeriesConfigurationController.h"
#import "AFGradientView.h"

@implementation ColorMappedTimeSeriesConfigurationController

@synthesize uniform;

- (id)initForVisualizer:(ColorMappedTimeSeriesVisualizer*)vis
{
	if(![super initWithWindowNibName:@"ColorMappedTimeSeriesConfigurationWindow"])
		return nil;
	
	visualizer = vis;
	
	return self;
}

- (void)windowDidLoad
{
	[gradientView setContinuous:NO];
	[gradientView setGradient:[[visualizer colorMaps] objectForKey:@"*"]];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateGradient:)
												 name:AFGradientUpdatedNotification
											   object:gradientView];
}


- (void)updateGradient:(NSNotification*)theNotification
{
	if(uniform)
	{
		[visualizer setUniformColorMap:[gradientView gradient]];	
	}
}

@end
