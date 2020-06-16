//
//  DPActivityLog.m
//  ChronoViz
//
//  Created by Adam Fouse on 6/14/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPActivityLog.h"
#import "AnnotationDocument.h"

NSString * const DPActivityLogUpdateNotification = @"DPActivityLogUpdate";

@implementation DPActivityLog

@synthesize numberOfBins;
@synthesize currentStartTime;
@synthesize lastRealTime;
@synthesize documentDuration;

- (id)initForDocument:(AnnotationDocument*)doc
{
	self = [super init];
	if (self != nil) {
		self.numberOfBins = 30;
		documentDuration = CMTimeGetSeconds([doc duration]);
		binSize = documentDuration/numberOfBins;
		
		currentActivity = [[NSMutableArray alloc] initWithCapacity:self.numberOfBins];
		for(int i = 0; i < numberOfBins; i++)
		{
			[currentActivity addObject:[NSDecimalNumber zero]];
		}
		currentTime = 0;
		
		pastActivity = nil;
		
		self.currentStartTime = [NSDate date];
		
		lastTimePoint = [[doc movie] currentTime];
		self.lastRealTime = [NSDate date];
		
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeFloat:currentTime forKey:@"DPActivityLogCurrentTime"];
	[coder encodeObject:currentActivity forKey:@"DPActivityLogCurrentActivity"];
	[coder encodeInt:numberOfBins forKey:@"DPActivityLogNumberOfBins"];
	[coder encodeFloat:binSize forKey:@"DPActivityLogBinSize"];
    [coder encodeDouble:documentDuration forKey:@"DPActivityLogDocumentDuration"];
    [coder encodeCMTime:lastTimePoint forKey:@"DPActivityLogLastTimePoint"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
        documentDuration = [coder decodeDoubleForKey:@"DPActivityLogDocumentDuration"];
        
        self.numberOfBins = [coder decodeIntForKey:@"DPActivityLogNumberOfBins"];
        binSize = [coder decodeFloatForKey:@"DPActivityLogBinSize"];
        
        currentTime = [coder decodeFloatForKey:@"DPActivityLogCurrentTime"];
        
        currentActivity = [[coder decodeObjectForKey:@"DPActivityLogCurrentActivity"] retain];
        
        lastTimePoint = [coder decodeQCMTimeForKey:@"DPActivityLogLastTimePoint"];
        
        self.lastRealTime = [NSDate date];
		
	}
    return self;
}


- (void) dealloc
{
	self.lastRealTime = nil;
	self.currentStartTime = nil;
    [currentActivity release];
	[super dealloc];
}


- (void)addSpeedChange:(float)speed atTime:(CMTime)time
{
	NSDate *now = [NSDate date];
	NSTimeInterval startTime;
	NSTimeInterval endTime;
	
	startTime = CMTimeGetSeconds(lastTimePoint);
	endTime = CMTimeGetSeconds(time);
	
	NSTimeInterval docDuration = endTime - startTime;
	NSTimeInterval realDuration = [now timeIntervalSinceDate:lastRealTime];
	int bins = ceil(docDuration/binSize);
	NSDecimalNumber *durationPerBin = [[NSDecimalNumber alloc] initWithFloat:realDuration/bins];
	
	int startBin = floor(startTime/binSize);
	for(int bin = 0; bin < bins; bin++)
	{
		NSDecimalNumber* value = [currentActivity objectAtIndex:(startBin + bin)];
		[currentActivity replaceObjectAtIndex:(startBin + bin) withObject:[value decimalNumberByAdding:durationPerBin]];
	}

	currentTime += realDuration;
	self.lastRealTime = now;
	lastTimePoint = time;
	[durationPerBin release];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DPActivityLogUpdateNotification object:self];
}

- (void)addJumpFrom:(CMTime)fromTime to:(CMTime)toTime
{
	NSTimeInterval jumpSize;
	jumpSize = CMTimeGetSeconds(CMTimeSubtract(toTime, fromTime));
	if(abs(jumpSize) < binSize)
	{
		[self addSpeedChange:0 atTime:toTime];
	}
	else
	{
		self.lastRealTime = [NSDate date];
		lastTimePoint = toTime;
	}
}

- (NSTimeInterval)activityForTimePoint:(CMTime)time
{
	NSTimeInterval timeInterval;
	timeInterval = CMTimeGetSeconds(time);
	return [self activityForSeconds:timeInterval];
}

- (NSTimeInterval)activityForSeconds:(NSTimeInterval)seconds
{

	int bin = floor(seconds/binSize);
	if(bin >= numberOfBins)
	{
		bin = numberOfBins - 1;
	}
	return [[currentActivity objectAtIndex:bin] floatValue];

	//int bin = floor(seconds/binSize);
	//return [[currentActivity objectAtIndex:bin] floatValue];
}

- (CGFloat)scoreForTimePoint:(CMTime)time
{
	return 0;
}

- (CGFloat)scoreForSeconds:(NSTimeInterval)seconds
{
    return [self scoreForSeconds:seconds withMethod:DPActivityCalculationAutomatic];
}

- (CGFloat)scoreForSeconds:(NSTimeInterval)seconds withMethod:(DPActivityCalculationMethod)calculationMethod
{
   	NSTimeInterval activity = [self activityForSeconds:seconds];
    
    BOOL absolute = YES;
    if(calculationMethod == DPActivityCalculationAutomatic)
    {
        absolute = (currentTime < 100);
    }
    else if (calculationMethod == DPActivityCalculationAbsolute)
    {
        absolute = YES;
    }
    else if (calculationMethod == DPActivityCalculationRelative)
    {
        absolute = NO;
    }
    
	if(absolute)
	{
		return fmin((activity/10),1.0);
	}
	else
	{
		CGFloat averageTime = (currentTime/numberOfBins);
		return fmin((activity/averageTime),1.0);
	} 
}

@end
