//
//  InteractionJump.m
//  Annotation
//
//  Created by Adam Fouse on 1/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "InteractionJump.h"
#import "InteractionLog.h"

@implementation InteractionJump

- (id)initWithFromMovieTime:(QTTime)fromMovieTime toMovieTime:(QTTime)toMovieTime andSessionTime:(double)theSessionTime
{
	[super init];
	fromTime = fromMovieTime;
	toTime = toMovieTime;
	movieTime = toMovieTime;
	sessionTime = theSessionTime;
	return self;
}

- (NSString *)description
{
	NSTimeInterval fromTimeInterval;
	QTGetTimeInterval(fromTime, &fromTimeInterval);
	NSTimeInterval toTimeInterval;
	QTGetTimeInterval(toTime, &toTimeInterval);
	return [NSString stringWithFormat:@"Time: %1.2f, From Time: %1.2f, To Time: %1.2f", sessionTime, fromTimeInterval, toTimeInterval];
}

- (NSString *)logOutput
{
	NSTimeInterval fromTimeInterval;
	QTGetTimeInterval(fromTime, &fromTimeInterval);
	NSTimeInterval toTimeInterval;
	QTGetTimeInterval(toTime, &toTimeInterval);
	return [NSString stringWithFormat:@"jump %1.2f %1.3f %1.3f\n", sessionTime, fromTimeInterval, toTimeInterval];
}

- (NSXMLElement *)xmlElement
{
	NSXMLElement *element = [super xmlElement];
	
	[element setName:@"jump"];
	
	NSTimeInterval fromTimeInterval;
	QTGetTimeInterval(fromTime, &fromTimeInterval);
	NSTimeInterval toTimeInterval;
	QTGetTimeInterval(toTime, &toTimeInterval);
	
	NSNumber *fromTimeNumber = [NSNumber numberWithDouble:fromTimeInterval];
	NSXMLNode *fromTimeAttribute = [NSXMLNode attributeWithName:@"fromTime"
													   stringValue:[fromTimeNumber stringValue]];
	[element addAttribute:fromTimeAttribute];
	
	NSNumber *toTimeNumber = [NSNumber numberWithDouble:toTimeInterval];
	NSXMLNode *toTimeAttribute = [NSXMLNode attributeWithName:@"toTime"
													stringValue:[toTimeNumber stringValue]];
	[element addAttribute:toTimeAttribute];
	
	return element;
}

+ (NSString *)typeString
{
	return @"jump";
}

- (QTTime)fromMovieTime
{
	return fromTime;
}

- (QTTime)toMovieTime
{
	return toTime;
}

- (int)type
{
	return AFInteractionTypeJump;
}

@end
