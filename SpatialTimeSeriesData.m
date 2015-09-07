//
//  SpatialTimeSeriesData.m
//  ChronoViz
//
//  Created by Adam Fouse on 6/16/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "SpatialTimeSeriesData.h"
#import "TimeCodedSpatialPoint.h"
#import "DPSpatialDataBase.h"

@implementation SpatialTimeSeriesData

@synthesize minX,minY,maxX,maxY;
@synthesize xOffset,yOffset;
@synthesize spatialBase;

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeFloat:maxX forKey:@"AnnotationDataSetMaxX"];
	[coder encodeFloat:maxY forKey:@"AnnotationDataSetMaxY"];
	[coder encodeFloat:minX forKey:@"AnnotationDataSetMinX"];
	[coder encodeFloat:minY forKey:@"AnnotationDataSetMinY"];
    [coder encodeFloat:xOffset forKey:@"AnnotationDataSetXOffset"];
	[coder encodeFloat:yOffset forKey:@"AnnotationDataSetYOffset"];
    
    if(spatialBase)
    {
        [coder encodeObject:spatialBase forKey:@"AnnotationDataSetSpatialBase"];
    }
    
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		maxX = [coder decodeFloatForKey:@"AnnotationDataSetMaxX"];
		maxY = [coder decodeFloatForKey:@"AnnotationDataSetMaxY"];
		minX = [coder decodeFloatForKey:@"AnnotationDataSetMinX"];
		minY = [coder decodeFloatForKey:@"AnnotationDataSetMinY"];
		xOffset = [coder decodeFloatForKey:@"AnnotationDataSetXOffset"];
		yOffset = [coder decodeFloatForKey:@"AnnotationDataSetYOffset"];
        
        DPSpatialDataBase *storedBase = [coder decodeObjectForKey:@"AnnotationDataSetSpatialBase"];
        if(storedBase)
        {
            self.spatialBase = storedBase;
            
            CGPoint savedOffsets = [self.spatialBase savedOffsets];
            
            if(savedOffsets.x != 0)
            {
                self.xOffset = savedOffsets.x;
            }
            
            if(savedOffsets.y != 0)
            {
                self.yOffset = savedOffsets.y;
            }
            
        }
        else
        {
            self.spatialBase = nil;
        }
        
	}
    return self;
}

// Initialize with an array of TimeCodedDataPoints
-(id)initWithDataPointArray:(NSArray*)data
{
	self = [super initWithDataPointArray:data];
	if (self != nil) {
		if(([data count] > 0)
		   && !([[data objectAtIndex:0] isKindOfClass:[TimeCodedSpatialPoint class]]))
		{
			[self release];
			return nil;
		}
		else
		{
			[self setColor:nil];
        
            self.spatialBase = nil;
            
			maxX = - FLT_MAX;
			maxY = - FLT_MAX;
			minX = FLT_MAX;
			minY = FLT_MAX;
			
			for(TimeCodedSpatialPoint* dataPoint in data)
			{
				maxX = fmax(maxX,[dataPoint x]);
				maxY = fmax(maxY,[dataPoint y]);
				minX = fmin(minX,[dataPoint x]);
				minY = fmin(minY,[dataPoint y]);
			}
			
			
		}
	}
	return self;
}

-(id)initWithXarray:(NSArray*)xArray andYarray:(NSArray*)yArray overRange:(QTTimeRange)timeRange
{
	int numPoints = [xArray count];
	if([yArray count] != numPoints)
	{
		return nil;
	}
	
	double interval = (double)(timeRange.duration.timeValue)/(numPoints - 1);
	
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:numPoints];
	int i;
	for(i = 0; i < numPoints; i++)
	{
		TimeCodedSpatialPoint *dataPoint = [[TimeCodedSpatialPoint alloc] init];
		[dataPoint setX:[[xArray objectAtIndex:i] floatValue]];
		[dataPoint setY:[[yArray objectAtIndex:i] floatValue]];
		[dataPoint setTime:QTMakeTime(i*interval,timeRange.duration.timeScale)];
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
		TimeCodedSpatialPoint *dataPoint = [[TimeCodedSpatialPoint alloc] init];
		[dataPoint setValue:[[row objectAtIndex:1] doubleValue]];
		[dataPoint setTime:QTMakeTimeWithTimeInterval([[row objectAtIndex:0] floatValue])];
		[dataPoint setY:[[row objectAtIndex:2] floatValue]];
		[dataPoint setX:[[row objectAtIndex:3] floatValue]];
		[dataPointArray addObject:dataPoint];
		[dataPoint release];
	}
	return dataPointArray;
}

-(TimeCodedDataPoint*)addPoint:(TimeCodedDataPoint*)point
{	
    if([point isKindOfClass:[TimeCodedSpatialPoint class]])
    {
        TimeCodedSpatialPoint *dataPoint = (TimeCodedSpatialPoint*)[super addPoint:point];;
        
        maxX = fmax(maxX,[dataPoint x]);
        maxY = fmax(maxY,[dataPoint y]);
        minX = fmin(minX,[dataPoint x]);
        minY = fmin(minY,[dataPoint y]);
        
        return dataPoint;
    }
		
	return nil;
}

-(void)removeAllPoints
{
    maxX = - FLT_MAX;
    maxY = - FLT_MAX;
    minX = FLT_MAX;
    minY = FLT_MAX;
    
    [super removeAllPoints];
}

@end
