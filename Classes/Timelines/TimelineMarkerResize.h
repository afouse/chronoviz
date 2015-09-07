//
//  ResizeLayer.h
//  Annotation
//
//  Created by Adam Fouse on 7/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
@class TimelineMarker;

@interface TimelineMarkerResize : NSObject {

	CALayer *resizelayer;
	float radius;
	float arrowMargin;
	
	CGMutablePathRef theCircle;
	CGMutablePathRef theArrows;
	
	TimelineMarker *marker;
	NSTrackingArea *trackingArea;
	BOOL highlighted;
	
}

@property float radius;
@property float arrowMargin;
@property BOOL highlighted;
@property(retain) NSTrackingArea *trackingArea;
@property(assign) TimelineMarker *marker;

- (id)initWithLayer:(CALayer*)theLayer;
- (CALayer*)layer;

@end
