//
//  InteractionSpeedChange.m
//  Annotation
//
//  Created by Adam Fouse on 11/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InteractionSpeedChange.h"
#import "InteractionLog.h"

@implementation InteractionSpeedChange

- (id)initWithSpeed:(float)theSpeed andMovieTime:(CMTime)theMovieTime atTime:(double)theSessionTime
{
	[super init];
	speed = theSpeed;
	movieTime = theMovieTime;
	sessionTime = theSessionTime;
	return self;
}

- (NSString *)description
{
	NSTimeInterval movieTimeInterval;
	movieTimeInterval = CMTimeGetSeconds(movieTime);
	return [NSString stringWithFormat:@"Time: %1.2f, Speed: %1.2f, MovieTime: %1.3f",sessionTime,speed,movieTimeInterval];
}

- (float)speed
{
	return speed;
}

- (NSString *)logOutput
{
	NSTimeInterval movieTimeInterval;
	movieTimeInterval = CMTimeGetSeconds(movieTime);
	return [NSString stringWithFormat:@"speedchange %1.2f %1.2f %1.3f\n",sessionTime,speed,movieTimeInterval];
}

- (NSXMLElement *)xmlElement
{
	NSXMLElement *element = [super xmlElement];
	
	[element setName:@"speedChange"];
	
	NSTimeInterval movieTimeInterval;
	movieTimeInterval = CMTimeGetSeconds(movieTime);
	NSNumber *movieTimeNumber = [NSNumber numberWithDouble:movieTimeInterval];
	NSXMLNode *sessionTimeAttribute = [NSXMLNode attributeWithName:@"movieTime"
													   stringValue:[movieTimeNumber stringValue]];
	[element addAttribute:sessionTimeAttribute];
	
	NSNumber *speedNumber = [NSNumber numberWithDouble:speed];
	NSXMLNode *speedAttribute = [NSXMLNode attributeWithName:@"speed"
													   stringValue:[speedNumber stringValue]];
	[element addAttribute:speedAttribute];
	
	return element;
}

+ (NSString *)typeString
{
	return @"speedchange";
}

- (int)type
{
	return AFInteractionTypeSpeedChange;
}

@end
