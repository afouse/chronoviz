//
//  TimelineZoomAnimation.h
//  DataPrism
//
//  Created by Adam Fouse on 4/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
@class OverviewTimelineView;

@interface TimelineZoomAnimation : NSAnimation {

	CMTimeRange startRange;
	CMTimeRange endRange;
	
	OverviewTimelineView *overviewTimeline;
	
}

@property CMTimeRange startRange;
@property CMTimeRange endRange;
@property(retain) OverviewTimelineView* overviewTimeline;


@end
