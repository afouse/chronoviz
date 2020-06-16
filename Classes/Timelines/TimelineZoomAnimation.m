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
		
		startRangeBegin = CMTimeGetSeconds(startRange.start);
		startRangeEnd = CMTimeGetSeconds(CMTimeRangeGetEnd(startRange));
		endRangeBegin = CMTimeGetSeconds(endRange.start);
		endRangeEnd = CMTimeGetSeconds(CMTimeRangeGetEnd(endRange));
		
		NSTimeInterval currentBegin = startRangeBegin + (endRangeBegin - startRangeBegin)*progress;
		NSTimeInterval currentEnd = startRangeEnd + (endRangeEnd - startRangeEnd)*progress;
		

		[overviewTimeline setSelection:CMTimeRangeMake(CMTimeMake(currentBegin, 1000000), // TODO: Check if the timescale is correct.
													   CMTimeMake(currentEnd - currentBegin, 1000000))]; // TODO: Check if the timescale is correct.
	}
	
}

@end
