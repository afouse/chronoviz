//
//  GeographicTimeSeriesData.m
//  Annotation
//
//  Created by Adam Fouse on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "GeographicTimeSeriesData.h"
#import "TimeCodedDataPoint.h"
#import "TimeCodedGeographicPoint.h"

@implementation GeographicTimeSeriesData

@synthesize lonVariableName;

// Initialize with an array of values evenly distributed over a range
-(id)initWithDataPoints:(NSArray*)values overRange:(CMTimeRange)timeRange
{
	return nil;
}

// Initialize with an array of TimeCodedDataPoints
-(id)initWithDataPointArray:(NSArray*)data
{
	self = [super initWithDataPointArray:data];
	if (self != nil) {
		if(([data count] == 0)
		   || !([[data objectAtIndex:0] isKindOfClass:[TimeCodedGeographicPoint class]]))
		{
			[self release];
			return nil;
		}
		else
		{
			maxLat = - FLT_MAX;
			maxLon = - FLT_MAX;
			minLat = FLT_MAX;
			minLon = FLT_MAX;
			
			for(TimeCodedGeographicPoint* dataPoint in data)
			{
				maxLat = fmax(maxLat,[dataPoint lat]);
				maxLon = fmax(maxLon,[dataPoint lon]);
				minLat = fmin(minLat,[dataPoint lat]);
				minLon = fmin(minLon,[dataPoint lon]);
			}
		}
	}
	return self;
}

-(id)initWithLatitudes:(NSArray*)latitudes andLongitudes:(NSArray*)longitudes overRange:(CMTimeRange)timeRange
{
	NSUInteger numPoints = [latitudes count];
	if([longitudes count] != numPoints)
	{
		return nil;
	}
	
	maxLat = - FLT_MAX;
	maxLon = - FLT_MAX;
	minLat = FLT_MAX;
	minLon = FLT_MAX;
	
	float interval = (float)(timeRange.duration.value)/(numPoints - 1);
	
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:numPoints];
	int i;
	for(i = 0; i < numPoints; i++)
	{
		TimeCodedGeographicPoint *dataPoint = [[TimeCodedGeographicPoint alloc] init];
		[dataPoint setLat:[[latitudes objectAtIndex:i] floatValue]];
		[dataPoint setLon:[[longitudes objectAtIndex:i] floatValue]];
		//NSLog(@"Lat: %f Lon: %f",[dataPoint lat],[dataPoint lon]);
		[dataPoint setTime:CMTimeMake(i*interval,timeRange.duration.timescale)];
		
		maxLat = fmax(maxLat,[dataPoint lat]);
		maxLon = fmax(maxLon,[dataPoint lon]);
		minLat = fmin(minLat,[dataPoint lat]);
		minLon = fmin(minLon,[dataPoint lon]);
		
		[array addObject:dataPoint];
		[dataPoint release];
	}
	
	NSLog(@"MaxLat: %f, MaxLon: %f, MinLat: %f, MinLon: %f",maxLat,maxLon,minLat,minLon);
	
	return [self initWithDataPointArray:array];
}

- (float) maxLat
{
	return maxLat;
}

- (float) maxLon
{
	return maxLon;
}

- (float) minLat
{
	return minLat;
}

- (float) minLon
{
	return minLon;
}

- (NSString*)latVariableName
{
	return [self variableName];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeFloat:maxLat forKey:@"AnnotationDataSetMaxLat"];
	[coder encodeFloat:maxLon forKey:@"AnnotationDataSetMaxLon"];
	[coder encodeFloat:minLat forKey:@"AnnotationDataSetMinLat"];
	[coder encodeFloat:minLon forKey:@"AnnotationDataSetMinLon"];
	[coder encodeObject:lonVariableName forKey:@"AnnotationDataSetLonVariable"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		maxLat = [coder decodeFloatForKey:@"AnnotationDataSetMaxLat"];
		maxLon = [coder decodeFloatForKey:@"AnnotationDataSetMaxLon"];
		minLat = [coder decodeFloatForKey:@"AnnotationDataSetMinLat"];
		minLon = [coder decodeFloatForKey:@"AnnotationDataSetMinLon"];
		self.lonVariableName = [coder decodeObjectForKey:@"AnnotationDataSetLonVariable"];
	}
    return self;
}


- (NSMutableArray*)dataPointsFromCSVArray:(NSArray*)dataArray
{
	NSMutableArray *dataPointArray = [NSMutableArray arrayWithCapacity:[dataArray count]];
	int timeScale = range.start.timescale;
	BOOL timeIntervals = ([(NSString*)[[dataArray objectAtIndex:0] objectAtIndex:0] rangeOfString:@"."].location != NSNotFound);	
	for(NSArray* row in dataArray)
	{
		TimeCodedGeographicPoint *dataPoint = [[TimeCodedGeographicPoint alloc] init];
		[dataPoint setValue:[[row objectAtIndex:1] doubleValue]];
		if(timeIntervals)
		{
			[dataPoint setTime:CMTimeMake([[row objectAtIndex:0] floatValue], 1000000)]; // TODO: Check if the timescale is correct.
		}
		else
		{
			[dataPoint setTime:CMTimeMake([[row objectAtIndex:0] longLongValue],timeScale)];
		}
		[dataPoint setLat:[[row objectAtIndex:2] floatValue]];
		[dataPoint setLon:[[row objectAtIndex:3] floatValue]];
		[dataPointArray addObject:dataPoint];
		[dataPoint release];
	}
	return dataPointArray;
}

@end
