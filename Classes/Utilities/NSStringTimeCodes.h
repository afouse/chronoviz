//
//  NSStringTimeCodes.h
//  DataPrism
//
//  Created by Adam Fouse on 6/23/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

enum {
	DPTimeCodeAutomaticMask = 1 << 8,
	DPTimeCodeSecondsMask = 1 << 0,
	DPTimeCodeMinutesMask = 1 << 1,
	DPTimeCodeHoursMask = 1 << 2,
	DPTimeCodeDecisecondsMask = 1 << 3,
	DPTimeCodeMillisecondsMask = 1 << 7,
	DPTimeCodeFramesMask = 1 << 4,
	DPTimeCodeTimeOfDayMask = 1 << 5,
	DPTimeCode24HourMask = 1 << 6
};

@interface NSString (TimeCodes) 

+ (void)setDefaultTimeFormat:(NSUInteger)timeFormat;
+ (NSUInteger)defaultTimeFormat;

+ (NSString*)stringWithTimeInterval:(NSTimeInterval)interval;
+ (NSString*)stringWithTimeInterval:(NSTimeInterval)interval sinceDate:(NSDate*)date;
+ (NSString*)stringWithTimeInterval:(NSTimeInterval)interval sinceDate:(NSDate*)date withOptions:(NSUInteger)optionsMask;
+ (NSString*)stringWithQTTime:(QTTime)time;
+ (NSString*)stringWithQTTime:(QTTime)time sinceDate:(NSDate*)date;
+ (NSString*)stringWithQTTime:(QTTime)time sinceDate:(NSDate*)date withOptions:(NSUInteger)optionsMask;

- (NSTimeInterval)timeInterval;

@end
