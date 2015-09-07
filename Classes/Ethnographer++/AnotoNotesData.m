//
//  AnotoNotesData.m
//  DataPrism
//
//  Created by Adam Fouse on 3/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AnotoNotesData.h"
#import "DataSource.h"

@implementation AnotoNotesData


- (NSArray*)traces
{
	if(!traces && [[self source] respondsToSelector:@selector(traces)])
	{
		return [(id)[self source] traces];	
	}
	else
	{
		return traces;
	}
}

- (void)setTraces:(NSMutableArray *)theTraces
{
	[theTraces retain];
	[traces release];
	traces = theTraces;
}

- (QTTimeRange)range
{
	return [source range];
}

@end
