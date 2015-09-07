//
//  TranscriptData.m
//  DataPrism
//
//  Created by Adam Fouse on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TranscriptData.h"
#import "TimeCodedString.h"
#import "Annotation.h"
#import "AnnotationDocument.h"


@implementation TranscriptData

@synthesize frameRate;

- (id) initWithTimeCodedStrings:(NSArray*)theStrings
{
	self = [super init];
	if (self != nil) {
		if(!theStrings)
		{
			strings = [[NSMutableArray alloc] init];
		}
		else
		{
			strings = [theStrings mutableCopy];
		}
		frameRate = 29;
	}
	return self;
}

- (void) dealloc
{
	[strings release];
	[super dealloc];
}


- (NSArray*)timeCodedStrings
{
	return strings;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:strings forKey:@"AnnotationDataArray"];
	[coder encodeFloat:frameRate forKey:@"AnnotationDataFrameRate"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		strings = [[coder decodeObjectForKey:@"AnnotationDataArray"] mutableCopy];
		frameRate = [coder decodeFloatForKey:@"AnnotationDataFrameRate"];
	}
    return self;
}



@end
