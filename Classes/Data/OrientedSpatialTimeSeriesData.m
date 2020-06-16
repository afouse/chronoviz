//
//  OrientedSpatialTimeSeriesData.m
//  ChronoViz
//
//  Created by Adam Fouse on 11/8/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "OrientedSpatialTimeSeriesData.h"
#import "TimeCodedOrientationPoint.h"

@implementation OrientedSpatialTimeSeriesData


// Initialize with an array of TimeCodedDataPoints
-(id)initWithDataPointArray:(NSArray*)data
{
	self = [super initWithDataPointArray:data];
	if (self != nil) {
		if(([data count] > 0)
		   && !([[data objectAtIndex:0] isKindOfClass:[TimeCodedOrientationPoint class]]))
		{
			[self release];
			return nil;
		}
		else
		{
            return [super initWithDataPointArray:data];
			
		}
	}
	return self;
}

-(id)initWithXarray:(NSArray*)xArray andYarray:(NSArray*)yArray overRange:(CMTimeRange)timeRange
{
	NSUInteger numPoints = [xArray count];
	if([yArray count] != numPoints)
	{
		return nil;
	}
	
	double interval = (double)(timeRange.duration.value)/(numPoints - 1);
	
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:numPoints];
	int i;
	for(i = 0; i < numPoints; i++)
	{
		TimeCodedOrientationPoint *dataPoint = [[TimeCodedOrientationPoint alloc] init];
		[dataPoint setX:[[xArray objectAtIndex:i] floatValue]];
		[dataPoint setY:[[yArray objectAtIndex:i] floatValue]];
        [dataPoint setOrientation:0];
		[dataPoint setTime:CMTimeMake(i*interval,timeRange.duration.timescale)];
		[array addObject:dataPoint];
		[dataPoint release];
	}
    
	return [self initWithDataPointArray:array];
}


- (NSMutableArray*)dataPointsFromCSVArray:(NSArray*)dataArray
{
	NSMutableArray *dataPointArray = [NSMutableArray arrayWithCapacity:[dataArray count]];
	for(NSArray* row in dataArray)
	{
		TimeCodedOrientationPoint *dataPoint = [[TimeCodedOrientationPoint alloc] init];
		[dataPoint setValue:[[row objectAtIndex:1] doubleValue]];
		[dataPoint setTime:CMTimeMake([[row objectAtIndex:0] floatValue], 1000000)]; // TODO: Check if the timescale is correct.
		[dataPoint setY:[[row objectAtIndex:2] floatValue]];
		[dataPoint setX:[[row objectAtIndex:3] floatValue]];
        [dataPoint setOrientation:[[row objectAtIndex:4] floatValue]];
		[dataPointArray addObject:dataPoint];
		[dataPoint release];
	}
	return dataPointArray;
}


@end
