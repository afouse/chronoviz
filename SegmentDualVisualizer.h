//
//  SegmentDualVisualizer.h
//  Annotation
//
//  Created by Adam Fouse on 6/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SegmentVisualizer.h"
#import "TimelineMarker.h"


@interface SegmentDualVisualizer : SegmentVisualizer {
	
	NSGradient* segmentGradient;
	NSGradient* segmentHighlightedGradient;
	NSColor* borderColor;
	
	CGColorRef cgSegmentColorA;
	CGColorRef cgSegmentColorB;
	CGColorRef cgSegmentColorHighlight;
	
	float durationBarHeight;
	
	int annotationRadius;
}


@end
