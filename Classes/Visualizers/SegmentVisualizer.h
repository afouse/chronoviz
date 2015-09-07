//
//  SegmentVisualizer.h
//  Annotation
//
//  Created by Adam Fouse on 1/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <QuartzCore/CoreAnimation.h>
#import "TimelineView.h"
@class Annotation;
@class TimelineMarker;
@class VideoProperties;

@interface SegmentVisualizer : NSObject {
	TimelineView *timeline;
	NSMutableArray *addedSegments;	
	NSMutableArray *markers;
	BOOL autoSegments;
	
	VideoProperties *videoProperties;
}

@property BOOL autoSegments;
@property(retain) VideoProperties* videoProperties;

-(id)initWithTimelineView:(TimelineView*)timelineView;

-(TimelineMarker *)addKeyframe:(SegmentBoundary*)keyframe;
-(TimelineMarker *)removeSegmentBoundary:(SegmentBoundary*)boundary;
-(void)updateMarker:(TimelineMarker*)marker;
-(BOOL)updateMarkers;
-(void)reset;
-(void)setup;

-(NSArray *)markers;
-(QTMovie *)movie;

// Core Animation Layer drawing
-(CALayer*)visualizationLayer;
-(void)drawMarker:(TimelineMarker *)marker;

-(BOOL)canDragMarkers;
-(BOOL)dragMarker:(TimelineMarker*)marker forDragEvent:(NSEvent*)theEvent;


@end
