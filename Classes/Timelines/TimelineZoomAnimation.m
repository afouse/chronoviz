//
//  TimelineZoomAnimation.m
//  DataPrism
//
//  Created by Adam Fouse on 4/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TimelineZoomAnimation.h"
#import "OverviewTimelineView.h"

@implementation TimelineZoomAnimation

@synthesize startRange;
@synthesize endRange;
@synthesize overviewTimeline;

- (void) dealloc
{
	[overviewTimeline release];
	[super dealloc];
}


- (void)setCurrentProgress:(NSAnimationProgress)progress
{
    // Call super to update the progress value.
    [super setCurrentProgress:progress];
	
	if(progress == 1)
	{
		[overviewTimeline setSelection:endRange];
	}
	else
	{	
		NSTimeInterval startRangeBegin;
		NSTimeInterval startRangeEnd;
		
		NSTimeInterval endRangeBegin;
		NSTimeInterval endRangeEnd;
		
		QTGetTimeInterval(startRange.time, &startRangeBegin);
		QTGetTimeInterval(QTTimeRangeEnd(startRange), &startRangeEnd);
		QTGetTimeInterval(endRange.time, &endRangeBegin);
		QTGetTimeInterval(QTTimeRangeEnd(endRange), &endRangeEnd);
		
		NSTimeInterval currentBegin = startRangeBegin + (endRangeBegin - startRangeBegin)*progress;
		NSTimeInterval currentEnd = startRangeEnd + (endRangeEnd - startRangeEnd)*progress;
		

		[overviewTimeline setSelection:QTMakeTimeRange(QTMakeTimeWithTimeInterval(currentBegin), 
													   QTMakeTimeWithTimeInterval(currentEnd - currentBegin))];
	}
	
}

@end
