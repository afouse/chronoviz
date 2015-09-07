//
//  InteractionAddSegment.m
//  Annotation
//
//  Created by Adam Fouse on 11/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InteractionAddSegment.h"
#import "InteractionLog.h"

@implementation InteractionAddSegment

- (id)initWithMovieTime:(QTTime)theMovieTime andSessionTime:(double)theSessionTime
{
	[super init];
	movieTime = theMovieTime;
	sessionTime = theSessionTime;
	return self;
}

- (NSString *)description
{
	NSTimeInterval movieTimeInterval;
	QTGetTimeInterval(movieTime, &movieTimeInterval);
	return [NSString stringWithFormat:@"Time: %1.2f, MovieTime: %1.2f", sessionTime, movieTimeInterval];
}

- (NSString *)logOutput
{
	NSTimeInterval movieTimeInterval;
	QTGetTimeInterval(movieTime, &movieTimeInterval);
	return [NSString stringWithFormat:@"segment %1.2f %1.3f\n", sessionTime, movieTimeInterval];
}

- (NSXMLElement *)xmlElement
{
	NSXMLElement *element = [super xmlElement];
	
	[element setName:@"addSegment"];
	
	NSTimeInterval movieTimeInterval;
	QTGetTimeInterval(movieTime, &movieTimeInterval);
	NSNumber *movieTimeNumber = [NSNumber numberWithDouble:movieTimeInterval];
	NSXMLNode *sessionTimeAttribute = [NSXMLNode attributeWithName:@"movieTime"
													   stringValue:[movieTimeNumber stringValue]];
	[element addAttribute:sessionTimeAttribute];
	
	return element;
}

+ (NSString *)typeString
{
	return @"segment";
}

- (int)type
{
	return AFInteractionTypeAddSegment;
}

@end
