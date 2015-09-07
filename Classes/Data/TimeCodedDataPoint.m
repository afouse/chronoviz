//
//  TimeCodedDataPoint.m
//  Annotation
//
//  Created by Adam Fouse on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TimeCodedDataPoint.h"

@implementation TimeCodedDataPoint

@synthesize time;
@synthesize value;

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeQTTime:time forKey:@"AnnotationDataTime"];
	[coder encodeDouble:value forKey:@"AnnotationDataValue"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
		self.time = [coder decodeQTTimeForKey:@"AnnotationDataTime"];
		self.value = [coder decodeDoubleForKey:@"AnnotationDataValue"];
	}
    return self;
}

-(NSString*)csvString
{
	return [NSString stringWithFormat:@"%.6f,%.6f",[self seconds],value];
}

-(double)numericValue
{
	return [self value];
}

-(NSTimeInterval)seconds
{
	NSTimeInterval timeInterval;
	QTGetTimeInterval(time, &timeInterval);
	return timeInterval;
}

@end
