//
//  ActivityTrailsDataSource.m
//  DataPrism
//
//  Created by Adam Fouse on 1/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ActivityTrailsDataSource.h"
#import "TimeCodedString.h"
#import "TimeCodedImageFiles.h"
#import "TimeCodedData.h"

@interface ActivityTrailsDataSource (Parsing)

- (NSDate*)parseDate:(NSString*)filename;

@end

@implementation ActivityTrailsDataSource

+(NSString*)dataTypeName
{
	return @"ActivityTrails Images";
}

+(BOOL)validateFileName:(NSString*)fileName
{
	return (([[fileName lastPathComponent] rangeOfString:@"AT"].location == 0)
			&& (([[fileName pathExtension] caseInsensitiveCompare:@"jpg"] == NSOrderedSame)
				|| ([[fileName pathExtension] caseInsensitiveCompare:@"png"] == NSOrderedSame)));
}

-(id)initWithPath:(NSString*)directory
{
	
	BOOL isDirectory = NO;
	
	BOOL isFile = [[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDirectory];
	
	if(!isFile)
	{
		[self release];
		return nil;
	}
	
	if(!isDirectory)
		directory = [directory stringByDeletingLastPathComponent];;
	
	self = [super initWithPath:directory];
	
	if (self != nil) {
		[self setPredefinedTimeCode:YES];
		[self setTimeCoded:YES];
		[self setDirectoryDataFile:YES];
		
	}
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

-(NSArray*)possibleDataTypes
{
	return [NSArray arrayWithObjects:
			DataTypeTimeSeries,
			DataTypeImageSequence,
			nil];
}

-(NSArray*)defaultVariablesToImport
{
	return [NSArray arrayWithObject:@"File Name"];
}

-(NSString*)defaultDataType:(NSString*)variableName
{
	if([variableName rangeOfString:@"File" options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		return DataTypeImageSequence;
	}
	else
	{
		return DataTypeTimeSeries;
	}
}

-(NSDate*)startDate
{
	return [[[self dataArray] objectAtIndex:1] objectAtIndex:0];
}

-(QTTime)timeForRowArray:(NSArray*)row;
{
	NSDate *startDate = [[[self dataArray] objectAtIndex:1] objectAtIndex:0];
	NSDate *dataTime = [row objectAtIndex:timeColumn];
	return QTMakeTimeWithTimeInterval([dataTime timeIntervalSinceDate:startDate]);
}

- (NSDate*)parseDate:(NSString*)filename
{
	// AT_screenshot_02-23-10_11-42-26
	
	
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
	NSDateComponents *dateComponents = [gregorian components:unitFlags fromDate:[NSDate date]];
	
	NSRange monthrange = NSMakeRange(14,2);
	NSRange dayrange = NSMakeRange(17,2);
	NSRange yearrange = NSMakeRange(20,2);
	NSRange hourrange = NSMakeRange(23,2);
	NSRange minuterange = NSMakeRange(26,2);
	NSRange secondrange = NSMakeRange(29,2);
	
	[dateComponents setYear:[[filename substringWithRange:yearrange] integerValue]];
	[dateComponents setMonth:[[filename substringWithRange:monthrange]  integerValue]];
	[dateComponents setDay:[[filename substringWithRange:dayrange]  integerValue]];
	[dateComponents setHour:[[filename substringWithRange:hourrange]  integerValue]];
	[dateComponents setMinute:[[filename substringWithRange:minuterange]  integerValue]];
	[dateComponents setSecond:[[filename substringWithRange:secondrange]  integerValue]];
	
	NSDate *date = [gregorian dateFromComponents:dateComponents];
	
	return date;
}

-(NSArray*)dataArray
{
	if(!dataArray)
	{		
		NSError *error;
		
		NSFileManager *manager = [NSFileManager defaultManager];
		
		NSArray *imageList = [manager contentsOfDirectoryAtPath:dataFile error:&error];
		
		NSMutableArray *fileArray = [NSMutableArray arrayWithCapacity:[imageList count]];
		
		[fileArray addObject:[NSArray arrayWithObjects:@"File Name",nil]];
		
		for(NSString* imageName in imageList)
		{
			if([imageName characterAtIndex:0] != '.')
			{
				NSString *file = [dataFile stringByAppendingPathComponent:imageName];
				//NSDate *creationDate = [[manager attributesOfItemAtPath:file error:&error] objectForKey:NSFileCreationDate];
				NSDate *creationDate = [self parseDate:[[file lastPathComponent] stringByDeletingPathExtension]];
				[fileArray addObject:[NSArray arrayWithObjects:creationDate,imageName,nil]];
			}
		}
		
		QTTime duration = QTMakeTimeWithTimeInterval([[[fileArray lastObject] objectAtIndex:0] timeIntervalSinceDate:[[fileArray objectAtIndex:1] objectAtIndex:0]]);
		range = QTMakeTimeRange(QTMakeTime(0, duration.timeScale),duration);
		[self setDataArray:fileArray];
	}
	return dataArray;
}

-(NSArray*)importVariables:(NSArray*)variables asTypes:(NSArray*)types
{
	NSMutableArray *newDataSets = [NSMutableArray array];
	
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
				TimeCodedImageFiles* images = [[TimeCodedImageFiles alloc] initWithDataPointArray:[self imageFiles]];
				[newDataSets addObject:images];
				[dataSets addObject:images];
				[images setVariableName:variable];
				[images release];
			}
		}
	}
	
	return newDataSets;
}

- (NSArray*)imageFiles
{
	NSArray* data = [self dataArray];
	NSUInteger pictureColumn = 1;
	
	NSMutableArray *pictureFileArray = [NSMutableArray array];
	NSDate *startDate = [[data objectAtIndex:1] objectAtIndex:0];
	
	BOOL header = YES;
	for(NSArray* row in data)
	{
		if(header)
		{
			header = NO;
			continue;
		}
		
		if([row objectAtIndex:pictureColumn] != [NSNull null])
		{
			
			NSString *fileName = [row objectAtIndex:pictureColumn];
			
			NSString *pictureFile = [dataFile stringByAppendingPathComponent:fileName];
			
			NSDate *date = [row objectAtIndex:0];
			
			TimeCodedString *picture = [[TimeCodedString alloc] init];
			[picture setValue:0];
			[picture setTime:QTMakeTimeWithTimeInterval([date timeIntervalSinceDate:startDate])];
			[picture setString:pictureFile];
			
			[pictureFileArray addObject:picture];
			
			[picture release];
		}
	}
	
	return pictureFileArray;
	
}


@end
