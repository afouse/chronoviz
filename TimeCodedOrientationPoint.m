//
//  TimeCodedOrientationPoint.m
//  ChronoViz
//
//  Created by Adam Fouse on 11/8/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "TimeCodedOrientationPoint.h"

@implementation TimeCodedOrientationPoint

@synthesize orientation,reversed;

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeFloat:self.orientation forKey:@"DPDataOrientation"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		self.orientation = [coder decodeFloatForKey:@"DPDataOrientation"];
	}
    return self;
}

-(NSString*)csvString
{
	return [NSString stringWithFormat:@"%@,%.6f",[super csvString],self.orientation];
}

-(CGFloat)radians
{
    return DEGREES_TO_RADIANS(orientation);
}

@end
