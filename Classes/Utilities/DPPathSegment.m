//
//  DPPathSegment.m
//  ChronoViz
//
//  Created by Adam Fouse on 11/9/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPPathSegment.h"

@implementation DPPathSegment

@synthesize start,end,reversed;

- (id)init {
    self = [super init];
    if (self) {
        self.start = NSZeroPoint;
        self.end = NSZeroPoint;
        self.reversed = NO;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    DPPathSegment *copy = [[[self class] allocWithZone: zone] init];
    copy.start = self.start;
    copy.end = self.end;
    copy.reversed = self.reversed;
    return copy;
}

- (DPIntersectionResult)intersectsPathSegment:(DPPathSegment*)otherSegment
{
    DPIntersectionResult result;
    result.intersect = NO;
    result.intersectionPoint = NSZeroPoint;
    
    CGFloat denom = ((otherSegment.end.y - otherSegment.start.y)*(end.x - start.x)) -
    ((otherSegment.end.x - otherSegment.start.x)*(end.y - start.y));
    
    CGFloat nume_a = ((otherSegment.end.x - otherSegment.start.x)*(start.y - otherSegment.start.y)) -
    ((otherSegment.end.y - otherSegment.start.y)*(start.x - otherSegment.start.x));
    
    CGFloat nume_b = ((end.x - start.x)*(start.y - otherSegment.start.y)) -
    ((end.y - start.y)*(start.x - otherSegment.start.x));
    
    if(denom != 0.0f)
    {
        float ua = nume_a / denom;
        float ub = nume_b / denom;
        
        if(ua >= 0.0f && ua <= 1.0f && ub >= 0.0f && ub <= 1.0f)
        {
            // Get the intersection point.
            result.intersectionPoint.x = start.x + ua*(end.x - start.x);
            result.intersectionPoint.y = start.y + ua*(end.y - start.y);
            result.intersectedSegment = self;
            result.intersectingSegment = otherSegment;
            result.intersect = YES;
        } 
    }
    
    return result;
}

- (NSArray*)splitAtLine:(DPPathSegment*)line
{
    DPIntersectionResult intersectresult = [self intersectsPathSegment:line];
    if(intersectresult.intersect)
    {
        DPPathSegment *first = [[DPPathSegment alloc] init];
        DPPathSegment *second = [[DPPathSegment alloc] init];
        
        first.start = self.start;
        first.end = intersectresult.intersectionPoint;
        first.reversed = self.reversed;
        
        second.start = intersectresult.intersectionPoint;
        second.end = self.end;
        second.reversed = self.reversed;
        
        NSArray *result = [NSArray arrayWithObjects:first,second, nil];
        [first release];
        [second release];
        return result;
    }
    
    return nil;
}

- (CGFloat)length
{
    return sqrt(pow((self.end.y - self.start.y), 2) + pow((self.end.x - self.start.x),2));
}

@end
