//
//  DPSpatialConnectionsLayer.h
//  ChronoViz
//
//  Created by Adam Fouse on 9/6/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/CoreAnimation.h>
#import <AVKit/AVKit.h>
@class DPSpatialDataView;
@class SpatialTimeSeriesData;
@class TimeCodedDataPoint;

@interface DPSpatialConnectionsLayer : NSObject {
    
    DPSpatialDataView* spatialView;
    NSMutableArray *connections;
    CALayer* linesLayer;
    
    NSColor *linesColor;
}

@property(assign) DPSpatialDataView* spatialView;
@property(retain) CALayer* linesLayer;
@property(retain) NSColor* linesColor;

- (void)addConnectionFrom:(CALayer*)fromData to:(CALayer*)toData;

- (BOOL)hasVisibleSegments;

@end
