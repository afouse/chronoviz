//
//  TimeVisualizer.h
//  DataPrism
//
//  Created by Adam Fouse on 3/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SegmentVisualizer.h"

@interface TimeVisualizer : SegmentVisualizer {
	
	NSTimeInterval interval;
	
	CGFloat lineHeight;
	CGFloat minSpace;
	CGFloat maxSpace;
	NSDictionary *labelAttr;
	
	CALayer *timesLayer;
	NSBezierPath *lines;
	NSMutableArray *days;
	NSMutableArray *lineDates;
	NSMutableArray *lineTimes;
	
	NSGradient *groundGradient;

	
	BOOL createdViz;
}

- (void)createLines;
- (void)createLayer;

- (NSString*)timeCodeString:(NSTimeInterval)time;

@end
