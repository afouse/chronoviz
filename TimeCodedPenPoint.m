//
//  TimeCodedPenPoint.m
//  DataPrism
//
//  Created by Adam Fouse on 2/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TimeCodedPenPoint.h"


@implementation TimeCodedPenPoint

@synthesize x;
@synthesize y;
@synthesize force;

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeFloat:x forKey:@"AnnotationDataX"];
	[coder encodeFloat:y forKey:@"AnnotationDataY"];
	[coder encodeFloat:force forKey:@"AnnotationDataForce"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		self.x = [coder decodeFloatForKey:@"AnnotationDataX"];
		self.y = [coder decodeFloatForKey:@"AnnotationDataY"];
		self.force = [coder decodeFloatForKey:@"AnnotationDataForce"];
	}
    return self;
}

-(NSString*)csvString
{
	return [NSString stringWithFormat:@"%f,%f,%.6f",x,y,force];
}


@end
