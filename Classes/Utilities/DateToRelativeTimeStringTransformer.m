//
//  QTTimeToStringTransformer.m
//  Annotation
//
//  Created by Adam Fouse on 7/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DateToRelativeTimeStringTransformer.h"
#import "AnnotationDocument.h"
#import "Annotation.h"
#import "NSStringTimeCodes.h"

@implementation DateToRelativeTimeStringTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{		
	if([value isKindOfClass:[NSDate class]])
	{
		NSDate *date = (NSDate*)value;
		NSDate *reference = [[AnnotationDocument currentDocument] startDate];
		
		NSTimeInterval interval = [date timeIntervalSinceDate:reference];
		return [NSString stringWithTimeInterval:interval];
	}
	
	return nil;
}

- (id)reverseTransformedValue:(id)value
{
    if (value == nil) return nil;

	NSString *timeString = (NSString*)value;
	
	NSArray *components = [timeString componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
	
	if([components count] == 3)
	{
		float minutes = [[components objectAtIndex:0] floatValue];
		float seconds = [[components objectAtIndex:1] floatValue];
		float deciseconds = [[components objectAtIndex:2] floatValue];
		
		float totalSeconds = (minutes * 60.0) + seconds + (deciseconds/10);
		
		NSDate *reference = [[AnnotationDocument currentDocument] startDate];
		
		NSDate *newDate = [[NSDate alloc] initWithTimeInterval:totalSeconds sinceDate:reference];
		
		return [newDate autorelease];
	}
	
	return nil;
}

@end
