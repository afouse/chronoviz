//
//  DPSpatialDataPlugin.m
//  ChronoViz
//
//  Created by Adam Fouse on 10/17/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPSpatialDataPlugin.h"
#import "AppController.h"
#import "DPViewManager.h"
#import "DPSpatialDataView.h"
#import "DPSpatialDataWindowController.h"
#import "SpatialTimeSeriesData.h"
#import "OrientedSpatialTimeSeriesData.h"

@implementation DPSpatialDataPlugin

- (id) initWithAppProxy:(DPAppProxy *)appProxy
{
	self = [super init];
	if (self != nil) {
		
        
        
        [appProxy registerDataClass:[SpatialTimeSeriesData class]
                                  withViewClass:[DPSpatialDataView class]
                                controllerClass:[DPSpatialDataWindowController class]
                                   viewMenuName:@"Spatial Data"];
        
        [appProxy registerDataClass:[OrientedSpatialTimeSeriesData class]
                               withViewClass:[DPSpatialDataView class]
                             controllerClass:[DPSpatialDataWindowController class]
                                viewMenuName:@"Trajectory Data"];
        
	}
	return self;
}

- (void) reset
{

}

@end
