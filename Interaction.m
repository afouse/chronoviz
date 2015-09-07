//
//  Interaction.m
//  Annotation
//
//  Created by Adam Fouse on 11/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Interaction.h"
#import "InteractionLog.h"


@implementation Interaction

@synthesize source;

- (NSString *)logOutput
{
	return @"Default Output";
}

- (NSXMLElement *)xmlElement
{
	NSXMLElement *element = [NSXMLElement elementWithName:@"interaction"];
	if([self source])
	{
		NSXMLNode *sourceAttribute = [NSXMLNode attributeWithName:@"source"
													  stringValue:[self source]];
		[element addAttribute:sourceAttribute];	
	}
	NSNumber *sessionTimeNumber = [NSNumber numberWithDouble:[self sessionTime]];
	NSXMLNode *sessionTimeAttribute = [NSXMLNode attributeWithName:@"sessionTime"
													   stringValue:[sessionTimeNumber stringValue]];
	[element addAttribute:sessionTimeAttribute];
	
	return element;
}

- (QTTime)movieTime
{
	return movieTime;
}

- (double)sessionTime
{
	return sessionTime;
}

- (int)type
{
	return AFInteractionType;
}

- (NSString *)description
{
	NSTimeInterval movieTimeInterval;
	QTGetTimeInterval(movieTime, &movieTimeInterval);
	return [NSString stringWithFormat:@"Time: %1.2f, MovieTime: %1.2f", sessionTime, movieTimeInterval];
}

+ (NSString *)typeString
{
	return @"interaction";
}

@end
