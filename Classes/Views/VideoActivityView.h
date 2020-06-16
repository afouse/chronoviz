//
//  VideoActivityVidew.h
//  Annotation
//
//  Created by Adam Fouse on 12/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "InteractionLog.h"
#import <AVKit/AVKit.h>


@interface VideoActivityView : NSView {
	InteractionLog *interactions;
	
	float movieTimeToPixel;
	float sessionTimeToPixel;
	float margin;
	
	NSBezierPath *path;
	NSBezierPath *segmentLines;
	NSBezierPath *promptLines;
	
	AVPlayer *movie;
	
	CGFloat * dashPattern;
	
	NSColor *backgroundColor;
	NSColor *activityColor;
	NSColor *segmentColor;
}

@property(retain) NSColor* backgroundColor;
@property(retain) NSColor* activityColor;
@property(retain) NSColor* segmentColor;

-(void)setMovie:(QTMovie *)movie;
-(void)setInteractionLog:(InteractionLog *)log;
-(void)updatePath;
-(void)addSpeedChange:(float)speed atTime:(CMTime)time;
-(NSPoint)addPointatMovieTime:(float)movieTime andSessionTime:(float)sessionTime;
-(NSPoint)jumpToPointatMovieTime:(float)movieTime andSessionTime:(float)sessionTime;

- (void)exportImageToFile:(NSString *)path;

@end
