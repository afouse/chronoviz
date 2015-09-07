//
//  DPPath.h
//  ChronoViz
//
//  Created by Adam Fouse on 11/8/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPPathSegment.h"

@interface DPPath : NSObject {
    
    NSMutableArray *segments;
    NSPoint startPoint;
    BOOL empty;
    
    NSMutableArray *lastAddedSegments;
    
    BOOL onlyTrimLast;
}

@property BOOL onlyTrimLast;

-(void)addPoint:(NSPoint)point;
-(void)addSegment:(DPPathSegment*)segment;
-(void)addSegment:(DPPathSegment *)segment trim:(BOOL)trim;
-(void)addPath:(DPPath*)otherPath trim:(BOOL)trim;
-(void)addPath:(DPPath*)otherPath trim:(BOOL)trim onlyMostRecent:(BOOL)last;

-(NSArray*)splitSegment:(DPPathSegment *)segment atLine:(DPPathSegment *)line;

-(NSArray*)segments;

-(DPIntersectionResult)intersection:(DPPath*)otherPath;

@end
