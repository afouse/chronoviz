//
//  AnnotationHover.h
//  Annotation
//
//  Created by Adam Fouse on 6/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
@class Annotation;
@class TimelineView;
@class TimelineMarker;
@class MAAttachedWindow;

@interface AnnotationHover : NSObject {

	IBOutlet NSTextField *annotationHoverTitle;
	IBOutlet NSTextField *annotationHoverContent;
	IBOutlet NSImageView *annotationHoverImage;
	TimelineView *hoverTimeline;
	
	IBOutlet NSView *annotationHoverView;
	
	MAAttachedWindow *hoverWindow;
	TimelineMarker *currentMarker;
	
	NSRect originalFrame;
	
}

- (void)displayForTimelineMarker:(TimelineMarker*)marker;
- (void)closeForTimelineMarker:(TimelineMarker*)marker;
- (void)close;

- (void)setAnnotation:(Annotation*)annotation;
- (void)reset;
- (NSView*)hoverView;

@end
