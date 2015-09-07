//
//  DPSpatialPathLayer.h
//  ChronoViz
//
//  Created by Adam Fouse on 9/2/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/CoreAnimation.h>
#import <QTKit/QTKit.h>
@class DPSpatialDataView;
@class SpatialTimeSeriesData;
@class TimeCodedDataPoint;
@class TimeCodedSpatialPoint;

@interface DPSpatialPathLayer : NSObject {
    DPSpatialDataView* spatialView;
    SpatialTimeSeriesData* pathData;
    NSArray* pathSubset;
    CALayer* pathLayer;
    CGFloat tailTime;
    CGFloat pointRadius;
    BOOL connected;
    BOOL entirePath;
    BOOL entirePathNeedsRedraw;
    
    CGMutablePathRef currentPath;
    
    NSColor *fillColor;
    NSColor *strokeColor;
    
    TimeCodedSpatialPoint *thecurrentPoint;
    NSInteger thecurrentIndex;
    QTTime currentTime;
    
}

@property(assign) DPSpatialDataView* spatialView;
@property(retain) SpatialTimeSeriesData* pathData;
@property(retain) NSArray* pathSubset;
@property(retain) CALayer* pathLayer;
@property(retain) NSColor* fillColor;
@property(retain) NSColor* strokeColor;
@property CGFloat tailTime;
@property CGFloat pointRadius;
@property BOOL connected;
@property BOOL entirePath;
@property BOOL entirePathNeedsRedraw;

- (void)updateForTime:(QTTime)time;

@end
