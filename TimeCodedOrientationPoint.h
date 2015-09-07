//
//  TimeCodedOrientationPoint.h
//  ChronoViz
//
//  Created by Adam Fouse on 11/8/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "TimeCodedSpatialPoint.h"

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

@interface TimeCodedOrientationPoint : TimeCodedSpatialPoint {
    
    CGFloat orientation;
    BOOL reversed;
}

// Orientation in degrees.
@property CGFloat orientation;
@property BOOL reversed;

-(CGFloat)radians;

@end
