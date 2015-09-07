//
//  DPSpatialDataBase.m
//  ChronoViz
//
//  Created by Adam Fouse on 9/30/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPSpatialDataBase.h"
#import "NSImage-Extras.h"
#import "TimeCodedSpatialPoint.h"
#import <QuartzCore/CoreAnimation.h>

NSString * const SpatialDataBaseUpdatedNotification = @"SpatialDataBaseUpdatedNotification";

@implementation DPSpatialDataBase

@synthesize coordinateSpace,xReflect,yReflect;

- (id)init
{
    self = [super init];
    if (self) {
        backgroundLayer = nil;
        
        loaded = YES;
    }
    
    return self;
}

- (void)dealloc {
    [backgroundLayer removeFromSuperlayer];
    [backgroundLayer release];
    [super dealloc];
}

- (CALayer*)backgroundLayer
{
    if(!backgroundLayer)
    {
        backgroundLayer = [[CALayer layer] retain];
        
        CGColorRef background = CGColorCreateGenericGray(0.2, 1.0);
        backgroundLayer.backgroundColor = background;
        CGColorRelease(background);
    }
    return backgroundLayer;
}

- (CGPoint)viewPointForDataPoint:(CGPoint)dataPoint 
{
    return [self viewPointForDataX:dataPoint.x andY:dataPoint.y];
}

- (CGPoint)viewPointForSpatialDataPoint:(TimeCodedSpatialPoint*)dataPoint
{
    return [self viewPointForDataX:[dataPoint x] andY:[dataPoint y]];
}

- (CGPoint)viewPointForDataPoint:(CGPoint)dataPoint withOffsets:(CGPoint)offsets
{
    return [self viewPointForDataX:dataPoint.x andY:dataPoint.y withOffsets:offsets];
}

- (CGPoint)viewPointForSpatialDataPoint:(TimeCodedSpatialPoint*)dataPoint withOffsets:(CGPoint)offsets
{
    return [self viewPointForDataX:[dataPoint x] andY:[dataPoint y] withOffsets:offsets];
}

- (CGPoint)viewPointForDataX:(CGFloat)dataX andY:(CGFloat)dataY
{
    return [self viewPointForDataX:dataX andY:dataY withOffsets:CGPointZero];
}

- (CGPoint)viewPointForDataX:(CGFloat)dataX andY:(CGFloat)dataY withOffsets:(CGPoint)offsets
{
    //return CGPointMake((dataX - coordinateSpace.origin.x) * xDataToPixel, (dataY - coordinateSpace.origin.y) * yDataToPixel);
    
    if(self.yReflect)
    {
        return CGPointMake((dataX - coordinateSpace.origin.x) * xDataToPixel, (dataY - coordinateSpace.origin.y) * yDataToPixel);
    }
    else
    {
        return CGPointMake((dataX - coordinateSpace.origin.x) * xDataToPixel, displayBounds.size.height - ((dataY - coordinateSpace.origin.y) * yDataToPixel));
    }
    
}



- (CGPoint)dataPointForViewPoint:(CGPoint)viewPoint
{
    return [self dataPointForViewPoint:viewPoint withOffsets:CGPointZero];
}

- (CGPoint)dataPointForViewPoint:(CGPoint)viewPoint withOffsets:(CGPoint)offsets
{
    CGFloat dataX = (viewPoint.x / xDataToPixel) + coordinateSpace.origin.x;
    CGFloat dataY = (viewPoint.y / yDataToPixel) + coordinateSpace.origin.y;
    
    return CGPointMake(dataX, dataY);
}

- (BOOL)compatibleWithBase:(DPSpatialDataBase*)otherBase
{
    return YES;
    //return CGRectEqualToRect(self.coordinateSpace, otherBase.coordinateSpace);
}

- (void)load
{
    loaded = YES;
}

- (CGRect)displayBounds
{
    return displayBounds;
}

- (void)setDisplayBounds:(CGRect)theDisplayBounds
{
    displayBounds = theDisplayBounds;
    [self update];
}

- (void)update
{
	yDataToPixel = displayBounds.size.height/coordinateSpace.size.height;
	xDataToPixel = displayBounds.size.width/coordinateSpace.size.width;
	
    if(yDataToPixel < xDataToPixel)
    {
        xDataToPixel = yDataToPixel;
    }
    else
    {
        yDataToPixel = xDataToPixel;
    }
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeRect:NSRectFromCGRect(self.coordinateSpace) forKey:@"CoordinateSpace"];
    [coder encodeBool:self.xReflect forKey:@"XReflect"];
    [coder encodeBool:self.yReflect forKey:@"YReflect"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{        
        self.coordinateSpace = NSRectToCGRect([coder decodeRectForKey:@"CoordinateSpace"]);

        self.xReflect = [coder decodeBoolForKey:@"XReflect"];
        self.yReflect = [coder decodeBoolForKey:@"YReflect"];

        savedOffsets.x = [coder decodeDoubleForKey:@"XOffset"];
        savedOffsets.y = [coder decodeDoubleForKey:@"YOffset"];
		
        loaded = NO;
	}
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    DPSpatialDataBase *copy = [[[self class] allocWithZone: zone] init];
    copy.coordinateSpace = self.coordinateSpace;
    copy.xReflect = self.xReflect;
    copy.yReflect = self.yReflect;
    return copy;
}

- (CGPoint)savedOffsets
{
    return savedOffsets;
}

@end
