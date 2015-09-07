//
//  ActivityFramesVisualizer.h
//  ChronoViz
//
//  Created by Adam Fouse on 6/14/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FilmstripVisualizer.h"
@class DPActivityLog;

@interface ActivityFramesVisualizer : FilmstripVisualizer {

	DPActivityLog *activityLog;
	
	CALayer *activityLayer;
	CALayer *activityLayerMask;
	CALayer *framesLayer;
	
	CGImageRef activityMaskImage;
	
	NSMutableDictionary *bins;
	
    NSInteger visMethod;
    
    id configurationController;
}

@property(retain) DPActivityLog* activityLog;

- (void)updateActivityLayer;
- (void)setVisualizationMethod:(NSInteger)method;

@end
