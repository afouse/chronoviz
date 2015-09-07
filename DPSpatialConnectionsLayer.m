//
//  DPSpatialConnectionsLayer.m
//  ChronoViz
//
//  Created by Adam Fouse on 9/6/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPSpatialConnectionsLayer.h"
#import "SpatialTimeSeriesData.h"
#import "TimeCodedSpatialPoint.h"
#import "DPSpatialDataView.h"
#import "NSColorCGColor.h"
#import "DPSpatialDataBase.h"

@interface DPSpatialConnection : NSObject {
    CALayer *layerFrom;
    CALayer *layerTo;
    
    NSColor *color;
}

@property(retain) CALayer* layerFrom;
@property(retain) CALayer* layerTo;
@property(retain) NSColor *color;

@end

@implementation DPSpatialConnection

@synthesize  layerFrom,layerTo,color;

- (void)dealloc {
    self.layerFrom = nil;
    self.layerTo = nil;
    self.color = nil;
    [super dealloc];
}

@end

@implementation DPSpatialConnectionsLayer

@synthesize spatialView, linesLayer, linesColor;

- (id)init
{
    self = [super init];
    if (self) {
        connections = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [connections release];
    [super dealloc];
}

- (BOOL)hasVisibleSegments
{
    for(DPSpatialConnection *connection in connections)
    {
        if(![connection.layerFrom isHidden] && ![connection.layerTo isHidden])
        {
            return YES;
        }
    }
    return NO;
}

- (void)addConnectionFrom:(CALayer*)fromData to:(CALayer*)toData
{
    DPSpatialConnection *connection = [[DPSpatialConnection alloc] init];
    connection.layerFrom = fromData;
    connection.layerTo = toData;
    [connections addObject:connection];
    [connection release];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    DPSpatialDataBase *spatialBase = spatialView.spatialBase;
    
    for(DPSpatialConnection *connection in connections)
    {
        CGContextBeginPath (ctx);
        if(![connection.layerFrom isHidden] && ![connection.layerTo isHidden])
        {
            CGPoint startPoint = [spatialBase viewPointForSpatialDataPoint:[connection.layerFrom valueForKey:@"currentPoint"]];
            CGPoint endPoint = [spatialBase viewPointForSpatialDataPoint:[connection.layerTo valueForKey:@"currentPoint"]];
            CGContextMoveToPoint(ctx,startPoint.x,startPoint.y );
            CGContextAddLineToPoint(ctx, endPoint.x, endPoint.y);
        }
        CGColorRef strokeColor = [linesColor createCGColor];
        CGContextSetLineWidth(ctx, 2.0);
        CGContextSetStrokeColorWithColor(ctx, strokeColor);
        CGContextStrokePath(ctx);
        CGColorRelease(strokeColor);
    }
}


@end
