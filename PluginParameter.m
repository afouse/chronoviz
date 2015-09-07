//
//  PluginParameter.m
//  Annotation
//
//  Created by Adam Fouse on 9/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PluginParameter.h"


@implementation PluginParameter

@synthesize parameterName;
@synthesize parameterValue;
@synthesize maxValue;
@synthesize minValue;
@synthesize possibleValues;

-(float)floatValue
{
	return (float)parameterValue;
}

- (void) dealloc
{
	[parameterName release];
	[super dealloc];
}


- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:parameterName forKey:@"AnnotationPluginParameterName"];
	[coder encodeFloat:parameterValue forKey:@"AnnotationPluginParameterValue"];
	[coder encodeFloat:maxValue forKey:@"AnnotationPluginParameterMaxValue"];
	[coder encodeFloat:minValue forKey:@"AnnotationPluginParameterMinValue"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
		[self setParameterName:[coder decodeObjectForKey:@"AnnotationPluginParameterName"]];
		[self setParameterValue:[coder decodeFloatForKey:@"AnnotationPluginParameterValue"]];
		[self setMaxValue:[coder decodeFloatForKey:@"AnnotationPluginParameterMaxValue"]];
		[self setMinValue:[coder decodeFloatForKey:@"AnnotationPluginParameterMinValue"]];
	}
    return self;
}

@end
