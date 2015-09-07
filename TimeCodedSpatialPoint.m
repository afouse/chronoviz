//
//  TimeCodedSpatialPoint.m
//  ChronoViz
//
//  Created by Adam Fouse on 6/16/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "TimeCodedSpatialPoint.h"


@implementation TimeCodedSpatialPoint

@synthesize x;
@synthesize y;

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeFloat:self.x forKey:@"DPDataX"];
	[coder encodeFloat:self.y forKey:@"DPDataY"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		self.x = [coder decodeFloatForKey:@"DPDataX"];
		self.y = [coder decodeFloatForKey:@"DPDataY"];	
	}
    return self;
}

-(NSString*)csvString
{
	return [NSString stringWithFormat:@"%@,%.6f,%.6f",[super csvString],self.y,self.x];
}

@end
