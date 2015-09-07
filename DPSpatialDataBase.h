//
//  DPSpatialDataBase.h
//  ChronoViz
//
//  Created by Adam Fouse on 9/30/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPStateRecording.h"
@class TimeCodedSpatialPoint;

extern NSString * const SpatialDataBaseUpdatedNotification;

@interface DPSpatialDataBase : NSObject <NSCoding,NSCopying> {
    
    CALayer *backgroundLayer;
    
    CGRect displayBounds;
    CGRect coordinateSpace;
    CGFloat xDataToPixel;
    CGFloat yDataToPixel;
    
    BOOL xReflect;
    BOOL yReflect;
    
    CGPoint savedOffsets;
    
    BOOL loaded;
}

@property CGRect displayBounds;
@property CGRect coordinateSpace;
@property BOOL xReflect;
@property BOOL yReflect;

- (void)load;
- (void)update;

- (CALayer*)backgroundLayer;

- (CGPoint)viewPointForDataPoint:(CGPoint)dataPoint;
- (CGPoint)viewPointForSpatialDataPoint:(TimeCodedSpatialPoint*)dataPoint;
- (CGPoint)viewPointForDataX:(CGFloat)dataX andY:(CGFloat)dataY;

- (CGPoint)viewPointForDataPoint:(CGPoint)dataPoint withOffsets:(CGPoint)offsets;
- (CGPoint)viewPointForSpatialDataPoint:(TimeCodedSpatialPoint*)dataPoint withOffsets:(CGPoint)offsets;
- (CGPoint)viewPointForDataX:(CGFloat)dataX andY:(CGFloat)dataY withOffsets:(CGPoint)offsets;

- (CGPoint)dataPointForViewPoint:(CGPoint)viewPoint;
- (CGPoint)dataPointForViewPoint:(CGPoint)viewPoint withOffsets:(CGPoint)offsets;

- (BOOL)compatibleWithBase:(DPSpatialDataBase*)otherBase;

- (CGPoint)savedOffsets;

@end
