//
//  DPMappedValueTransformer.m
//  ChronoViz
//
//  Created by Adam Fouse on 1/17/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPMappedValueTransformer.h"


@implementation DPMappedValueTransformer

@synthesize inputValues;
@synthesize outputValues;

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		[self setInputValues:[NSArray arrayWithObjects:
							  [NSNumber numberWithInt:0],
							  [NSNumber numberWithInt:100],
							  nil]];
		[self setOutputValues:[NSArray arrayWithObjects:
							  [NSNumber numberWithInt:0],
							  [NSNumber numberWithInt:1],
							   nil]];
	}
	return self;
}


- (void) dealloc
{
	[inputValues release];
	[outputValues release];
	[super dealloc];
}

- (id)transformedValue:(id)value
{
    float inputValue;
	
    if (value == nil) return nil;
	
    // Attempt to get a reasonable value from the
    // value object.
    if ([value respondsToSelector: @selector(floatValue)]) {
		// handles NSString and NSNumber
        inputValue = [value floatValue];
    } else {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Value (%@) does not respond to -floatValue.",
		 [value class]];
    }
	
	// Calculate output value
	int i;
	float inputMap1 = 0;
	float inputMap2 = 0;
	for(i = 0; i < ([inputValues count] - 1); i++)
	{
		inputMap1 = [[inputValues objectAtIndex:i] floatValue];
		if(inputMap1 == inputValue)
		{
			return [outputValues objectAtIndex:i];
		}
		
		inputMap2 = [[inputValues objectAtIndex:(i + 1)] floatValue];
		if((inputMap1 < inputValue) && (inputValue < inputMap2))
		{
			float interpolationPoint = (inputValue - inputMap1)/(inputMap2 - inputMap1);
			float outputMap1 = [[outputValues objectAtIndex:i] floatValue];
			float outputMap2 = [[outputValues objectAtIndex:(i + 1)] floatValue];
			
			
			return [NSNumber numberWithFloat:((interpolationPoint * (outputMap2 - outputMap1)) + outputMap1)];
		}
	}
	
	if(inputValue == [[inputValues objectAtIndex:([inputValues count] - 1)] floatValue])
	{
		return [outputValues objectAtIndex:([inputValues count] - 1)];
	}
	
    return [NSNumber numberWithFloat: inputValue];
}

- (id)reverseTransformedValue:(id)value
{
    float outputValue;
	
    if (value == nil) return nil;
	
    // Attempt to get a reasonable value from the
    // value object.
    if ([value respondsToSelector: @selector(floatValue)]) {
		// handles NSString and NSNumber
        outputValue = [value floatValue];
    } else {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Value (%@) does not respond to -floatValue.",
		 [value class]];
    }
	
	// Calculate output value
	int i;
	float outputMap1 = 0;
	float outputMap2 = 0;
	for(i = 0; i < ([outputValues count] - 1); i++)
	{
		outputMap1 = [[outputValues objectAtIndex:i] floatValue];
		if(outputMap1 == outputValue)
		{
			return [inputValues objectAtIndex:i];
		}
		
		outputMap2 = [[outputValues objectAtIndex:(i + 1)] floatValue];
		if((outputMap1 < outputValue) && (outputValue < outputMap2))
		{
			float interpolationPoint = (outputValue - outputMap1)/(outputMap2 - outputMap1);
			float inputMap1 = [[inputValues objectAtIndex:i] floatValue];
			float inputMap2 = [[inputValues objectAtIndex:(i + 1)] floatValue];
			
			return [NSNumber numberWithFloat:((interpolationPoint * (inputMap2 - inputMap1)) + inputMap1)];
		}
	}
	
	if(outputValue == [[outputValues objectAtIndex:([outputValues count] - 1)] floatValue])
	{
		return [inputValues objectAtIndex:([outputValues count] - 1)];
	}
	
    return [NSNumber numberWithFloat: outputValue];
}

@end
