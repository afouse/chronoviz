//
//  TimeSeriesData.h
//  Annotation
//
//  Created by Adam Fouse on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "TimeCodedData.h"
@class DataSource;
@class TimeCodedDataPoint;

int afTimeCodedPointSort( id obj1, id obj2, void *context );

@interface TimeSeriesData : TimeCodedData {
	
	NSMutableArray *dataPoints;
	
	double maxValue;
	double minValue;
	double mean;
    double intervalMode;
	
}

// Initialize with an array of TimeCodedDataPoints
-(id)initWithDataPointArray:(NSArray*)data;

// Initialize with an array of values evenly distributed over a range
-(id)initWithDataPoints:(NSArray*)values overRange:(CMTimeRange)range;

-(TimeCodedDataPoint*)addPoint:(TimeCodedDataPoint*)point;
-(TimeCodedDataPoint*)addValue:(double)value atTime:(CMTime)time;
-(TimeCodedDataPoint*)addValue:(double)value atSeconds:(NSTimeInterval)seconds;
-(void)addPoints:(NSArray*)timeCodedDataPoints;
-(void)removeAllPoints;

- (void)shiftByTime:(CMTime)diff;

- (void)scaleFromRange:(CMTimeRange)oldRange toRange:(CMTimeRange)newRange;
- (void)scaleToRange:(CMTimeRange)newRange;

- (double)maxValue;
- (double)minValue;
- (double)mean;
- (double)intervalMode;

- (NSArray*)values;
- (NSArray*)dataPoints;
- (NSArray*)subsetOfSize:(NSUInteger)size forRange:(CMTimeRange)subsetRange;

- (NSString*)csvData;
- (NSMutableArray*)dataPointsFromCSVArray:(NSArray*)dataArray;

@end
