//
//  DPTimeIntervalToStringTransformer.m
//  ChronoViz
//
//  Created by Adam Fouse on 1/11/12.
//  Copyright (c) 2012 University of California, San Diego. All rights reserved.
//

#import "DPTimeIntervalToStringTransformer.h"
#import "NSStringTimeCodes.h"

@implementation DPTimeIntervalToStringTransformer

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
	if([value isKindOfClass:[NSNumber class]])
	{
		return [NSString stringWithTimeInterval:[value floatValue]];
	}
	
	return nil;
}

- (id)reverseTransformedValue:(id)value
{
    if (value == nil) return nil;
    
	NSString *timeString = (NSString*)value;
	
    return [NSNumber numberWithFloat:[timeString timeInterval]];
}


@end
