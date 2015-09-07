//
//  SpatialTimeSeriesData.h
//  ChronoViz
//
//  Created by Adam Fouse on 6/16/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TimeSeriesData.h"
@class DPSpatialDataBase;

@interface SpatialTimeSeriesData : TimeSeriesData {

	CGFloat minX;
	CGFloat minY;
	CGFloat maxX;
	CGFloat maxY;
    CGFloat xOffset;
    CGFloat yOffset;
    
    DPSpatialDataBase *spatialBase;
	
}


@property(retain) DPSpatialDataBase *spatialBase;
@property(readonly) CGFloat minX;
@property(readonly) CGFloat minY;
@property(readonly) CGFloat maxX;
@property(readonly) CGFloat maxY;
@property CGFloat xOffset;
@property CGFloat yOffset;

@end
