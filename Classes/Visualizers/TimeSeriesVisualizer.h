//
//  TimeSeriesVisualizer.h
//  Annotation
//
//  Created by Adam Fouse on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
#import "SegmentVisualizer.h"
@class TimeSeriesData;

@interface TimeSeriesVisualizer : SegmentVisualizer {

	NSMutableArray *subset;
	CGFloat subsetMax;
	CGFloat subsetMin;
	CMTimeRange subsetRange;
	
	CALayer *graphLayer;
	CALayer *linesLayer;
	NSBezierPath *graph;
	NSBezierPath *lines;
	CGFloat firstLine;
	CGFloat lineScale;
	CGFloat numbersWidth;
	int numLines;
	BOOL createdGraph;
	
}

- (void)createGraph;
- (void)createLines;

- (void)reloadData;

- (CALayer*)graphLayer;
- (CALayer*)linesLayer;

@end
