//
//  OverviewTimelineView.h
//  DataPrism
//
//  Created by Adam Fouse on 3/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TimelineView.h"

@interface OverviewTimelineView : TimelineView <NSAnimationDelegate> {

	CMTimeRange selection;
	
	IBOutlet TimelineView *detailTimeline;
	
	CALayer* selectionLayer;
	NSTrackingArea *selectionTrackingArea;
	
	CGColorRef selectionColor;
	
	NSCursor *selectionCursor;
	BOOL overSelection;
	BOOL resizeSelectionLeft;
	BOOL resizeSelectionRight;
	
	BOOL makingSelection;
	
	BOOL dragging;
	
	CMTime clickTime;
	CMTime offset;
	
	CGFloat resizeMargin;
	
	CGFloat minSelectionWidth;
	CGFloat selectionStartX;
	CGFloat selectionEndX;
	
}

-(CMTimeRange)selection;
-(void)setSelection:(CMTimeRange)theSelection;
-(void)setSelection:(CMTimeRange)theSelection animate:(BOOL)animateChange;

-(void)updateSelectionCursor:(NSEvent*)theEvent;

@end
