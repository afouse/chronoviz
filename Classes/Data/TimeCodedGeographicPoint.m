//
//  TimeCodedGeographicPoint.m
//  Annotation
//
//  Created by Adam Fouse on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TimeCodedGeographicPoint.h"


@implementation TimeCodedGeographicPoint

- (CGFloat)lat
{
	return y;
}

- (CGFloat)lon
{
	return x;
}

- (void)setLat:(CGFloat)theLat
{
	y = theLat;
}

- (void)setLon:(CGFloat)theLon
{
	x = theLon;
}

/*
- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeFloat:self.lat forKey:@"AnnotationDataLat"];
	[coder encodeFloat:self.lon forKey:@"AnnotationDataLon"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		self.lat = [coder decodeFloatForKey:@"AnnotationDataLat"];
		self.lon = [coder decodeFloatForKey:@"AnnotationDataLon"];	
	}
    return self;
}

-(NSString*)csvString
{
	return [NSString stringWithFormat:@"%@,%.6f,%.6f",[super csvString],self.lat,self.lon];
}
 */

@end
