//
//  MultipleTimeSeriesVisualizer.h
//  ChronoViz
//
//  Created by Adam Fouse on 1/7/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
#import "TimeSeriesVisualizer.h"
@class TimeSeriesData;
@class TimeCodedDataPoint;

@interface MultipleTimeSeriesVisualizer : TimeSeriesVisualizer {
	
	NSMutableArray *subsets;
	NSMutableArray *subsetRanges;
	NSMutableArray *subsetDataMaxes;
	NSMutableArray *subsetDataMins;
	TimeCodedDataPoint *maxValuePoint;
	TimeCodedDataPoint *minValuePoint;

	NSMutableArray *graphs;
	
}

@end