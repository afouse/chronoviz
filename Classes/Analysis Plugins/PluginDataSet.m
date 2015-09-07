//
//  PluginDataSet.m
//  DataPrism
//
//  Created by Adam Fouse on 7/22/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "PluginDataSet.h"
#import "TimeSeriesData.h"
#import "TimeCodedData.h"

@implementation PluginDataSet

@synthesize name;
@synthesize defaultVariable;
@synthesize dataSet;

-(NSArray*)dataPoints
{
	if([dataSet isKindOfClass:[TimeSeriesData class]])
	{
		return [(TimeSeriesData*)dataSet dataPoints];
	}
	else
	{
		return [NSArray array];
	}
}

@end
