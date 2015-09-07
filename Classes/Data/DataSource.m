//
//  DataSource.m
//  Annotation
//
//  Created by Adam Fouse on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DataSource.h"
#import "TimeCodedData.h"
#import "TimeSeriesData.h"
#import "NSStringParsing.h"
#import "GeographicTimeSeriesData.h"
#import "SpatialTimeSeriesData.h"
#import "TimeCodedDataPoint.h"
#import "TimeCodedGeographicPoint.h"
#import "TimeCodedString.h"
#import "TimeCodedImageFiles.h"
#import "NSStringFileManagement.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "Annotation.h"
#import "AnnotationSet.h"
#import "AnnotationCategory.h"
#import "NSStringUUID.h"
#import "NSStringTimeCodes.h"
#import "DPConstants.h"

NSString * const DataSourceUpdatedNotification = @"DataSourceUpdatedNotification";
NSString * const DPDataSetAddedNotification = @"DPDataSetAddedNotification";
NSString * const DPDataSetRemovedNotification = @"DPDataSetRemovedNotification";

NSString * const DataTypeTimeSeries = @"Time Series";
NSString * const DataTypeGeographicLat = @"Geographic Latitude";
NSString * const DataTypeGeographicLon = @"Geographic Longitude";
NSString * const DataTypeImageSequence = @"Image Sequence";
NSString * const DataTypeAnnotationTime = @"Annotation Start Time";
NSString * const DataTypeAnnotationEndTime = @"Annotation End Time";
NSString * const DataTypeAnnotationTitle = @"Annotation Title";
NSString * const DataTypeAnnotationCategory = @"Annotation Category";
NSString * const DataTypeAnnotation = @"Annotation";
NSString * const DataTypeAnotoTraces = @"Anoto Traces";
NSString * const DataTypeAudio = @"Audio";
NSString * const DataTypeTranscript = @"Transcript";
NSString * const DataTypeSpatialX = @"Spatial X";
NSString * const DataTypeSpatialY = @"Spatial Y";

@interface DataSource (TimeCoding)

- (NSTimeInterval)timeForCodedString:(NSString*)timeString;

-(GeographicTimeSeriesData*)geographicTimeSeriesDataFromLatColumn:(NSUInteger)latIndex andLonColumn:(NSUInteger)lonIndex;
-(SpatialTimeSeriesData*)spatialTimeSeriesDataFromXColumn:(NSUInteger)xColumn andYColumn:(NSUInteger)yColumn;
-(AnnotationSet*)annotationSetFromAnnotationColumn:(NSInteger)textIndex titleColumn:(NSInteger)titleIndex endTimeColumn:(NSInteger)endIndex categoryColumn:(NSInteger)categoryIndex;
-(TimeCodedImageFiles*)imageSequenceFromColumn:(NSUInteger)columnIndex;

@end

@implementation DataSource

@synthesize uuid;
@synthesize predefinedTimeCode;
@synthesize absoluteTime;
@synthesize name;
@synthesize timeCoded;
@synthesize timeColumn;
@synthesize imported;
@synthesize directoryDataFile;
@synthesize linkedVariables;
@synthesize local;

+(NSString*)dataTypeName
{
	return @"CSV";
}

+(NSString*)defaultsIdentifier
{
	return [self dataTypeName];
}

+(BOOL)validateFileName:(NSString*)fileName
{
	return ([[fileName pathExtension] caseInsensitiveCompare:@"csv"] == NSOrderedSame);
}


-(id)initWithPath:(NSString*)theFile
{
	self = [super init];
	if (self != nil) {
		delegate = nil;
		dataArray = nil;
		self.imported = NO;
        self.local = NO;
		self.absoluteTime = NO;
		self.predefinedTimeCode = NO;
		dataFile = [theFile retain];
		dataSets = [[NSMutableArray alloc] init];
        linkedVariables = [[NSMutableDictionary alloc] init];
		timeColumn = 0;
		timeCoding = DataPrismTimeCodingFloat;
		range = QTMakeTimeRange(QTZeroTime, QTZeroTime);
		self.directoryDataFile = NO;
		[self setName:[theFile lastPathComponent]];
		uuid = [[NSString stringWithUUID] retain];
	}
	return self;
}

- (void) dealloc
{
	[uuid release];
	[dataFile release];
	[dataSets release];
    [linkedVariables release];
	[dataArray release];
	[name release];
	[super dealloc];
}

-(NSArray*)possibleDataTypes
{
	return [NSArray arrayWithObjects:
			DataTypeTimeSeries,
			DataTypeGeographicLat,
			DataTypeGeographicLon,
			DataTypeSpatialX,
			DataTypeSpatialY,
			DataTypeImageSequence,
			DataTypeAnnotationEndTime,
			DataTypeAnnotationTitle,
			DataTypeAnnotationCategory,
			DataTypeAnnotation,
			nil];
}

-(NSArray*)variables
{
	NSArray *data = [self dataArray];
	if(data && [data count])
	{
		return [data objectAtIndex:0];	
	}
	else
	{
		return [NSArray array];
	}
}

-(NSArray*)defaultVariablesToImport
{
	return [NSArray array];
}

-(NSString*)defaultDataType:(NSString*)variableName
{
	if([[self possibleDataTypes] containsObject:DataTypeGeographicLat]
	   && (([variableName rangeOfString:@"latitude" options:NSCaseInsensitiveSearch].location != NSNotFound)
           || ([variableName caseInsensitiveCompare:@"lat"] == NSOrderedSame))
       )
	{
		return DataTypeGeographicLat;
	}
	else if([[self possibleDataTypes] containsObject:DataTypeGeographicLon]
			&& (([variableName rangeOfString:@"longitude" options:NSCaseInsensitiveSearch].location != NSNotFound)
                || ([variableName caseInsensitiveCompare:@"lon"] == NSOrderedSame))
            )
	{		
		return DataTypeGeographicLon;
	}
	else if([[self possibleDataTypes] containsObject:DataTypeAnnotation]
			&& ([variableName rangeOfString:@"annotation" options:NSCaseInsensitiveSearch].location != NSNotFound))
	{		
		return DataTypeAnnotation;
	}
    else if([[self possibleDataTypes] containsObject:DataTypeSpatialX]
			&& ([variableName characterAtIndex:([variableName length] - 1)] == 'X'))
	{		
		return DataTypeSpatialX;
	}
    else if([[self possibleDataTypes] containsObject:DataTypeSpatialY]
			&& ([variableName characterAtIndex:([variableName length] - 1)] == 'Y'))
	{		
		return DataTypeSpatialY;
	}
	else
	{
		return [[self possibleDataTypes] objectAtIndex:0];
	}
}

-(BOOL)lockedDataType:(NSString*)variableName
{
	return NO;
}

-(NSArray*)importVariables:(NSArray*)variables asTypes:(NSArray*)types
{
	if((range.duration.timeValue == 0) && (![self timeCoded]))
	{
		range = QTMakeTimeRange(QTZeroTime,[[[AnnotationDocument currentDocument] movie] duration]);
	}
	
	NSMutableArray *newDataSets = [NSMutableArray array];
	
	NSString *geographicLat = nil;
	NSString *geographicLon = nil;
	
	NSString *spatialX = nil;
	NSString *spatialY = nil;
	
	NSString *annotationsText = nil;
	NSString *annotationsTime = nil;
	NSString *annotationsTitle = nil;
	NSString *annotationsCategory = nil;
	
	NSUInteger index;
	for(index = 0; index < [variables count]; index++)
	{
		NSString *variable = [variables objectAtIndex:index];
		NSString *type = [types objectAtIndex:index];
		
		BOOL alreadyIn = NO;
		
		// If this dataSet has already been imported, don't import it again
		for(TimeCodedData *dataSet in dataSets)
		{
			if([variable isEqualToString:[dataSet variableName]])
			{
				[newDataSets addObject:variable];
				alreadyIn = YES;
				break;
			}
		}
		
		if(!alreadyIn)
		{
			if([type isEqualToString:DataTypeTimeSeries])
			{
				NSUInteger index = [[dataArray objectAtIndex:0] indexOfObject:variable];
				[newDataSets addObject:[self timeSeriesDataFromColumn:index]];
				[[newDataSets lastObject] setVariableName:variable];
			}
            else if([type isEqualToString:DataTypeImageSequence])
			{
				NSUInteger index = [[dataArray objectAtIndex:0] indexOfObject:variable];
				[newDataSets addObject:[self imageSequenceFromColumn:index]];
				[[newDataSets lastObject] setVariableName:variable];
			}
			else if([type isEqualToString:DataTypeGeographicLat])
			{
				geographicLat = variable;
			}
			else if([type isEqualToString:DataTypeGeographicLon])
			{
				geographicLon = variable;
			}
			else if([type isEqualToString:DataTypeSpatialX])
			{
				spatialX = variable;
			}
			else if([type isEqualToString:DataTypeSpatialY])
			{
				spatialY = variable;
			}
			else if([type isEqualToString:DataTypeAnnotationTitle])
			{
				annotationsTitle = variable;
			}
			else if([type isEqualToString:DataTypeAnnotationCategory])
			{
				annotationsCategory = variable;
			}
			else if([type isEqualToString:DataTypeAnnotationEndTime])
			{
				annotationsTime = variable;
			}
			else if([type isEqualToString:DataTypeAnnotation])
			{
				if(annotationsText)
				{
					NSUInteger index = [[dataArray objectAtIndex:0] indexOfObject:variable];
					[newDataSets addObject:[self annotationSetFromAnnotationColumn:index titleColumn:-1 endTimeColumn:-1 categoryColumn:-1]];
					[[newDataSets lastObject] setVariableName:variable];
				}
				else
				{
					annotationsText = variable;
				}
			}
			
			if(geographicLat && geographicLon)
			{
				NSUInteger latIndex = [[dataArray objectAtIndex:0] indexOfObject:geographicLat];
				NSUInteger lonIndex = [[dataArray objectAtIndex:0] indexOfObject:geographicLon];
				[newDataSets addObject:[self geographicTimeSeriesDataFromLatColumn:latIndex andLonColumn:lonIndex]];
				[[newDataSets lastObject] setVariableName:geographicLat];
				[[newDataSets lastObject] setLonVariableName:geographicLon];
                
                NSArray *variablesArray = [[NSArray alloc] initWithObjects:geographicLat,geographicLon, nil];
                [linkedVariables setObject:variablesArray forKey:geographicLat];
                [linkedVariables setObject:variablesArray forKey:geographicLon];
                [variablesArray release];
                
				geographicLat = nil;
				geographicLon = nil;
                
			} else if(geographicLat || geographicLon)
			{
				[newDataSets addObject:[NSNull null]];
			}
			
			if(spatialX && spatialY)
			{
				NSUInteger xIndex = [[dataArray objectAtIndex:0] indexOfObject:spatialX];
				NSUInteger yIndex = [[dataArray objectAtIndex:0] indexOfObject:spatialY];
				[newDataSets addObject:[self spatialTimeSeriesDataFromXColumn:xIndex andYColumn:yIndex]];
				[[newDataSets lastObject] setVariableName:spatialX];
                
                NSArray *variablesArray = [[NSArray alloc] initWithObjects:spatialX,spatialY, nil];
                [linkedVariables setObject:variablesArray forKey:spatialX];
                [linkedVariables setObject:variablesArray forKey:spatialY];
                [variablesArray release];
                
				spatialX = nil;
				spatialY = nil;
			} else if(spatialX || spatialY)
			{
				[newDataSets addObject:[NSNull null]];
			}
		}
	}
	
	if(annotationsTitle || annotationsTime || annotationsText)
	{
        NSMutableArray *variablesArray = [[NSMutableArray alloc] init];
        
		NSInteger titleIndex = -1;
		NSInteger textIndex = -1;
		NSInteger endIndex = -1;
		NSInteger categoryIndex = -1;
		if(annotationsTitle)
		{
			titleIndex = [[dataArray objectAtIndex:0] indexOfObject:annotationsTitle];
            [variablesArray addObject:annotationsTitle];
            [linkedVariables setObject:variablesArray forKey:annotationsTitle];
		}
		if(annotationsText)
		{
			textIndex = [[dataArray objectAtIndex:0] indexOfObject:annotationsText];
            [variablesArray addObject:annotationsText];
            [linkedVariables setObject:variablesArray forKey:annotationsText];
		}
		if(annotationsTime)
		{
			endIndex = [[dataArray objectAtIndex:0] indexOfObject:annotationsTime];
            [variablesArray addObject:annotationsTime];
            [linkedVariables setObject:variablesArray forKey:annotationsTime];
		}
		if(annotationsCategory)
		{
			categoryIndex = [[dataArray objectAtIndex:0] indexOfObject:annotationsCategory];
            [variablesArray addObject:annotationsCategory];
            [linkedVariables setObject:variablesArray forKey:annotationsCategory];
		}
		
		AnnotationSet *annotationSet = [self annotationSetFromAnnotationColumn:textIndex 
																   titleColumn:titleIndex 
																 endTimeColumn:endIndex
																categoryColumn:categoryIndex];
		
		if(annotationsTitle)
		{
			[annotationSet setVariableName:annotationsTitle];
		}
		if(annotationsText)
		{
			[annotationSet setVariableName:annotationsText];
		}
		
		[newDataSets insertObject:annotationSet atIndex:0];
		
        [variablesArray release];

	}
	
	return newDataSets;
}


-(void)load
{
    
}

-(void)reset
{
	if([dataSets count] > 0)
	{
		NSArray *sets = [dataSets copy];
		for(TimeCodedData *data in sets)
		{
			[self removeDataSet:data];
		}
        [sets release];
	}
	
	range = QTMakeTimeRange(QTZeroTime, QTZeroTime); 
}

-(void)addDataSet:(TimeCodedData*)dataSet
{
	[dataSets addObject:dataSet];
	[dataSet setSource:self];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:DataSetsChangedNotification object:self];
}

-(void)removeDataSet:(TimeCodedData*)dataSet
{
	if([dataSets containsObject:dataSet])
	{
        NSArray *linked = [linkedVariables objectForKey:[dataSet variableName]];
        [linkedVariables removeObjectsForKeys:linked];
        
		[dataSet setSource:nil];
		[dataSets removeObject:dataSet];
		[[[AppController currentApp] viewManager] removeData:dataSet];
	}
}

-(NSArray*)dataArray
{
	if(!dataArray)
	{
		NSError* error;
		if(![dataFile fileExists])
		{
			dataFile = [[dataFile stringByAskingForReplacement] retain];
			[[AppController currentDoc] saveData];
		}
		
		BOOL showProgress = NO;
		if([[[NSFileManager defaultManager] attributesOfItemAtPath:dataFile error:&error] fileSize] > 1000000)
		{
			showProgress = YES;
			[delegate dataSourceLoadStart];
			[delegate dataSourceLoadStatus:0.0];
		}
		
		NSString *dataString = [[NSString alloc] initWithContentsOfFile:dataFile encoding:NSUTF8StringEncoding error:&error];
		if(!dataString)
		{
			NSLog(@"Error loading data: %@",[error localizedDescription]);
			return nil;
		}
		
		if(showProgress)
		{
			[delegate dataSourceLoadStatus:0.1];
			[self setDataArray:[dataString csvRowsWithDelegate:delegate]];
			[delegate dataSourceLoadStatus:0.9];
		}
		else
		{
			[self setDataArray:[dataString csvRows]];
		}
		
		
        if(!imported)
        {
            NSUInteger column = 0;
            BOOL foundTime = NO;
            for(NSString* title in [[self dataArray] objectAtIndex:0])
            {
                NSLog(@"Title: %@",title);
                if(([title caseInsensitiveCompare:@"time"] == NSOrderedSame)
                   || ([title caseInsensitiveCompare:@"StartTime"] == NSOrderedSame)
                   || ([title caseInsensitiveCompare:@"timestamp"] == NSOrderedSame))
                {
                    [self setTimeColumn:column];
                    [self setTimeCoded:YES];
                    foundTime = YES;
                    break;
                }
                column++;
            }
            
            if(!foundTime)
            {
                [self setTimeColumn:0];
                [self setTimeCoded:YES];
                //range = QTMakeTimeRange(QTZeroTime,[[[AnnotationDocument currentDocument] movie] duration]);
            }
        }
		
		[dataString release];
		
		if(showProgress)
		{
			[delegate dataSourceLoadStatus:1.0];
			[delegate dataSourceLoadFinished];
		}
	}
	return dataArray;
}

-(void)setDataArray:(NSArray*)array
{
	[array retain];
	[dataArray release];
	dataArray = array;
}

-(QTTime)timeForRowArray:(NSArray*)row;
{
	// Cases:
	// - Relative Time:
	// --- Decimal
	// --- HH:MM:SS.s
	// - Absolute Time:
	// --- Date Column + Time Column
	// ----- YYMMDD + HHMMSS
	// ----- DD/MM/YY + HH:MM:SS
	// --- DateTime Column
	
	long timeScale;
	if(range.duration.timeValue == 0)
	{
		NSTimeInterval initialOffset = -[self timeForCodedString:[[dataArray objectAtIndex:1] objectAtIndex:timeColumn]];
		timeEncodingOffset = QTMakeTimeWithTimeInterval(initialOffset);
		if(!absoluteTime)
		{
			timeEncodingOffset.timeValue = 0;
		}
		timeScale = timeEncodingOffset.timeScale;
		
		range.time = QTMakeTime(0, timeScale);
		
		NSTimeInterval last = [self timeForCodedString:[[dataArray lastObject] objectAtIndex:timeColumn]];
		
		int index = [dataArray count] - 1;
		while(last == 0)
		{
			last = [self timeForCodedString:[[dataArray objectAtIndex:index] objectAtIndex:timeColumn]];
			index--;
		}
		
		QTTime duration = QTMakeTime(timeEncodingOffset.timeValue + (last * timeScale), timeScale);
		
		range.duration = duration;
	}
	NSString *timeString = [row objectAtIndex:timeColumn];
	if([timeString length] == 0)
	{
		return QTIndefiniteTime;
	}
	else {
		double relativeTime = [self timeForCodedString:timeString];
		QTTime relativeQTTime = QTMakeTimeWithTimeInterval(relativeTime);
		QTTime totalOffset = QTTimeIncrement(timeEncodingOffset,range.time);
		return QTTimeIncrement(totalOffset,relativeQTTime);
	}
}

- (NSTimeInterval)timeForCodedString:(NSString*)timeString
{	
	if(absoluteTime)
	{
		NSRange theRange;
		theRange.location = 0;
		theRange.length = 2;
		
		int hours = [[timeString substringWithRange:theRange] intValue];
		theRange.location = 2;
		int minutes = [[timeString substringWithRange:theRange] intValue];
		theRange.location = 4;
		int seconds = [[timeString substringWithRange:theRange] intValue];
		
		return ((hours * 60.0 * 60.0) + (minutes * 60.0) + seconds);
	}
	else
	{
        return [timeString timeInterval];
	}
}

#pragma mark Data Set Importing

-(AnnotationSet*)annotationSetFromAnnotationColumn:(NSInteger)textIndex
									   titleColumn:(NSInteger)titleIndex 
									 endTimeColumn:(NSInteger)endIndex
									 categoryColumn:(NSInteger)categoryIndex
{
	AnnotationSet *annotationSet = [[AnnotationSet alloc] init];
	
	NSTimeInterval relativeTime = 0;
	
	BOOL keep = NO;
	
	for(NSArray *row in dataArray)
	{
		if(row != [dataArray objectAtIndex:0])
		{
			QTTime time = [self timeForRowArray:row];
			if(!QTTimeIsIndefinite(time))
			{
				Annotation *annotation = [[Annotation alloc] initWithQTTime:[self timeForRowArray:row]];
				[annotation setSource:[self uuid]];
				keep = NO;
				
				if(titleIndex > -1)
				{
					NSString *entry = [row objectAtIndex:titleIndex];
					if([entry length] > 0)
					{
						[annotation setTitle:entry];
						keep = YES;
					}
				}
				
				if((textIndex > -1) && ([row count] > textIndex))
				{
					NSString *entry = [row objectAtIndex:textIndex];
					if([entry length] > 0)
					{
						[annotation setAnnotation:entry];	
						keep = YES;
					}
				}

				if((endIndex > -1) && (![[row objectAtIndex:timeColumn] isEqualToString:[row objectAtIndex:endIndex]]))
				{
					[annotation setIsDuration:YES];
					relativeTime = [self timeForCodedString:[row objectAtIndex:endIndex]];
					[annotation setEndTime:QTMakeTime(timeEncodingOffset.timeValue + (relativeTime * timeEncodingOffset.timeScale), timeEncodingOffset.timeScale)];
				}
				
				if((categoryIndex > -1) && ([row count] > categoryIndex))
				{
					NSString *categoryName = [row objectAtIndex:categoryIndex];
					AnnotationCategory *category = [[AnnotationDocument currentDocument] categoryForIdentifier:categoryName];
					if(!category)
					{
						category = [[AnnotationDocument currentDocument] createCategoryForIdentifier:categoryName];
						[category autoColor];
					}
					[annotation addCategory:category];
				}
				
				if(keep)
				{
					[annotationSet addAnnotation:annotation];
				}
				
				[annotation release];
			}
		}
	}
	
	[annotationSet setUseNameAsCategory:YES];
	
	[dataSets addObject:annotationSet];
	[annotationSet setSource:self];
	[annotationSet release];
	
	return annotationSet;
}

-(TimeSeriesData*)timeSeriesDataFromColumn:(NSUInteger)columnIndex
{
	if(timeCoded)
	{
		NSMutableArray *timeSeriesData = [NSMutableArray arrayWithCapacity:[dataArray count]];
		
        id val = nil;
        //NSUInteger columns = [[dataArray objectAtIndex:0] count];
        NSUInteger columns = columnIndex;
        
		for(NSArray *row in dataArray)
		{
			if((row != [dataArray objectAtIndex:0]) && ([row count] > columns))
			{
                val = [row objectAtIndex:columnIndex];
                if(val && (val != [NSNull null]))
				{
                    if(![val isKindOfClass:[NSString class]] || ([val length] > 0))
                    {
                        TimeCodedDataPoint *dataPoint = [[TimeCodedDataPoint alloc] init];
                        [dataPoint setValue:[val doubleValue]];
                        [dataPoint setTime:[self timeForRowArray:row]];
                        [timeSeriesData addObject:dataPoint];
                        [dataPoint release];
                    }
				}
			}
		}
		
		TimeSeriesData *timeSeries = [[TimeSeriesData alloc] initWithDataPointArray:timeSeriesData];
		[dataSets addObject:timeSeries];
		[timeSeries setSource:self];
		[timeSeries release];

		return timeSeries;
	}
	else
	{
		NSMutableArray *timeSeriesData = [NSMutableArray arrayWithCapacity:[dataArray count]];
		
		for(NSArray *row in dataArray)
		{
			if(row != [dataArray objectAtIndex:0])
			{
				if([row objectAtIndex:columnIndex] != [NSNull null])
				{
					[timeSeriesData addObject:[NSNumber numberWithDouble:[[row objectAtIndex:columnIndex] doubleValue]]];
				}
			}
		}
		
		TimeSeriesData *timeSeries = [[TimeSeriesData alloc] initWithDataPoints:timeSeriesData overRange:[self range]];
		[dataSets addObject:timeSeries];
		[timeSeries setSource:self];
		[timeSeries release];
		
		return timeSeries;
	}
}

-(SpatialTimeSeriesData*)spatialTimeSeriesDataFromXColumn:(NSUInteger)xColumn andYColumn:(NSUInteger)yColumn
{
	NSMutableArray *timeSeriesData = [NSMutableArray arrayWithCapacity:[dataArray count]];
	
    id xVal = nil;
    
    //NSUInteger columns = [[dataArray objectAtIndex:0] count];
    NSUInteger columns = fmax(xColumn,yColumn);
    
    
	for(NSArray *row in dataArray)
	{
		if((row != [dataArray objectAtIndex:0]) && ([row count] > columns))
		{
            xVal = [row objectAtIndex:xColumn];
			if(xVal && (xVal != [NSNull null]) && ([xVal length] > 0))
			{
				TimeCodedSpatialPoint *dataPoint = [[TimeCodedSpatialPoint alloc] init];

				[dataPoint setX:[[row objectAtIndex:xColumn] floatValue]];
				[dataPoint setY:[[row objectAtIndex:yColumn] floatValue]];
				[dataPoint setValue:1.0];
                
                if((dataPoint.x == 0) || (dataPoint.y == 0))
                {
                    //NSLog(@"Zero point");
                }
                
				[dataPoint setTime:[self timeForRowArray:row]];
				[timeSeriesData addObject:dataPoint];	

				[dataPoint release];		
			}
		}
	}
	
	SpatialTimeSeriesData *timeSeries = [[SpatialTimeSeriesData alloc] initWithDataPointArray:timeSeriesData];
	[dataSets addObject:timeSeries];
	[timeSeries setSource:self];
	[timeSeries release];
	
	return timeSeries;
}

-(GeographicTimeSeriesData*)geographicTimeSeriesDataFromLatColumn:(NSUInteger)latColumn andLonColumn:(NSUInteger)lonColumn
{
	NSMutableArray *timeSeriesData = [NSMutableArray arrayWithCapacity:[dataArray count]];
	
	//First, determine coordinate encoding
	BOOL cardinalEncoding = NO;
	NSCharacterSet *nsCharacters = [NSCharacterSet characterSetWithCharactersInString:@"NSns"];
	NSCharacterSet *ewCharacters = [NSCharacterSet characterSetWithCharactersInString:@"EWew"];
	for(NSArray *row in dataArray)
	{
		if(row != [dataArray objectAtIndex:0] && ([row objectAtIndex:latColumn] != [NSNull null]))
		{
			NSString *latValue = [row objectAtIndex:latColumn];
			NSString *lonValue = [row objectAtIndex:lonColumn];
			
			if([latValue isKindOfClass:[NSString class]]
			   && ([latValue rangeOfCharacterFromSet:nsCharacters].location != NSNotFound)
			   && ([lonValue rangeOfCharacterFromSet:ewCharacters].location != NSNotFound))
			{
				cardinalEncoding = YES;
			}
			break;
		}
	}
	
	NSString *latValue;
	NSString *lonValue;
	NSRange latCardinalRange;
	NSRange lonCardinalRange;
	float latSign = 1;
	float lonSign = 1;
	
	for(NSArray *row in dataArray)
	{
		if(row != [dataArray objectAtIndex:0])
		{
			if([row objectAtIndex:latColumn] != [NSNull null])
			{
				TimeCodedGeographicPoint *dataPoint = [[TimeCodedGeographicPoint alloc] init];
				if(cardinalEncoding)
				{
					latValue = [row objectAtIndex:latColumn];
					lonValue = [row objectAtIndex:lonColumn];
					latCardinalRange = [latValue rangeOfCharacterFromSet:nsCharacters];
					lonCardinalRange = [lonValue rangeOfCharacterFromSet:ewCharacters];
					if([[latValue substringWithRange:latCardinalRange] caseInsensitiveCompare:@"S"] == NSOrderedSame)
					{
						latSign = -1;
					}
					if([[lonValue substringWithRange:lonCardinalRange] caseInsensitiveCompare:@"W"] == NSOrderedSame)
					{
						lonSign = -1;
					}
					latValue = [latValue stringByTrimmingCharactersInSet:nsCharacters];
					lonValue = [lonValue stringByTrimmingCharactersInSet:ewCharacters];
					[dataPoint setLat:(latSign * [latValue floatValue])];
					[dataPoint setLon:(lonSign * [lonValue floatValue])];
				}
				else
				{
					[dataPoint setLat:[[row objectAtIndex:latColumn] floatValue]];
					[dataPoint setLon:[[row objectAtIndex:lonColumn] floatValue]];
				}
				
				if(([dataPoint lat] != 0) && ([dataPoint lon] != 0))
				{
					[dataPoint setTime:[self timeForRowArray:row]];
					[timeSeriesData addObject:dataPoint];	
				}
				
				[dataPoint release];		
			}
		}
	}
	
	GeographicTimeSeriesData *timeSeries = [[GeographicTimeSeriesData alloc] initWithDataPointArray:timeSeriesData];
	[dataSets addObject:timeSeries];
	[timeSeries setSource:self];
	[timeSeries release];
	
	return timeSeries;
}

-(TimeCodedImageFiles*)imageSequenceFromColumn:(NSUInteger)columnIndex
{
    NSArray* data = [self dataArray];
	
	NSMutableArray *pictureFileArray = [NSMutableArray array];
	
    id imgFile = nil;
    
    NSUInteger columns = [[dataArray objectAtIndex:0] count];
    
	for(NSArray* row in data)
	{
        if((row != [dataArray objectAtIndex:0]) && ([row count] == columns))
		{
            imgFile = [row objectAtIndex:columnIndex];
			if(imgFile && (imgFile != [NSNull null]) && ([imgFile length] > 0))
			{
                NSString *pictureFile = [[dataFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:imgFile];
                
                if([pictureFile fileExists])
                {
                    TimeCodedString *picture = [[TimeCodedString alloc] init];
                    [picture setValue:0];
                    [picture setTime:[self timeForRowArray:row]];
                    //[picture setString:pictureFile];
                    [picture setString:imgFile];
                    
                    [pictureFileArray addObject:picture];
                    
                    [picture release];
                }
            }
		}
	}

    
    TimeCodedImageFiles* images = [[TimeCodedImageFiles alloc] initWithDataPointArray:pictureFileArray];
    [images setRelativeToSource:YES];
    [dataSets addObject:images];
    [images setSource:self];
    [images release];
    
    return images;

}

#pragma mark Time Coding

-(NSDate*)startDate
{
	return nil;
}

-(void)setRange:(QTTimeRange)newRange
{
	if(timeCoded)
	{
		
		QTTime previousDiff = range.time;
		QTTime diff = newRange.time;
		
		//[super setRange:newRange];
		
		for(TimeCodedData *data in dataSets)
		{
			if([data isKindOfClass:[TimeSeriesData class]])
			{
				[(TimeSeriesData*)data shiftByTime:QTTimeDecrement(newRange.time, range.time)];
			}
			else if ([data isKindOfClass:[AnnotationSet class]])
			{
				NSArray *annotations = [(AnnotationSet*)data annotations];
				for(Annotation *annotation in annotations)
				{
					[annotation setStartTime:QTTimeIncrement(QTTimeDecrement([annotation startTime],previousDiff), diff)];
					if([annotation isDuration])
					{
						[annotation setEndTime:QTTimeIncrement(QTTimeDecrement([annotation endTime],previousDiff), diff)];
					}
					
				}	
			}
		}
		
		range = newRange;
		
		
	}
	else
	{
		range = newRange;
		for(TimeSeriesData *data in dataSets)
		{
			[data scaleToRange:newRange];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:DPDataSetRangeChangeNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:DataSourceUpdatedNotification object:self];
}

-(QTTimeRange)range
{
	return range;
}

-(NSString*)dataFile
{
	return dataFile;
}

-(void)setDataFile:(NSString*)theDataFile
{
	[dataFile release];
	dataFile = [theDataFile copy];
}

-(NSArray*)dataSets
{
	return [[dataSets copy] autorelease];
}

-(void)addAnnotation:(Annotation*)annotation
{
	
}

#pragma mark File Coding

- (void)encodeWithCoder:(NSCoder *)coder
{
	//NSString *altColon = @"⁚";
	[coder encodeObject:uuid forKey:@"AnnotationDataSourceUUID"];
	[coder encodeObject:dataFile forKey:@"AnnotationDataSourceFile"];
	[coder encodeQTTimeRange:range forKey:@"AnnotationDataSourceRange"];
	[coder encodeBool:timeCoded forKey:@"AnnotationDataSourceTimeCoded"];
	[coder encodeBool:absoluteTime forKey:@"AnnotationDataSourceAbsoluteTime"];
	[coder encodeInteger:timeColumn forKey:@"AnnotationDataSourceTimeColumn"];
	[coder encodeObject:dataSets forKey:@"AnnotationDataSourceDataSets"];
    [coder encodeObject:linkedVariables forKey:@"AnnotationDataSourceLinkedVariables"];
	[coder encodeObject:name forKey:@"AnnotationDataSourceName"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
		uuid = [[coder decodeObjectForKey:@"AnnotationDataSourceUUID"] retain];
		if(!uuid)
		{
			uuid = [[NSString stringWithUUID] retain];
		}
		
		dataFile = [[coder decodeObjectForKey:@"AnnotationDataSourceFile"] retain];
		range = [coder decodeQTTimeRangeForKey:@"AnnotationDataSourceRange"];
		timeCoded = [coder decodeBoolForKey:@"AnnotationDataSourceTimeCoded"];
		absoluteTime = [coder decodeBoolForKey:@"AnnotationDataSourceAbsoluteTime"];
		timeColumn = [coder decodeIntegerForKey:@"AnnotationDataSourceTimeColumn"];
		dataSets = [[coder decodeObjectForKey:@"AnnotationDataSourceDataSets"] retain];
        
        linkedVariables = [[coder decodeObjectForKey:@"AnnotationDataSourceLinkedVariables"] retain];
        if(!linkedVariables)
        {
            linkedVariables = [[NSMutableDictionary alloc] init];
        }
        
		NSTimeInterval start;
		QTGetTimeInterval(range.time, &start);
		//NSLog(@"Init data set: %@ Range Start: %f",dataFile,start);
		
		dataArray = nil;
		
		name = [[coder decodeObjectForKey:@"AnnotationDataSourceName"] retain];
		
		if(!name)
		{
			[self setName:[dataFile lastPathComponent]];
		}
        
        imported = YES;
		
	}
    return self;
}

#pragma mark Delegate

- (NSObject<DataSourceDelegate>*)delegate
{
	return delegate;
}

- (void)setDelegate:(NSObject<DataSourceDelegate>*)new_delegate
{
	delegate = new_delegate;
}

@end
