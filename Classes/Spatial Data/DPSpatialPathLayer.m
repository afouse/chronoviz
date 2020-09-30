//
//  DPSpatialPathLayer.m
//  ChronoViz
//
//  Created by Adam Fouse on 9/2/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPSpatialPathLayer.h"
#import "NSColorCGColor.h"
#import "NSArrayAFBinarySearch.h"
#import "DPSpatialDataView.h"
#import "SpatialTimeSeriesData.h"
#import "TimeSeriesData.h"
#import "TimeCodedSpatialPoint.h"
#import "DPSpatialDataBase.h"

@implementation DPSpatialPathLayer

@synthesize spatialView,pathData,pathSubset,pathLayer,tailTime,pointRadius,connected,entirePath,entirePathNeedsRedraw;

- (id)init
{
    self = [super init];
    if (self) {
        self.pathData = nil;
        
        self.pathLayer = [CALayer layer];
        [self.pathLayer setDelegate:self];
        //pathLayer.lineWidth = 3.0;
        //pathLayer.fillRule = kCAFillRuleNonZero;
        //pathLayer.fillColor = nil;
        
        currentPath = NULL;
        
//        CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
//        [filter setDefaults];
//        [filter setValue:[NSNumber numberWithFloat:3.0] forKey:@"inputRadius"];
//        pathLayer.filters = [NSArray arrayWithObject:filter];
        
        self.tailTime = 0;
        self.pointRadius = 3;
        self.connected = YES;
        self.entirePath = NO;
        self.entirePathNeedsRedraw = YES;
    }
    
    return self;
}

- (void)dealloc {
    CGPathRelease(currentPath);
    self.pathData = nil;
    self.pathLayer = nil;
    self.fillColor = nil;
    self.strokeColor = nil;
    [super dealloc];
}

- (NSColor*)fillColor
{
    return fillColor;
}

- (void)setFillColor:(NSColor *)theFillColor
{
    [theFillColor retain];
    [fillColor release];
    fillColor = theFillColor;
    
//    CGColorRef fill = [fillColor createCGColor];
//    self.pathLayer.fillColor = fill;
//    CGColorRelease(fill);
}

- (NSColor*)strokeColor
{
    return strokeColor;
}

- (void)setStrokeColor:(NSColor *)theStrokeColor
{
    [theStrokeColor retain];
    [strokeColor release];
    strokeColor = theStrokeColor;
    
//    CGColorRef stroke = [strokeColor createCGColor];
//    self.pathLayer.strokeColor = stroke;
//    CGColorRelease(stroke);
}

- (void)updateForTime:(CMTime)time;
{
//    CGFloat minX = spatialView.minX;
//    CGFloat minY = spatialView.minY;
//    CGFloat xDataToPixel = spatialView.xDataToPixel;
//    CGFloat yDataToPixel = spatialView.yDataToPixel;
    
    if((entirePath && !entirePathNeedsRedraw)
       || ([pathSubset count] == 0))
    {
        return;
    }
    
    if(currentPath != NULL)
    {
        CGPathRelease(currentPath);
    }
    
    currentPath = CGPathCreateMutable();
    
    NSInteger closestIndex = 0;
    
    if(entirePath || (tailTime < 0) || ([pathSubset count] == 1))
    {
        closestIndex = 0;
    }
    else
    {
    
        TimeCodedDataPoint *startTimePoint = [[TimeCodedDataPoint alloc] init];
        startTimePoint.time = CMTimeSubtract(time, CMTimeMake(time.timescale * tailTime, time.timescale));
        
        closestIndex = [pathSubset binarySearch:startTimePoint
                                            usingFunction:afTimeCodedPointSort
                                                  context:NULL];	
        
        if(closestIndex < 0)
        {
            closestIndex = -(closestIndex + 2);
        }
        
        if(closestIndex >= ([pathSubset count] - 1))
        {
            closestIndex = [pathSubset count] - 2;
        }
        
        if(closestIndex < 0)
        {
            closestIndex = 0;
        }
        
    }
    
    TimeCodedSpatialPoint* currentPoint = [pathSubset objectAtIndex:closestIndex];
    
    thecurrentPoint = currentPoint;
    thecurrentIndex = closestIndex;
    currentTime = time;
    

    
    if(entirePath)
    {
        entirePathNeedsRedraw = NO;
    }
    
     
    //self.pathLayer.path = currentPath;
    [self.pathLayer setNeedsDisplay];
    
    //CGPathRelease(currentPath);
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    BOOL outline = NO;
    
    if([pathSubset count] > 1)
    {
        
        TimeCodedSpatialPoint* currentPoint = thecurrentPoint;

        NSInteger closestIndex = thecurrentIndex;
            
        TimeCodedSpatialPoint* previousPoint = currentPoint;
        currentPoint = [pathSubset objectAtIndex:++closestIndex];
        
        CGColorRef cgstrokeColor = [strokeColor createCGColor];
        if(!outline)
        {
            CGContextSetStrokeColorWithColor(ctx, cgstrokeColor);
            CGContextSetLineWidth(ctx, 3.0);
        }
        else
        {
            CGContextSetStrokeColorWithColor(ctx, CGColorGetConstantColor(kCGColorWhite));
            CGContextSetLineWidth(ctx, 7.0);
        }
        CGContextSetLineJoin(ctx, kCGLineJoinRound);
        
        CGColorRef cgfillColor = [[strokeColor colorWithAlphaComponent:0.3] createCGColor];
        //CGColorRef cgfillColor = [[NSColor blackColor] createCGColor];
        CGContextSetFillColorWithColor(ctx, cgfillColor);
        
        CGPoint previousViewPoint;
        CGPoint currentViewPoint;
        
//        BOOL outline = YES;
        
        DPSpatialDataBase *spatialBase = spatialView.spatialBase;
        
        while(//(closestIndex < ([pathSubset count] - 2)) &&
              (entirePath || (CMTIME_COMPARE_INLINE(currentTime, >=, currentPoint.time))))
        {
            if(connected)
            {    
                previousViewPoint = [spatialBase viewPointForSpatialDataPoint:previousPoint withOffsets:CGPointMake(pathData.xOffset,pathData.yOffset)];
                currentViewPoint = [spatialBase viewPointForSpatialDataPoint:currentPoint withOffsets:CGPointMake(pathData.xOffset,pathData.yOffset)];
                
                CGContextMoveToPoint(ctx, previousViewPoint.x, previousViewPoint.y);
                CGContextAddLineToPoint(ctx, currentViewPoint.x, currentViewPoint.y);
                
                //CGContextMoveToPoint(ctx, ([previousPoint x] - minX) * xDataToPixel, ([previousPoint y] - minY) * yDataToPixel);
                //CGContextAddLineToPoint(ctx, ([currentPoint x] - minX) * xDataToPixel, ([currentPoint y] - minY) * yDataToPixel);
                CGContextStrokePath(ctx);
                
                previousPoint = currentPoint;

            }
            else
            {
                currentViewPoint = [spatialBase viewPointForSpatialDataPoint:currentPoint withOffsets:CGPointMake(pathData.xOffset,pathData.yOffset)];
//            CGFloat x =  ([currentPoint x] - minX) * xDataToPixel;
//            CGFloat y = ([currentPoint y] - minY) * yDataToPixel;
                CGRect dot = CGRectMake(currentViewPoint.x - pointRadius, currentViewPoint.y - pointRadius, 2*pointRadius, 2*pointRadius);
               // CGContextAddEllipseInRect(ctx, dot);
                CGContextFillEllipseInRect(ctx, dot);
            }

            if(closestIndex < ([pathSubset count] - 1))
            {
                currentPoint = [pathSubset objectAtIndex:++closestIndex];
            }
            else
            {
                break;
            }

        }
        
        CGColorRelease(cgfillColor);
        CGColorRelease(cgstrokeColor);
    }
    
}

@end
