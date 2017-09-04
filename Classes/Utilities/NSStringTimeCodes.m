//
//  NSStringTimeCodes.m
//  DataPrism
//
//  Created by Adam Fouse on 6/23/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "NSStringTimeCodes.h"

static NSUInteger defaultTimeFormat = (DPTimeCodeAutomaticMask | DPTimeCodeDecisecondsMask);

@implementation NSString (TimeCodes)

+ (void)setDefaultTimeFormat:(NSUInteger)timeFormat
{
    defaultTimeFormat = timeFormat;
}

+ (NSUInteger)defaultTimeFormat
{
    return defaultTimeFormat;
}

#pragma mark TimeInterval to String

+ (NSString*)stringWithTimeInterval:(NSTimeInterval)interval
{
	return [NSString stringWithTimeInterval:interval sinceDate:nil withOptions:defaultTimeFormat];
}

+ (NSString*)stringWithTimeInterval:(NSTimeInterval)interval sinceDate:(NSDate*)date
{
	return [NSString stringWithTimeInterval:interval sinceDate:date withOptions:(DPTimeCodeTimeOfDayMask | DPTimeCodeSecondsMask)];
}

+ (NSString*)stringWithTimeInterval:(NSTimeInterval)interval sinceDate:(NSDate*)date withOptions:(NSUInteger)optionsMask
{
	NSString *timeString = nil;
	
	NSDate *theDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:date];
	
	if(optionsMask & DPTimeCodeTimeOfDayMask)
	{
		NSCalendar *gregorian = [[NSCalendar alloc]
								 initWithCalendarIdentifier:NSGregorianCalendar];
		
		NSDateComponents *timeComponents = [gregorian components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:theDate];
		
		int hours = (int)[timeComponents hour];
		int minutes = (int)[timeComponents minute];
		int seconds = (int)[timeComponents second];
		
		NSString *timeOfDay = nil;
		if(hours > 11)
		{
			timeOfDay = @"PM";
			if(hours > 12)
				hours -= 12;
		}
		else
		{
			timeOfDay = @"AM";
		}
		
		if(DPTimeCodeSecondsMask & optionsMask)
		{
			timeString = [NSString stringWithFormat:@"%02i:%02i:%02i %@",hours,minutes,seconds,timeOfDay];
		}
		else
		{
			timeString = [NSString stringWithFormat:@"%02i:%02i %@",hours,minutes,timeOfDay];
		}
	}
	else
	{
        NSString *negative = @"";
        if(interval < 0)
        {
            negative = @"-";
            interval = -interval;
        }
        
		float totalSeconds = interval;
		int minutes = totalSeconds/60;
		int seconds = totalSeconds - minutes*60;
		
		if((optionsMask & DPTimeCodeAutomaticMask) && (minutes > 59))
		{
			optionsMask = optionsMask | DPTimeCodeHoursMask;
		}
		
		NSString *fractionalSeconds = @"";
		if(optionsMask & DPTimeCodeMillisecondsMask)
		{
			int milliseconds = roundf((totalSeconds - (minutes*60 + seconds)) * 1000);
			if(milliseconds == 1000)
			{
				seconds++;
				milliseconds = 0;
			}
			fractionalSeconds =  [[NSString alloc] initWithFormat:@".%03i",milliseconds];
		}
		else if(optionsMask & DPTimeCodeDecisecondsMask)
		{
			int deciseconds = roundf((totalSeconds - (minutes*60 + seconds)) * 10);
			if(deciseconds == 10)
			{
				seconds++;
				deciseconds = 0;
			}
			fractionalSeconds =  [[NSString alloc] initWithFormat:@".%i",deciseconds];
		}
		
		//int deciseconds = roundf((totalSeconds - (minutes*60 + seconds)) * 10);
		
		
		if(optionsMask & DPTimeCodeHoursMask) 
		{
			int hours = minutes/60;
			minutes = minutes - (hours*60);
			timeString = [NSString stringWithFormat:@"%@%02i:%02i:%02i%@",negative,hours,minutes,seconds,fractionalSeconds];
		}
		else
		{
			timeString =  [NSString stringWithFormat:@"%@%02i:%02i%@",negative,minutes,seconds,fractionalSeconds];
		}
		
		[fractionalSeconds release];
	}
	
	[theDate release];
	return timeString;

}

#pragma mark QTTime to String

+ (NSString*)stringWithCMTime:(CMTime)time
{
    NSTimeInterval interval = CMTimeGetSeconds(time);
	return [NSString stringWithTimeInterval:interval];
}

+ (NSString*)stringWithCMTime:(CMTime)time sinceDate:(NSDate*)date
{
	NSTimeInterval interval = CMTimeGetSeconds(time);
	return [NSString stringWithTimeInterval:interval sinceDate:date];
}

+ (NSString*)stringWithCMTime:(CMTime)time sinceDate:(NSDate*)date withOptions:(NSUInteger)optionsMask
{
	NSTimeInterval interval = CMTimeGetSeconds(time);
	return [NSString stringWithTimeInterval:interval sinceDate:date withOptions:optionsMask];
}

#pragma mark String to TimeInterval

- (NSTimeInterval)timeInterval
{
    if([self rangeOfString:@":"].location != NSNotFound)
    {
        NSString *absString = self;
        if(([absString characterAtIndex:0] == '-') && ([absString length] > 1))
        {
            absString = [absString substringFromIndex:1];
        }
        NSArray *components = [absString componentsSeparatedByString:@":"];
        NSUInteger count = [components count];
        if(count == 3)
        {
            return (([[components objectAtIndex:0] floatValue] * 3600.0) +
                    ([[components objectAtIndex:1] floatValue] * 60.0) +
                    [[components objectAtIndex:2] floatValue]);
            
        }
        else if (count == 2)
        {
            return (([[components objectAtIndex:0] floatValue] * 60.0) +
                    [[components objectAtIndex:1] floatValue]);
        }
        else
        {
            return 0;
        }
    }
    else
    {
        return [self doubleValue];	
    }
}

@end
