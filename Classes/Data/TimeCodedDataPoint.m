//
//  TimeCodedDataPoint.m
//  Annotation
//
//  Created by Adam Fouse on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TimeCodedDataPoint.h"
#import "NSCoder+QTLegacy.h"

@implementation TimeCodedDataPoint

@synthesize time;
@synthesize value;

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeCMTime:time forKey:@"AnnotationDataCMTime"];
	[coder encodeDouble:value forKey:@"AnnotationDataValue"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
        if([coder containsValueForKey:@"AnnotationDataTime"])
        {
            self.time = [coder decodeLegacyQTTimeForKey:@"AnnotationDataTime"];
        }
        else if([coder containsValueForKey:@"AnnotationDataCMTime"])
        {
            self.time = [coder decodeCMTimeForKey:@"AnnotationDataCMTime"];
        }
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
    return CMTimeGetSeconds(time);
}

@end
