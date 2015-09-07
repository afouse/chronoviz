//
//  ColorMappedTimeSeriesConfigurationController.h
//  ChronoViz
//
//  Created by Adam Fouse on 8/18/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AFGradientView.h"
#import "ColorMappedTimeSeriesVisualizer.h"

@interface ColorMappedTimeSeriesConfigurationController : NSWindowController {

	IBOutlet AFGradientView *gradientView;
	
	ColorMappedTimeSeriesVisualizer *visualizer;
	
	BOOL uniform;
	
}

@property BOOL uniform;

- (id)initForVisualizer:(ColorMappedTimeSeriesVisualizer*)vis;

@end
