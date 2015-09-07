//
//  AnnotationTimeSeriesVisualizer.h
//  Annotation
//
//  Created by Adam Fouse on 8/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LayeredVisualizer.h"
@class TimeSeriesVisualizer;

@interface AnnotationTimeSeriesVisualizer : LayeredVisualizer {
	
	TimeSeriesVisualizer* dataViz;
    
    CALayer *annotationsLayer;
}

- (id)initWithTimelineView:(TimelineView *)timelineView andVisualizer:(TimeSeriesVisualizer*)viz;

@end
