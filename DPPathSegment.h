//
//  DPPathSegment.h
//  ChronoViz
//
//  Created by Adam Fouse on 11/9/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DPPathSegment;

typedef struct _DPIntersectionResult {
    BOOL intersect;
    NSPoint intersectionPoint;
    DPPathSegment *intersectedSegment;
    DPPathSegment *intersectingSegment;
} DPIntersectionResult;

@interface DPPathSegment : NSObject <NSCopying> {
    NSPoint start;
    NSPoint end;
    BOOL reversed;
}

@property NSPoint start;
@property NSPoint end;
@property BOOL reversed;

- (DPIntersectionResult)intersectsPathSegment:(DPPathSegment*)otherSegment;

- (NSArray*)splitAtLine:(DPPathSegment*)line;

- (CGFloat)length;

@end
