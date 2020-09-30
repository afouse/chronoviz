//
//  DPActivityLog.h
//  ChronoViz
//
//  Created by Adam Fouse on 6/14/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
@class AnnotationDocument;

extern NSString * const DPActivityLogUpdateNotification;

typedef enum {
	DPActivityCalculationAutomatic	 = 1,
	DPActivityCalculationAbsolute  = 2,
	DPActivityCalculationRelative	 = 3
} DPActivityCalculationMethod;

@interface DPActivityLog : NSObject <NSCoding> {

	int numberOfBins;
	NSTimeInterval duration;
	NSTimeInterval documentDuration;
	float binSize;
	
	NSMutableArray *currentActivity;
	NSMutableArray *pastActivity;
	
	NSTimeInterval currentTime;
	NSTimeInterval pastTime;
	NSDate* currentStartTime;
	
	CMTime lastTimePoint;
	NSDate *lastRealTime;
	
}

@property int numberOfBins;
@property NSTimeInterval documentDuration;
@property(retain) NSDate* currentStartTime;
@property(retain) NSDate* lastRealTime;

- (id)initForDocument:(AnnotationDocument*)doc;

- (void)addSpeedChange:(float)speed atTime:(CMTime)time;
- (void)addJumpFrom:(CMTime)time to:(CMTime)time;

- (NSTimeInterval)activityForTimePoint:(CMTime)time;
- (NSTimeInterval)activityForSeconds:(NSTimeInterval)seconds;
- (CGFloat)scoreForTimePoint:(CMTime)time;
- (CGFloat)scoreForSeconds:(NSTimeInterval)seconds;

- (CGFloat)scoreForSeconds:(NSTimeInterval)seconds withMethod:(DPActivityCalculationMethod)calculationMethod;

@end
