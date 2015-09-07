//
//  LayeredVisualizer.h
//  Annotation
//
//  Created by Adam Fouse on 8/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationVisualizer.h"

@interface LayeredVisualizer : AnnotationVisualizer {

	SegmentVisualizer *viz;
	
	BOOL overlayAnnotations;
}

@property BOOL overlayAnnotations;

-(id)initWithTimelineView:(TimelineView*)timelineView andSecondVisualizer:(SegmentVisualizer*)secondViz;
-(SegmentVisualizer*)dataVisualizer;

@end
