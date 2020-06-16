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

- (id)initWithFromMovieTime:(CMTime)fromMovieTime toMovieTime:(CMTime)toMovieTime andSessionTime:(double)theSessionTime
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
	fromTimeInterval = CMTimeGetSeconds(fromTime);
	NSTimeInterval toTimeInterval;
	toTimeInterval = CMTimeGetSeconds(toTime);
	return [NSString stringWithFormat:@"Time: %1.2f, From Time: %1.2f, To Time: %1.2f", sessionTime, fromTimeInterval, toTimeInterval];
}

- (NSString *)logOutput
{
	NSTimeInterval fromTimeInterval;
    fromTimeInterval = CMTimeGetSeconds(fromTime);
	NSTimeInterval toTimeInterval;
    toTimeInterval = CMTimeGetSeconds(toTime);
	return [NSString stringWithFormat:@"jump %1.2f %1.3f %1.3f\n", sessionTime, fromTimeInterval, toTimeInterval];
}

- (NSXMLElement *)xmlElement
{
	NSXMLElement *element = [super xmlElement];
	
	[element setName:@"jump"];
	
	NSTimeInterval fromTimeInterval;
    fromTimeInterval = CMTimeGetSeconds(fromTime);
	NSTimeInterval toTimeInterval;
    toTimeInterval = CMTimeGetSeconds(toTime);
	
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

- (CMTime)fromMovieTime
{
	return fromTime;
}

- (CMTime)toMovieTime
{
	return toTime;
}

- (int)type
{
	return AFInteractionTypeJump;
}

@end
