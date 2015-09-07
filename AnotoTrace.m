//
//  AnotoTrace.m
//  DataPrism
//
//  Created by Adam Fouse on 2/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AnotoTrace.h"
#import "TimeCodedPenPoint.h"
#import <QTKit/QTKit.h>

@implementation AnotoTrace

@synthesize page;


-(id)init
{
	return [self initWithDataPointArray:nil];
}

// Initialize with an array of values evenly distributed over a range
-(id)initWithDataPoints:(NSArray*)values overRange:(QTTimeRange)timeRange
{
	return nil;
}

// Initialize with an array of TimeCodedDataPoints
-(id)initWithDataPointArray:(NSArray*)data
{
	self = [super initWithDataPointArray:data];
	if (self != nil) {
		if((data != nil)
		   && !([[data objectAtIndex:0] isKindOfClass:[TimeCodedPenPoint class]]))
		{
			[self release];
			return nil;
		}
		else
		{
			maxX = -CGFLOAT_MAX;
			maxY = -CGFLOAT_MAX;
			minX = CGFLOAT_MAX;
			minY = CGFLOAT_MAX;
			
			for(TimeCodedPenPoint* dataPoint in data)
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

- (void) dealloc
{
	[page release];
	[super dealloc];
}


-(TimeCodedDataPoint*)addPoint:(TimeCodedDataPoint*)point
{
	if([point isKindOfClass:[TimeCodedPenPoint class]])
	{
		TimeCodedPenPoint* penPoint = (TimeCodedPenPoint*)[super addPoint:point];
		maxX = fmax(maxX,[penPoint x]);
		maxY = fmax(maxY,[penPoint y]);
		minX = fmin(minX,[penPoint x]);
		minY = fmin(minY,[penPoint y]);
		return penPoint;
	}
	else
	{
		return nil;
	}
}

- (NSString*)name
{
	return [NSString stringWithFormat:@"Anoto Trace, Page %@",page];
}

- (CGFloat) maxX
{
	return maxX;
}

- (CGFloat) maxY
{
	return maxY;
}

- (CGFloat) minX
{
	return minX;
}

- (CGFloat) minY
{
	return minY;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeFloat:maxX forKey:@"AnnotationDataSetmaxX"];
	[coder encodeFloat:maxY forKey:@"AnnotationDataSetmaxY"];
	[coder encodeFloat:minX forKey:@"AnnotationDataSetminX"];
	[coder encodeFloat:minY forKey:@"AnnotationDataSetminY"];
	[coder encodeObject:page forKey:@"AnnotationDataSetPage"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		maxX = [coder decodeFloatForKey:@"AnnotationDataSetmaxX"];
		maxY = [coder decodeFloatForKey:@"AnnotationDataSetmaxY"];
		minX = [coder decodeFloatForKey:@"AnnotationDataSetminX"];
		minY = [coder decodeFloatForKey:@"AnnotationDataSetminY"];
		[self setPage:[coder decodeObjectForKey:@"AnnotationDataSetPage"]];
	}
    return self;
}


- (NSMutableArray*)dataPointsFromCSVArray:(NSArray*)dataArray
{
	NSMutableArray *dataPointArray = [NSMutableArray arrayWithCapacity:[dataArray count]];
	long timeScale = range.time.timeScale;
	BOOL timeIntervals = ([(NSString*)[[dataArray objectAtIndex:0] objectAtIndex:0] rangeOfString:@"."].location != NSNotFound);
	for(NSArray* row in dataArray)
	{
		TimeCodedPenPoint *dataPoint = [[TimeCodedPenPoint alloc] init];
		[dataPoint setValue:[[row objectAtIndex:1] doubleValue]];
		if(timeIntervals)
		{
			[dataPoint setTime:QTMakeTimeWithTimeInterval([[row objectAtIndex:0] floatValue])];
		}
		else
		{
			[dataPoint setTime:QTMakeTime([[row objectAtIndex:0] longLongValue],timeScale)];
		}
		[dataPoint setX:[[row objectAtIndex:2] integerValue]];
		[dataPoint setY:[[row objectAtIndex:3] integerValue]];
		[dataPoint setForce:[[row objectAtIndex:4] floatValue]];
		[dataPointArray addObject:dataPoint];
		[dataPoint release];
	}
	return dataPointArray;
}

@end
