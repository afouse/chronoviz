//
//  MultiTimelineView.h
//  Annotation
//
//  Created by Adam Fouse on 6/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TimelineView.h"
@class Annotation;

@interface MultiTimelineView : TimelineView {

	NSMutableArray *timelines;
	
	CGFloat interTimelineSpace;
	CGFloat timelineHeight;
    CGFloat maximumHeight;
	
	CGMutablePathRef theLines;
	
	BOOL needsLayout;
	TimelineView* activeTimeline;
	TimelineView* draggingTimeline;
	CGFloat dragOffset;
    
    BOOL wrappedTimelines;
}

@property CGFloat interTimelineSpace;
@property CGFloat timelineHeight;
@property CGFloat maximumHeight;
@property(readonly) int maxTimelines;
@property BOOL needsLayout;
@property BOOL wrappedTimelines;
@property(assign) TimelineView* draggingTimeline;
@property(assign) TimelineView* activeTimeline;

- (TimelineView*)baseTimeline;
- (NSArray*)timelines;

// Convenience methods
- (TimelineView *)addNewTimeline;
- (TimelineView *)addNewAnnotationTimeline:(id)sender;
- (TimelineView *)addNewKeyframeTimeline:(id)sender;
- (TimelineView *)addNewDataTimeline:(id)sender;

- (BOOL)addTimelines:(NSArray*)timelineArray;
- (BOOL)addTimeline:(TimelineView*)timeline;
- (BOOL)addTimelines:(NSArray*)timelineArray atIndex:(NSUInteger)index;
- (BOOL)addTimeline:(TimelineView*)timeline atIndex:(NSUInteger)index;
- (BOOL)addTimeline:(TimelineView*)timeline aboveTimeline:(TimelineView*)existingTimeline;
- (void)removeTimeline:(TimelineView*)timeline;
- (void)replaceTimeline:(TimelineView*)oldTimeline withTimeline:(TimelineView*)newTimeline;
- (void)replaceHighestTimelineWithTimeline:(TimelineView*)timeline;
- (void)removeHighestTimeline;
- (void)layoutTimelines;

- (void)showAnnotation:(Annotation*)annotation;

- (BOOL)removeData:(TimeCodedData*)theData;

@end
