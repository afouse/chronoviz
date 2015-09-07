//
//  DPMappedValueTransformer.h
//  ChronoViz
//
//  Created by Adam Fouse on 1/17/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DPMappedValueTransformer : NSValueTransformer {

	NSArray *inputValues;
	NSArray *outputValues;
	
}

@property(copy) NSArray* inputValues;
@property(copy) NSArray* outputValues;

@end
