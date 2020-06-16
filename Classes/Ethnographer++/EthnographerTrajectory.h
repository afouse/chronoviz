//
//  EthnographerTrajectory.h
//  ChronoViz
//
//  Created by Adam Fouse on 11/8/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
@class EthnographerTrajectoryData;
@class DPPath;
@class DPPathSegment;
@class AnotoTrace;

extern NSString * const AFEthnographerTrajectoryRate;

@interface EthnographerOrientedTimeMarker : NSObject {
    BOOL hasOrientation;
    CGFloat orientation;
    CMTime time;
    NSString *uuid;
}

@property BOOL hasOrientation;
@property CGFloat orientation;
@property CMTime time;
@property(copy) NSString* uuid;

@end

@interface EthnographerTrajectoryPivot : NSObject {
    EthnographerOrientedTimeMarker *source;
    EthnographerOrientedTimeMarker *target;
    BOOL clockwise;
}

@property(retain) EthnographerOrientedTimeMarker *source;
@property(retain) EthnographerOrientedTimeMarker *target;
@property BOOL clockwise;

@end

@interface EthnographerTrajectory : NSObject {
    
    NSUInteger trajectoryID;
    NSString *trajectoryName;
    
    NSMutableArray *inputPathSegments;
    NSMutableDictionary *inputTimeMarkers;
    
    NSMutableDictionary *inputOrientations;
    NSMutableDictionary *inputPivots;
    
    DPPath* path;
    NSMutableArray *specifiedTimePoints;
    
    EthnographerTrajectoryData *trajectory;
    
    NSUInteger rate;
    
    NSUInteger lastTimeIndex;
    CMTime lastTime;
    
}

@property NSUInteger trajectoryID;
@property(copy) NSString* trajectoryName;
@property(readonly) EthnographerTrajectoryData* trajectory;

-(void)addPathSegment:(DPPathSegment*)path;
-(void)addPathStroke:(AnotoTrace*)path;
-(void)addPathStroke:(AnotoTrace*)path reversed:(BOOL)isReversed;
-(void)addTimeMarker:(DPPathSegment*)timeMarker atTime:(CMTime)time withId:(NSString*)uuid;

-(void)addOrientation:(CGFloat)degrees atTime:(CMTime)time withId:(NSString*)uuid;
-(void)addPivotFromSource:(NSString*)sourceId toTarget:(NSString*)targetId clockwise:(BOOL)cw startingAtTime:(CMTime)time withId:(NSString*)uuid;

-(void)removePathElement:(id)pathElement;
-(void)removeTimeMarkerAtTime:(CMTime)time;
-(void)removeOrientationMark:(EthnographerOrientedTimeMarker*)mark;
-(void)removePivot:(EthnographerTrajectoryPivot*)pivot;

-(void)regeneratePath;

-(NSArray*)pathSegments;
-(NSDictionary*)timeMarks;
-(NSDictionary*)orientationMarks;
-(NSDictionary*)pivotMarks;


@end

