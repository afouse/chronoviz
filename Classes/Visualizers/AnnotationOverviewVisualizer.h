//
//  AnnotationOverviewVisualizer.h
//  ChronoViz
//
//  Created by Adam Fouse on 4/8/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SegmentVisualizer.h"

@interface AnnotationOverviewVisualizer : SegmentVisualizer {

	CGFloat trackHeight;
	NSMutableArray *trackOrder;
	NSMutableDictionary *tracks;
	
}

@end
