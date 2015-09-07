//
//  DateVisualizer.h
//  Annotation
//
//  Created by Adam Fouse on 11/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SegmentVisualizer.h"

@interface DateVisualizer : SegmentVisualizer {

	NSDate *startDate;
	NSDate *endDate;
	
	NSDateFormatter *dateFormatter;
	NSDateFormatter *timeFormatter;
	
	CALayer *skyLayer;
	CALayer *sunLayer;
	CALayer *groundLayer;
	NSBezierPath *orbs;
	NSBezierPath *lines;
	NSMutableArray *days;
	NSMutableArray *lineDates;
	NSMutableArray *lineTimes;
	
	NSGradient *groundGradient;
	NSGradient *dayGradient;
	NSColor *sunColor;
	NSColor *nightColor;
	NSColor *dayColor;
	
	BOOL createdViz;
}

- (void)createSky;
- (void)createGround;

@end
