//
//  TimelineZoomAnimation.h
//  DataPrism
//
//  Created by Adam Fouse on 4/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
@class OverviewTimelineView;

@interface TimelineZoomAnimation : NSAnimation {

	QTTimeRange startRange;
	QTTimeRange endRange;
	
	OverviewTimelineView *overviewTimeline;
	
}

@property QTTimeRange startRange;
@property QTTimeRange endRange;
@property(retain) OverviewTimelineView* overviewTimeline;


@end
