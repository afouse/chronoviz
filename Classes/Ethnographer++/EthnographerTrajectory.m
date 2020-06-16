//
//  EthnographerTrajectory.m
//  ChronoViz
//
//  Created by Adam Fouse on 11/8/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "EthnographerTrajectory.h"
#import "EthnographerTrajectoryData.h"
#import "TimeCodedOrientationPoint.h"
#import "TimeSeriesData.h"
#import "DPPath.h"
#import "DPPathSegment.h"
#import "AnotoTrace.h"
#import "TimeCodedPenPoint.h"
#import "TimeCodedDataPoint.h"
#import "TimeCodedString.h"
#import "DPTimeUtilities.h"
#import "DPConstants.h"

NSString * const AFEthnographerTrajectoryRate = @"EthnographerTrajectoryRate";

static const double AFEthnographerTrajectoryTimeMarker = 1.0;

#pragma mark Helper Classes



@implementation EthnographerOrientedTimeMarker

@synthesize hasOrientation, orientation, time, uuid;

- (void)dealloc
{
    self.uuid = nil;
    [super dealloc];
}

@end


@implementation EthnographerTrajectoryPivot

@synthesize source,target,clockwise;

- (void)dealloc
{
    self.source = nil;
    self.target = nil;
    [super dealloc];
}

@end

@interface EthnographerTrajectory (Private)

-(void)processTimeMarker:(DPPathSegment*)marker atTime:(CMTime)time;
-(void)interpolateToSegment:(DPPathSegment *)segment atTime:(CMTime)time;

-(void)refreshOrientations;

@end

@implementation EthnographerTrajectory

@synthesize trajectoryID, trajectoryName, trajectory;

- (id)init {
    self = [super init];
    if (self) {
        inputPathSegments = [[NSMutableArray alloc] init];
        inputTimeMarkers = [[NSMutableDictionary alloc] init];
        inputOrientations = [[NSMutableDictionary alloc] init];
        inputPivots = [[NSMutableDictionary alloc] init];
        path = [[DPPath alloc] init];
        path.onlyTrimLast = YES;
        specifiedTimePoints = [[NSMutableArray alloc] init];
        trajectory = [[EthnographerTrajectoryData alloc] init];
        rate = [[NSUserDefaults standardUserDefaults] integerForKey:AFEthnographerTrajectoryRate];
        
        lastTimeIndex = 0;
        
        if(rate < 1)
		{
            rate = 10;
		}
        
    }
    return self;
}

- (void)dealloc {
    self.trajectoryName = nil;
    [inputPathSegments release];
    [inputTimeMarkers release];
    [path release];
    [specifiedTimePoints release];
    [super dealloc];
}

#pragma mark Paths

-(void)addPathSegment:(DPPathSegment*)pathsegment
{
    [inputPathSegments addObject:pathsegment];
    [path addSegment:pathsegment trim:YES];
    //NSLog(@"Add Path Segment, %@",path);
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DPDataSetUpdatedNotification object:self];
}

-(void)addPathStroke:(AnotoTrace*)trace
{
    [self addPathStroke:trace reversed:NO];
}

-(void)addPathStroke:(AnotoTrace*)trace reversed:(BOOL)isReversed
{
    DPPath *stroke = [[DPPath alloc] init];
    for(TimeCodedPenPoint* point in [trace dataPoints])
    {
        [stroke addPoint:NSMakePoint(point.x, point.y)];
    }
    [inputPathSegments addObject:stroke];
    
    for(DPPathSegment *segment in [stroke segments])
    {
        segment.reversed = isReversed;
    }
    
    [path addPath:stroke trim:YES];
    
    [stroke release];
    //NSLog(@"Add Path Stroke, %@",path);
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DPDataSetUpdatedNotification object:self];
}

-(void)addTimeMarker:(DPPathSegment*)timeMarker atTime:(CMTime)time withId:(NSString *)uuid
{
    //NSArray *timeMarkerTimes = [[inputTimeMarkers allKeys] sortedArrayUsingFunction:dpQTTimeValueSort context:NULL];
    //BOOL addToEnd = (CMTimeCompare([[timeMarkerTimes lastObject] QTTimeValue], time) == NSOrderedAscending);
    
    [inputTimeMarkers setObject:timeMarker forKey:[NSValue valueWithQTTime:time]];
    
    EthnographerOrientedTimeMarker *orientation = [[EthnographerOrientedTimeMarker alloc] init];
    orientation.time = time;
    orientation.uuid = uuid;
    orientation.hasOrientation = NO;
    [inputOrientations setObject:orientation forKey:uuid];
    [orientation release];

    [self regeneratePath];
    
    // Computational efficiency of two separate pathways isn't worth the potential errors...
    
//    if(addToEnd)
//    {
//        [self processTimeMarker:timeMarker atTime:time];
//        [self refreshOrientations];
//    }
//    else
//    {
//        [self regeneratePath];
//    }
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DPDataSetUpdatedNotification object:self];
}

-(void)processTimeMarker:(DPPathSegment*)timeMarker atTime:(CMTime)time
{
    for(int segmentIndex = lastTimeIndex; segmentIndex < [[path segments] count]; segmentIndex++)
    {
        DPPathSegment *segment = [[path segments] objectAtIndex:segmentIndex];
        
//    }
//    
//    for(DPPathSegment *segment in [path segments])
//    {
        DPIntersectionResult intersection = [segment intersectsPathSegment:timeMarker];
        
        if(intersection.intersect)
        {
            NSArray *split = [path splitSegment:segment atLine:timeMarker];
            //NSLog(@"Path after split: %@",path);
            if([[trajectory dataPoints] count] == 0)
            {
                TimeCodedOrientationPoint *point = [[TimeCodedOrientationPoint alloc] init];
                point.x = intersection.intersectionPoint.x;
                point.y = intersection.intersectionPoint.y;
                point.time = time;
                point.value = AFEthnographerTrajectoryTimeMarker;
                point.orientation = 0;
                //point.orientation = atan((segment.end.y - segment.start.y)/(segment.end.x - segment.start.x));
                
                [trajectory addPoint:point];
                [point release];
                
                lastTime = time;
                lastTimeIndex = [[path segments] indexOfObject:[split objectAtIndex:1]];
                
                
            }
            else
            {
                [self interpolateToSegment:[split objectAtIndex:1] atTime:time];
            }
            return;
        }
    }
    
    
    // For time markers that don't match the spatio-temporal ordering, but still cross the path
    // e.g., for "still" moments.
    for(DPPathSegment *segment in [path segments])
    {
        DPIntersectionResult intersection = [segment intersectsPathSegment:timeMarker];
        
        if(intersection.intersect)
        {
            if ([[trajectory dataPoints] count] > 0)
            {
                [self interpolateToSegment:[[path segments] objectAtIndex:lastTimeIndex] atTime:time];
            }
        }
    }

}

#pragma mark Orientations

-(void)addOrientation:(CGFloat)degrees atTime:(CMTime)time withId:(NSString*)uuid
{
    if(!QTTimeInTimeRange(time, [trajectory range]))
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"The current video time does not have a path defined."];
        [alert setInformativeText:@"Orientation marks can only be added to existing paths. Please make sure that you have make both path marks and time marks before adding orientations."];
        [alert runModal];
        [alert release];
    }
    
    if(degrees > 360)
    {
        degrees = fmodf(degrees, 360);
    }
    
    while(degrees < 0)
    {
        degrees += 360;
    }
    
    
    // If the current time is a time marker, then there will be already be a non-oriented time marker in inputOrientations
    EthnographerOrientedTimeMarker *existingMarker = nil;
    for(EthnographerOrientedTimeMarker *marker in [inputOrientations allValues])
    {
        if(CMTimeCompare(time, marker.time) == NSOrderedSame)
        {
            existingMarker = marker;
            break;
        }
    }
    
    if(existingMarker)
    {
        [inputOrientations removeObjectForKey:existingMarker.uuid];
    }
    
    EthnographerOrientedTimeMarker *orientation = [[EthnographerOrientedTimeMarker alloc] init];
    orientation.time = time;
    orientation.orientation = degrees;
    orientation.uuid = uuid;
    orientation.hasOrientation = YES;
    
    [inputOrientations setObject:orientation forKey:uuid];
   
    [orientation release];
    
    [self refreshOrientations];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DPDataSetUpdatedNotification object:self];
    
}

-(void)addPivotFromSource:(NSString*)sourceId toTarget:(NSString*)targetId clockwise:(BOOL)cw startingAtTime:(CMTime)time withId:(NSString*)uuid
{
    EthnographerOrientedTimeMarker *source = [inputOrientations objectForKey:sourceId];
    EthnographerOrientedTimeMarker *target = [inputOrientations objectForKey:targetId];
    if (source && target)
    {
        if(CMTimeCompare(source.time, target.time) != NSOrderedAscending)
        {
            EthnographerOrientedTimeMarker *temp = source;
            source = target;
            target = temp;
        }
        
        if(CMTimeCompare(source.time, time) == NSOrderedAscending)
        {
            // Create a new orientation mark at the start of the pivot
            EthnographerOrientedTimeMarker *orientation = [[EthnographerOrientedTimeMarker alloc] init];
            orientation.time = time;
            orientation.orientation = source.orientation;
            orientation.uuid = uuid;
            orientation.hasOrientation = YES;
            
            [inputOrientations setObject:orientation forKey:uuid];
            
            [orientation release];
            
            source = orientation;
            sourceId = uuid;
        }
        
        EthnographerTrajectoryPivot *pivot = [[EthnographerTrajectoryPivot alloc] init];
        pivot.source = source;
        pivot.target = target;
        pivot.clockwise = cw;
        [inputPivots setObject:pivot forKey:sourceId];
        [pivot release];    
    }
    
    [self refreshOrientations];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DPDataSetUpdatedNotification object:self];
    
}

// TODO: account for pivot at start
-(void)refreshOrientations
{
    if([[trajectory dataPoints] count] < 2)
    {
        return;
    }
    
    NSArray *orientations = [[inputOrientations allValues] sortedArrayUsingComparator:^(id obj1, id obj2) {
        EthnographerOrientedTimeMarker *point1 = (EthnographerOrientedTimeMarker*)obj1;
        EthnographerOrientedTimeMarker *point2 = (EthnographerOrientedTimeMarker*)obj2;
        return CMTimeCompare([point1 time], [point2 time]);   
    }];
    
    NSUInteger timeIndex = 0;
    EthnographerOrientedTimeMarker *nextTime = [orientations objectAtIndex:timeIndex];
    
    CGFloat currentOrientation = -1;
    if([nextTime hasOrientation])
    {
        currentOrientation = [(EthnographerOrientedTimeMarker*)nextTime orientation];
    }
    
    timeIndex++;
    nextTime = [orientations objectAtIndex:timeIndex];
    
    EthnographerTrajectoryPivot *currentPivot = nil;
    
    NSUInteger pointIndex = 0;
    NSArray *points = [trajectory dataPoints];
    TimeCodedOrientationPoint *previousPoint = nil;
    TimeCodedOrientationPoint *point = [points objectAtIndex:pointIndex];
    TimeCodedOrientationPoint *nextPoint = [points objectAtIndex:++pointIndex];
    
    while(pointIndex < ([points count] - 1))
    {
        if(currentPivot)
        {
            NSTimeInterval currentTime;
            NSTimeInterval startTime;
            NSTimeInterval endTime;
            currentTime = CMTimeGetSeconds(point.time);
            startTime = CMTimeGetSeconds(currentPivot.source.time);
            endTime = CMTimeGetSeconds(currentPivot.target.time);
            
            if(currentTime > endTime)
            {
                currentOrientation = currentPivot.target.orientation;
                currentPivot = nil;
                timeIndex++;
                nextTime = [orientations objectAtIndex:timeIndex];
            }
            else 
            {
            
                CGFloat startOrientation = currentPivot.source.orientation;
                CGFloat endOrientation = currentPivot.target.orientation;
                CGFloat travel = currentPivot.clockwise ? (endOrientation - startOrientation) : (360.0 - (endOrientation - startOrientation));
                
                CGFloat distance = (currentTime - startTime)/(endTime - startTime);
                
                CGFloat orientation = currentPivot.clockwise ? (startOrientation + (distance * travel)) : (startOrientation - (distance * travel));
                
                if(orientation > 360)
                {
                    orientation = fmodf(orientation, 360);
                }
                
                if(orientation < 0)
                {
                    orientation = 360 + orientation;
                }
                
                point.orientation = orientation;
            }
            
        }
        else if(CMTimeCompare(point.time, [nextTime time]) != NSOrderedAscending)
        {
            if([nextTime hasOrientation])
            {
                currentOrientation = [nextTime orientation];
                currentPivot = [inputPivots objectForKey:[nextTime uuid]];
                point.orientation = currentOrientation;
            }
            else
            {
                currentOrientation = -1;
                CGFloat distance = sqrt(pow(nextPoint.y - point.y,2) + pow(nextPoint.x - point.x,2));
                if((distance < DBL_EPSILON) && previousPoint)
                {
                    point.orientation = previousPoint.orientation;
                }
                else
                {
                    CGFloat pathAngle = RADIANS_TO_DEGREES(atan2((nextPoint.y - point.y),(nextPoint.x - point.x))) + 90.0;
                    if(point.reversed)
                    {
                        pathAngle -= 180;
                    }
                    while(pathAngle < 0)
                    {
                        pathAngle = 360 + pathAngle;
                    }
                    
                    point.orientation =  pathAngle;
                } 
            }            
            
            
            timeIndex++;
            nextTime = [orientations objectAtIndex:timeIndex];
            
        }
        else if (currentOrientation > 0)
        {
            point.orientation = currentOrientation;
        }
        else 
        {
            CGFloat distance = sqrt(pow(nextPoint.y - point.y,2) + pow(nextPoint.x - point.x,2));
            if((distance < DBL_EPSILON) && previousPoint)
            {
                point.orientation = previousPoint.orientation;
            }
            else
            {
                CGFloat distance = sqrt(pow(nextPoint.y - point.y,2) + pow(nextPoint.x - point.x,2));
                if((distance < DBL_EPSILON) && previousPoint)
                {
                    point.orientation = previousPoint.orientation;
                }
                else
                {
                    CGFloat pathAngle = RADIANS_TO_DEGREES(atan2((nextPoint.y - point.y),(nextPoint.x - point.x))) + 90.0;
                    if(point.reversed)
                    {
                        pathAngle -= 180;
                    }
                    while(pathAngle < 0)
                    {
                        pathAngle = 360 + pathAngle;
                    }
                    
                    point.orientation =  pathAngle;
                }
            }
        }
        
        previousPoint = point;
        point = nextPoint;
        nextPoint = [points objectAtIndex:++pointIndex];
        
    }
    
    if(currentOrientation >= 0)
    {
        point.orientation = currentOrientation;
        nextPoint.orientation = currentOrientation;
    }
    else 
    {
        CGFloat distance = sqrt(pow(nextPoint.y - point.y,2) + pow(nextPoint.x - point.x,2));
        if((distance < DBL_EPSILON) && previousPoint)
        {
            point.orientation = previousPoint.orientation;
        }
        else
        {
            CGFloat pathAngle = RADIANS_TO_DEGREES(atan2((nextPoint.y - point.y),(nextPoint.x - point.x))) + 90.0;
            if(point.reversed)
            {
                pathAngle -= 180;
            }
            while(pathAngle < 0)
            {
                pathAngle = 360 + pathAngle;
            }
            
            point.orientation =  pathAngle;
        }
        nextPoint.orientation = point.orientation;
    }
    
    
}

#pragma mark Path Generation

-(void)regeneratePath
{
    [trajectory removeAllPoints];
    [path release];
    path = [[DPPath alloc] init];
    path.onlyTrimLast = YES;
    
    for(NSObject *pathElement in inputPathSegments)
    {
        if([pathElement isKindOfClass:[DPPathSegment class]])
        {
            [path addSegment:(DPPathSegment*)pathElement trim:YES];
        }
        else if ([pathElement isKindOfClass:[DPPath class]])
        {
            [path addPath:(DPPath*)pathElement trim:YES];
        }
    }
    
    lastTimeIndex = 0;
    
    NSArray *timeMarkerTimes = [[inputTimeMarkers allKeys] sortedArrayUsingFunction:dpCMTimeValueSort context:NULL];
    for(NSValue *timeValue in timeMarkerTimes)
    {
        DPPathSegment *timeMarker = [inputTimeMarkers objectForKey:timeValue];
        [self processTimeMarker:timeMarker atTime:[timeValue QTTimeValue]];
    }
    
    [self refreshOrientations];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DPDataSetUpdatedNotification object:trajectory];
}

-(void)interpolateToSegment:(DPPathSegment *)segment atTime:(CMTime)time
{
    NSArray *pathSegments = [path segments];
    NSMutableArray *subpath = [NSMutableArray array];
    
    NSUInteger endIndex = [pathSegments indexOfObject:segment];
    while(lastTimeIndex < endIndex)
    {
        [subpath addObject:[pathSegments objectAtIndex:lastTimeIndex]];
        lastTimeIndex++;
    }
    
    CGFloat totalDistance = 0;
    for(DPPathSegment *segment in subpath)
    {
        totalDistance += [segment length];
    }
    
    NSTimeInterval timediff;
    timediff = CMTimeGetSeconds(CMTimeSubtract(time, lastTime));
    NSUInteger numPoints = timediff * rate;
    NSTimeInterval startTime;
    startTime = CMTimeGetSeconds(lastTime);
    NSTimeInterval timeIncrement = 1.0/rate;
    
    CGFloat pointDistance = totalDistance/numPoints;
    
    NSUInteger segmentIndex = 0;
    double pointTotal = 0;
    double segmentDistance = 0;
    DPPathSegment *currentSegment = nil;
    double currentSegmentLength = 0;
    for(NSUInteger ptindex = 0; ptindex < numPoints; ptindex++)
    {
        if(totalDistance == 0)
        {
            startTime += timeIncrement;
            
            TimeCodedOrientationPoint *lastPoint = [[trajectory dataPoints] lastObject];
            
            TimeCodedOrientationPoint *point = [[TimeCodedOrientationPoint alloc] init];
            point.x = lastPoint.x;
            point.y = lastPoint.y;
            point.time = CMTimeMake(startTime, 1000000); // TODO: Check if the timescale is correct.
            point.reversed = lastPoint.reversed;
            
            [trajectory addPoint:point];
            [point release];
            
            pointTotal = pointTotal - pointDistance;
        }
        else
        {
            while((segmentIndex < [subpath count]) && ((pointTotal - pointDistance) < DBL_EPSILON))
            {
                currentSegment = [subpath objectAtIndex:segmentIndex];
                currentSegmentLength = [currentSegment length];
                pointTotal += currentSegmentLength;
                segmentDistance = 0;
                segmentIndex++;
            }
            
            segmentDistance = (currentSegmentLength - (pointTotal - pointDistance));
            double segmentPercent = fmin(1.0,segmentDistance/currentSegmentLength);
            
            startTime += timeIncrement;
            
            double dx = currentSegment.end.x - currentSegment.start.x;
            double dy = currentSegment.end.y - currentSegment.start.y;
            double stepx = dx * segmentPercent;
            double stepy = dy * segmentPercent;
            double px = currentSegment.start.x + stepx;
            double py = currentSegment.start.y + stepy;
            
            TimeCodedOrientationPoint *point = [[TimeCodedOrientationPoint alloc] init];
            point.x = px;
            point.y = py;
            point.time = CMTimeMake(startTime, 1000000); // TODO: Check if the timescale is correct.
            point.reversed = currentSegment.reversed;
            
            [trajectory addPoint:point];
            [point release];
            
            pointTotal = pointTotal - pointDistance;
        }
        
    }
    
    [(TimeCodedOrientationPoint*)[[trajectory dataPoints] lastObject] setValue:AFEthnographerTrajectoryTimeMarker];
    
//    for(DPPathSegment *segment in subpath)
//    {
//        NSUInteger segmentPoints = ([segment length]/totalDistance)*numPoints;
//        double dx = segment.end.x - segment.start.x;
//        double dy = segment.end.y - segment.start.y;
//        double stepx = dx / segmentPoints;
//        double stepy = dy / segmentPoints;
//        double px = segment.start.x + stepx;
//        double py = segment.start.y + stepy;
//        for (int ix = 0; ix < segmentPoints; ix++)
//        {
//            startTime += timeIncrement;
//            
//            TimeCodedOrientationPoint *point = [[TimeCodedOrientationPoint alloc] init];
//            point.x = px;
//            point.y = py;
//            point.time = CMTimeMake(startTime, 1000000); // TODO: Check if the timescale is correct.
//            
//            [trajectory addPoint:point];
//            [point release];
//            
//            px += stepx;
//            py += stepy;
//        }   
//    }
//    
    lastTime = [[[trajectory dataPoints] lastObject] time];
    
}

#pragma mark Trajectory Modification

-(void)removePathElement:(id)pathElement
{
    [inputPathSegments removeObject:pathElement];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DPDataSetUpdatedNotification object:self];
}

-(void)removeTimeMarkerAtTime:(CMTime)time
{
    [inputTimeMarkers removeObjectForKey:[NSValue valueWithQTTime:time]];
    
    EthnographerOrientedTimeMarker *markerToRemove = nil;
    for(EthnographerOrientedTimeMarker *marker in [inputOrientations allValues])
    {
        if(!marker.hasOrientation && (CMTimeCompare(time, marker.time) == NSOrderedSame))
        {
            markerToRemove = marker;
            break;
        }
    }
    
    if(markerToRemove)
    {
        [inputOrientations removeObjectForKey:markerToRemove.uuid];
    }
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DPDataSetUpdatedNotification object:self];
}

-(void)removeOrientationMark:(EthnographerOrientedTimeMarker*)mark;
{
    [inputOrientations removeObjectForKey:mark.uuid];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DPDataSetUpdatedNotification object:self];
}

-(void)removePivot:(EthnographerTrajectoryPivot*)pivot
{
    [inputPivots removeObjectForKey:pivot.source.uuid];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DPDataSetUpdatedNotification object:self];
}


#pragma mark Data Accessors

-(NSArray*)pathSegments
{
    return inputPathSegments;
}

-(NSDictionary*)timeMarks
{
    return inputTimeMarkers;
}

-(NSDictionary*)orientationMarks
{
    return inputOrientations;
}

-(NSDictionary*)pivotMarks
{
    return inputPivots;
}

@end
