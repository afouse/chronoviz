//
//  TimelinePlayhead.h
//  Annotation
//
//  Created by Adam Fouse on 7/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>

@interface TimelinePlayhead : NSObject {

	CALayer *playheadlayer;
	CALayer *thumblayer;
	
	CGMutablePathRef theThumb;
	
	CGFloat minx;
	CGFloat midx;
	CGFloat inset;
}

- (id)initWithLayer:(CALayer*)theLayer;
- (CALayer*)layer;

- (void)setHeight:(CGFloat)height;
- (void)setBounds:(CGRect)theRect;

@end
