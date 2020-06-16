//
//  TimeCodedSourcedString.m
//  DataPrism
//
//  Created by Adam Fouse on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TimeCodedSourcedString.h"


@implementation TimeCodedSourcedString

@synthesize source;
@synthesize interpolated;
@synthesize duration;

- (void) dealloc
{
	[source release];
	[super dealloc];
}


-(NSString*)csvString
{
	return [NSString stringWithFormat:@"%@,%@",[super csvString],source];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeCMTime:time forKey:@"AnnotationDataTime"];
	[coder encodeCMTime:duration forKey:@"AnnotationDataDuration"];
	[coder encodeObject:string forKey:@"AnnotationDataString"];
	[coder encodeObject:source forKey:@"AnnotationDataSource"];
	[coder encodeBool:interpolated forKey:@"AnnotationDataSourceInterpolated"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
		self.time = [coder decodeCMTimeForKey:@"AnnotationDataTime"];
		self.duration = [coder decodeCMTimeForKey:@"AnnotationDataDuration"];
		self.string = [[coder decodeObjectForKey:@"AnnotationDataString"] retain];
		self.source = [[coder decodeObjectForKey:@"AnnotationDataSource"] retain];
		self.interpolated = [coder decodeBoolForKey:@"AnnotationDataSourceInterpolated"];
		
	}
    return self;
}

@end
