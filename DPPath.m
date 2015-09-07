//
//  DPPath.m
//  ChronoViz
//
//  Created by Adam Fouse on 11/8/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPPath.h"
#import "DPPathSegment.h"

@implementation DPPath

@synthesize onlyTrimLast;

- (id)init {
    self = [super init];
    if (self) {
        segments = [[NSMutableArray alloc] init];
        lastAddedSegments = [[NSMutableArray alloc] init];
        empty = YES;
    }
    return self;
}

- (void)dealloc {
    [segments release];
    [lastAddedSegments release];
    [super dealloc];
}

- (NSString*)description {
    NSMutableString *string = [NSMutableString stringWithString:@"Path Segments: \n"];
    
    for(DPPathSegment *segment in segments)
    {
        [string appendFormat:@"(%f,%f) to (%f,%f)\n",segment.start.x,segment.start.y,segment.end.x,segment.end.y];
    }
    return string;
}

-(void)addPoint:(NSPoint)point
{
    NSPoint start;
    if([segments count] == 0)
    {
        if(empty)
        {
            startPoint = point;
            empty = NO;
            return;
        }
        else
        {
            start = startPoint;
        }
    }
    else
    {
        start = [(DPPathSegment*)[segments lastObject] end];
    }
    empty = NO;
    
    DPPathSegment *segment = [[DPPathSegment alloc] init];
    segment.start = start;
    segment.end = point;
    [segments addObject:segment];
    [segment release];
    
    [lastAddedSegments removeAllObjects];
    [lastAddedSegments addObject:segment];
}

-(void)addSegment:(DPPathSegment *)segment
{
    [self addSegment:segment trim:NO];
}

-(void)addSegment:(DPPathSegment *)segment trim:(BOOL)trim
{
    if([segments count] == 0)
    {
        DPPathSegment *copy = [segment copy];
        [segments addObject:copy];
        [copy release];
        empty = NO;
        
        [lastAddedSegments removeAllObjects];
        [lastAddedSegments addObject:copy];
        
    }
    else
    {
        DPPath *tempPath = [[DPPath alloc] init];
        [tempPath addSegment:segment];
        [self addPath:tempPath trim:trim];
        [tempPath release];
    }

}

-(void)addPath:(DPPath*)otherPath trim:(BOOL)trim
{
    [self addPath:otherPath trim:trim onlyMostRecent:self.onlyTrimLast];
}

-(void)addPath:(DPPath*)otherPath trim:(BOOL)trim onlyMostRecent:(BOOL)last
{
    if([segments count] == 0)
    {
        [lastAddedSegments removeAllObjects];
        for(DPPathSegment *segment in [otherPath segments])
        {
            DPPathSegment *copy = [segment copy];
            [segments addObject:copy];
            [copy release];

            [lastAddedSegments addObject:copy];
        }
        empty = NO;
    }
    else
    {
        if(trim)
        {
            DPIntersectionResult intersection = [self intersection:otherPath];
            if(intersection.intersect && (!last ^ [lastAddedSegments containsObject:intersection.intersectedSegment]))
            {
                [lastAddedSegments removeAllObjects];
                
                while([segments lastObject] != intersection.intersectedSegment)
                {
                    [segments removeObject:[segments lastObject]];
                }
                [(DPPathSegment*)[segments lastObject] setEnd:intersection.intersectionPoint];
                
                BOOL include = NO;
                for(DPPathSegment *segment in [otherPath segments])
                {
                    if(segment == intersection.intersectingSegment)
                    {
                        DPPathSegment *trimmedSegment = [[DPPathSegment alloc] init];
                        trimmedSegment.start = intersection.intersectionPoint;
                        trimmedSegment.end = segment.end;
                        trimmedSegment.reversed = segment.reversed;
                        
                        [segments addObject:trimmedSegment];
                        [trimmedSegment release];
                        include = YES;
                        
                        [lastAddedSegments addObject:trimmedSegment];
                    }
                    else if (include)
                    {
                        DPPathSegment *copy = [segment copy];
                        [segments addObject:copy];
                        [copy release];
                        
                        [lastAddedSegments addObject:copy];
                    }
                }
                return;
            }
        }
        
        DPPathSegment *lastSegment = [segments lastObject];
        if(!NSEqualPoints(lastSegment.end,[(DPPathSegment*)[[otherPath segments] objectAtIndex:0] start]))
        {
            DPPathSegment *segment = [[DPPathSegment alloc] init];
            segment.start = lastSegment.end;
            segment.end = [(DPPathSegment*)[[otherPath segments] objectAtIndex:0] start];
            segment.reversed = [(DPPathSegment*)[[otherPath segments] objectAtIndex:0] reversed];
            [segments addObject:segment];
            [segment release];
        }
        
        [segments addObjectsFromArray:[otherPath segments]];
        
        [lastAddedSegments removeAllObjects];
        [lastAddedSegments addObjectsFromArray:[otherPath segments]];
        
    }
}

-(NSArray*)splitSegment:(DPPathSegment *)segment atLine:(DPPathSegment *)line
{
    if([segments containsObject:segment])
    {
        NSArray *results = [segment splitAtLine:line];
        if(results)
        {
            NSUInteger index = [segments indexOfObject:segment];
            [segments replaceObjectAtIndex:index withObject:[results objectAtIndex:0]];
            [segments insertObject:[results lastObject] atIndex:(index + 1)];
            return results;
        }
    }
    return nil;
}

-(NSArray*)segments
{
    return [[segments copy] autorelease];
}

-(DPIntersectionResult)intersection:(DPPath*)otherPath
{
    DPIntersectionResult result;
    for(DPPathSegment *mySegment in segments)
    {
        for(DPPathSegment *otherSegment in [otherPath segments])
        {
            result = [mySegment intersectsPathSegment:otherSegment];
            if(result.intersect)
            {
                return result;
            }
        }
    }
    
    result.intersect = NO;
    return result;
}

@end
