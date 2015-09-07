//
//  EthnographerTrajectoryData.h
//  ChronoViz
//
//  Created by Adam Fouse on 6/14/12.
//  Copyright (c) 2012 University of California, San Diego. All rights reserved.
//

#import "OrientedSpatialTimeSeriesData.h"
@class AnotoNotesData;
@class EthnographerTrajectory;

@interface EthnographerTrajectoryData : OrientedSpatialTimeSeriesData {
    NSString *annotationSessionId;
    AnotoNotesData *annotationSession;
    EthnographerTrajectory *trajectorySource;
    
}

@property(retain) AnotoNotesData *annotationSession;
@property(retain) EthnographerTrajectory *trajectorySource;

@end
