//
//  SegmentMarker.h
//  Annotation
//
//  Created by Adam Fouse on 1/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "SegmentBoundary.h"
@class Annotation;
@class TimelineView;
@class SegmentVisualizer;

@interface TimelineMarker : NSObject {
	CALayer *layer;
	SegmentVisualizer *visualizer;
	TimelineView *timeline;
	
	SegmentBoundary *start;
	SegmentBoundary *end;
	
	Annotation *annotation;
	
	NSBezierPath *path;
	id data;
	CGImageRef image;
	
	NSColor *backgroundColor;
	
	NSTrackingArea* trackingArea;
	int track;
	BOOL alternate;
	BOOL selected;
	
	NSDate *date;
}

@property(retain) NSDate* date;
@property int track;
@property BOOL selected;
@property BOOL alternate;
@property(retain) id data;
@property(retain) CALayer* layer;
@property(assign) SegmentVisualizer* visualizer;
@property(assign) TimelineView* timeline;
@property(retain) SegmentBoundary* end;
@property(retain) NSBezierPath* path;
@property(retain) NSColor* backgroundColor;
@property CGImageRef image;

-(id)initWithKeyframe:(SegmentBoundary*)theKeyframe andPath:(NSBezierPath*)thePath;
-(id)initWithKeyframe:(SegmentBoundary*)theKeyframe;
-(id)initWithAnnotation:(Annotation*)annotation;

-(void)setData:(id)theData;
-(void)setTrackingArea:(NSTrackingArea *)ta;

-(void)setHighlighted:(BOOL)isHighlighted;

-(BOOL)startResizeLeft:(CGPoint)point;
-(BOOL)startResizeRight:(CGPoint)point;

-(NSTrackingArea *)trackingArea;
-(SegmentBoundary*)boundary;
-(Annotation*)annotation;
-(id)data;
-(NSTimeInterval)time;
-(BOOL)highlighted;
-(BOOL)isDuration;

-(void)update;
-(void)select;

@end
