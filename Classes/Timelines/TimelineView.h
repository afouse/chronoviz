//
//  TimelineView.h
//  Annotation
//
//  Created by Adam Fouse on 1/22/09.
//  Copyright 2009 Adam Fouse. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
#import <QTKit/QTKit.h>
#import "TimelineMarker.h"
#import "AnnotationView.h"
#import "DPStateRecording.h"
@class SegmentVisualizer;
@class TimelineMarkerResize;
@class TimelinePlayhead;
@class TimelineMarker;
@class TimeSeriesData;
@class AnnotationFilter;

@interface TimelineView : NSView <AnnotationView,DPStateRecording,NSMenuDelegate> {
	QTMovie* movie;
	BOOL setup;
	BOOL resizing;
	
	BOOL needsFullRedraw;
	
	TimelineView *superTimelineView;
	TimelineView *subTimelineView;
	
	QTTimeRange range;
	NSString *label;
	
	// For timelines that are tied to a particular annotation
	Annotation *basisAnnotation;
	TimelineView *basisTimeline;
	BOOL filterAnnotations;
	
	AnnotationFilter *annotationFilter;
	
	BOOL shiftingTimeline;
	NSTrackingArea* shiftingTracker;
	
	NSMutableArray* annotations;
	//TimeSeriesData* timeSeriesData;
	NSMutableArray* dataSets;
	SegmentVisualizer *segmentVisualizer;
	SegmentVisualizer *timesVisualizer;
	Class timeSeriesVisualizerClass;
	
	NSGradient* backgroundGradient;
	NSColor* backgroundColor;
	NSColor* borderColor;
	NSColor* playheadColor;
	
	TimelineMarker *highlightedMarker;
	TimelineMarker *selectedMarker;
	
	
	BOOL showPlayhead;
	
	// Show the set of buttons that appears when the mouse is over the timeline
	BOOL showActionButtons;
	
	// Click on the timeline to move to that position in the movie
	BOOL clickToMovePlayhead;
	
	// Update movie in real time when moving playhead
	BOOL movingPlayhead;
	
	// Record timeline clicks
	BOOL recordClickPosition;
	
	// Automatically update playhead from movie time
	BOOL linkedToMovie;
	
	// Automatically update playhead from mouse movement
	BOOL linkedToMouse;
	
	// Allow multiple time series
	BOOL visualizeMultipleTimeSeries;
    
    // Toggle for making the background white
    BOOL whiteBackground;
	
	// Percentage complete
	double playheadPosition;
	
	CALayer *rootLayer;
	CALayer *visualizationLayer;
    CALayer *annotationsLayer;
	CALayer *timesLayer;
	CATextLayer *labelLayer;
	CALayer *playheadLayer;
	CALayer *actionLayer;
	CALayer *listLayer;
	CALayer *menuLayer;
	CALayer *selectionMask;
	
	TimelinePlayhead *playhead;
	float playheadWidth;
	
	// Direct movement of markers
	BOOL movingLeftMarker;
	BOOL movingRightMarker;
	TimelineMarker* draggingTimelineMarker;
	
	NSMutableArray* timePoints;
	NSArray* snapPoints;
	float snapThreshold;
	NSTimeInterval originalStartTime;
	NSTimeInterval originalEndTime;
	QTTime originalStartQTTime;
	QTTime originalEndQTTime;
	
	NSCursor *magnifyCursor;
	
	NSArray *contextualObjects;
}

@property BOOL resizing;
@property BOOL filterAnnotations;
@property BOOL showPlayhead;
@property BOOL showActionButtons;
@property BOOL clickToMovePlayhead;
@property BOOL recordClickPosition;
@property BOOL linkedToMovie;
@property BOOL linkedToMouse;
@property BOOL visualizeMultipleTimeSeries;
@property BOOL whiteBackground;
@property double playheadPosition;
@property QTTimeRange range;
@property(assign) TimelineMarker *highlightedMarker;
@property(assign) TimelineView *superTimelineView;
@property(assign) TimelineView *subTimelineView;
@property(readonly) CALayer* visualizationLayer;
@property(readonly) CALayer* annotationsLayer;
@property(readonly) CALayer* timesLayer;
@property(retain) AnnotationFilter *annotationFilter;
@property(copy) NSString *label;

-(void)awakeFromNib;
-(void)setup;
-(void)reset;
-(void)removeFromSuperTimeline;
-(void)resetTrackingAreas;

-(void)setMovie:(QTMovie *)mov;
-(void)setSegmentVisualizer:(SegmentVisualizer *)visualizer;
-(BOOL)setRangeFromBeginTime:(QTTime)begin andEndTime:(QTTime)end;
-(void)setBasisMarker:(TimelineMarker*)marker;
-(void)updateRange;
-(BOOL)shouldHighlightMarker:(TimelineMarker*)marker;

-(IBAction)setLabelAction:(id)sender;

-(void)showTimes:(BOOL)showTimes;
-(void)visualizeAudio:(id)sender;
-(void)visualizeKeyframes:(id)sender;
-(void)visualizeData:(id)sender;
-(void)toggleShowAnnotations;
-(void)toggleVisualizeMultipleTimeSeries:(id)sender;
-(void)toggleTimeSeriesVisualization:(id)sender;

-(void)addAnnotation:(Annotation*)annotation;
-(void)addAnnotations:(NSArray*)array;
-(void)removeAnnotation:(Annotation*)annotation;
-(void)updateAnnotation:(Annotation*)annotation;
-(BOOL)displayAnnotation:(Annotation*)annotation;

-(IBAction)editAnnotationFilters:(id)sender;
-(IBAction)setCategoryFilter:(id)sender;

-(void)setData:(TimeSeriesData*)data;
-(void)addData:(TimeSeriesData*)data;
-(void)startTimelineShift;
-(void)endTimelineShift;
-(IBAction)alignToPlayhead:(id)sender;
-(IBAction)resetAlignment:(id)sender;

-(QTMovie*)movie;
-(Annotation*)basisAnnotation;
-(SegmentVisualizer*)segmentVisualizer;
-(NSArray*)segments;
-(NSArray*)annotations;
-(void)setSelected:(TimelineMarker*)marker;

-(NSTimeInterval)closestTimePoint:(NSTimeInterval)timeValue;
-(void)updateTimePoints;

-(BOOL)resizingAnnotation;
-(void)redraw;
-(void)redrawSegments;
-(void)redrawAllSegments;

-(NSPoint)pointFromTime:(QTTime)time;
-(QTTime)timeFromPoint:(NSPoint)point;

// Core Animation
- (void)updatePlayheadPosition;
- (CALayer*)playheadLayer;

@end
