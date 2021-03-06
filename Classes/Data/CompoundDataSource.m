//
//  CompoundDataSource.m
//  ChronoViz
//
//  Created by Adam Fouse on 7/12/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "CompoundDataSource.h"
#import "DPConstants.h"

@interface CompoundDataSource (Updating)

-(void)updateRange:(NSNotification*)notification;
-(void)setRange:(QTTimeRange)newRange fromSource:(DataSource*)dataSource;

@end

@implementation CompoundDataSource

+(NSString*)dataTypeName
{
	return @"Compound Data Source";
}


+(BOOL)validateFileName:(NSString*)fileName
{
	return NO;
}

- (id) init
{
	return [self initWithPath:@""];
}


-(id)initWithPath:(NSString*)theFile
{
	self = [super initWithPath:@""];
	if (self != nil) {
		[self setPredefinedTimeCode:YES];
		[self setTimeCoded:YES];
		dataSources = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:dataSources forKey:@"AnnotationDataSourceCompoundArray"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		dataSources = [[coder decodeObjectForKey:@"AnnotationDataSourceCompoundArray"] retain];
	}
    return self;
}


- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[dataSources release];
	[super dealloc];
}

- (void)addDataSource:(DataSource*)source
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateRange:)
												 name:DataSourceUpdatedNotification
											   object:source];
	[dataSources addObject:source];
	
	if([dataSources count] == 1)
	{
		range = [source range];
	}
	else
	{
		QTTimeRange sourceRange = [source range];
		
		QTTime sourceRangeEnd = QTTimeRangeEnd(sourceRange);
		
		if(QTTimeCompare(sourceRange.time, range.time) == NSOrderedAscending)
		{
			range.time = sourceRange.time;
		}
		
		if(QTTimeCompare(QTTimeRangeEnd(range),sourceRangeEnd) == NSOrderedAscending)
		{
			range.duration = QTTimeDecrement(sourceRangeEnd, range.time);
		}	
	}
}

- (void)removeDataSource:(DataSource*)source
{
	[dataSources removeObject:source];
}

-(void)updateRange:(NSNotification*)notification
{
	DataSource *source = [notification object];
	[self setRange:[source range] fromSource:source];
}
			
-(void)setRange:(QTTimeRange)newRange
{
	[self setRange:newRange fromSource:nil];
}

-(void)setRange:(QTTimeRange)newRange fromSource:(DataSource*)dataSource
{
	QTTime diff = QTTimeDecrement(newRange.time, range.time);
	for(DataSource *source in dataSources)
	{
		if((source != dataSource) && [source isKindOfClass:[DataSource class]])
		{
			QTTimeRange oldRange = [source range];
			oldRange.time = QTTimeIncrement(oldRange.time, diff);
			[source setRange:oldRange];
		}
	}
	range.time = newRange.time;
	[[NSNotificationCenter defaultCenter] postNotificationName:DPDataSetRangeChangeNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:DataSourceUpdatedNotification object:self];
}

- (NSArray*)dataSources
{
	return [[dataSources copy] autorelease];
}

-(NSArray*)dataSets
{
	NSMutableArray *allSets = [NSMutableArray array];
	for(DataSource* source in dataSources)
	{
		[allSets addObjectsFromArray:[source dataSets]];
	}
	return allSets;
}

-(NSArray*)possibleDataTypes
{
	return [NSArray array];
}

-(NSArray*)importVariables:(NSArray*)variables asTypes:(NSArray*)types
{
	return [NSArray array];
}

-(QTTime)timeForRowArray:(NSArray*)row;
{
	return QTZeroTime;
}

-(NSArray*)dataArray
{
	if(!dataArray)
	{
		[self setDataArray:[NSArray array]];
	}
	return dataArray;
}


@end
