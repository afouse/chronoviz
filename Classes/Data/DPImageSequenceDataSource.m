//
//  ImageSequenceDataSource.m
//  ChronoViz
//
//  Created by Adam Fouse on 1/19/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPImageSequenceDataSource.h"
#import "TimeCodedString.h"
#import "TimeCodedImageFiles.h"
#import "TimeCodedData.h"

@interface DPImageSequenceDataSource (Parsing)

- (NSDate*)parseDate:(NSString*)filename;

@end

@implementation DPImageSequenceDataSource

+(NSString*)dataTypeName
{
	return @"Image Sequence";
}

+(BOOL)validateFileName:(NSString*)fileName
{
	return (([[fileName pathExtension] caseInsensitiveCompare:@"jpg"] == NSOrderedSame)
				|| ([[fileName pathExtension] caseInsensitiveCompare:@"png"] == NSOrderedSame));
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
		startDate = nil;
		[self setPredefinedTimeCode:NO];
		[self setTimeCoded:YES];
		[self setAbsoluteTime:NO];
		[self setDirectoryDataFile:YES];
		
	}
	return self;
}

- (void) dealloc
{
	[startDate release];
	[super dealloc];
}

-(NSArray*)possibleDataTypes
{
	return [NSArray arrayWithObjects:
			DataTypeImageSequence,
			nil];
}

-(NSArray*)defaultVariablesToImport
{
	return [NSArray arrayWithObject:@"File Name"];
}

-(NSString*)defaultDataType:(NSString*)variableName
{
	return DataTypeImageSequence;
}

-(NSDate*)startDate
{	
	if(startDate)
	{
		return startDate;
	}
	else
	{
		return [[[self dataArray] objectAtIndex:1] objectAtIndex:0];
	}	
}

-(QTTime)timeForRowArray:(NSArray*)row;
{
	NSDate *dataTime = [row objectAtIndex:[self timeColumn]];
	return QTMakeTimeWithTimeInterval([dataTime timeIntervalSinceDate:[self startDate]]);
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
		
		[fileArray addObject:[NSArray arrayWithObjects:@"Modification Date",@"Creation Date",@"File Name",nil]];
		
		for(NSString* imageName in imageList)
		{
			if([imageName characterAtIndex:0] != '.')
			{
				NSString *file = [dataFile stringByAppendingPathComponent:imageName];
				NSDate *creationDate = [[manager attributesOfItemAtPath:file error:&error] objectForKey:NSFileCreationDate];
				NSDate *modificationDate = [[manager attributesOfItemAtPath:file error:&error] objectForKey:NSFileModificationDate];
				//NSDate *creationDate = [self parseDate:[[file lastPathComponent] stringByDeletingPathExtension]];
				[fileArray addObject:[NSArray arrayWithObjects:modificationDate,creationDate,imageName,nil]];
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
	
	NSArray *fileArray = [self dataArray];
	
	NSDate *start = [[fileArray objectAtIndex:1] objectAtIndex:0];
	NSDate *end = [[fileArray objectAtIndex:1] objectAtIndex:0];
	
	BOOL first = YES;
	for(NSArray *row in fileArray)
	{
		if(first)
		{
			first = NO;
		}
		else
		{
			start = [start earlierDate:[row objectAtIndex:[self timeColumn]]];
			end = [end laterDate:[row objectAtIndex:[self timeColumn]]];	
		}
	}
	
	[startDate release];
	startDate = [start retain];
	
	QTTime duration = QTMakeTimeWithTimeInterval([end timeIntervalSinceDate:start]);
	range = QTMakeTimeRange(QTMakeTime(0, duration.timeScale),duration);
	
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
			if([type isEqualToString:DataTypeImageSequence])
			{
				imageFileColumn = [[dataArray objectAtIndex:0] indexOfObject:variable];
				TimeCodedImageFiles* images = [[TimeCodedImageFiles alloc] initWithDataPointArray:[self imageFiles]];
				[newDataSets addObject:images];
				[dataSets addObject:images];
				[images setVariableName:variable];
				[images release];
				
			}
		}
	}
	
	if(![self absoluteTime])
	{
		[startDate release];
		startDate = nil;
	}
	
	return newDataSets;
}

- (NSArray*)imageFiles
{
	NSArray* data = [self dataArray];
	NSUInteger pictureColumn = imageFileColumn;
	
	NSMutableArray *pictureFileArray = [NSMutableArray array];
	
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
			
			NSDate *date = [row objectAtIndex:[self timeColumn]];
			
			TimeCodedString *picture = [[TimeCodedString alloc] init];
			[picture setValue:0];
			[picture setTime:QTMakeTimeWithTimeInterval([date timeIntervalSinceDate:[self startDate]])];
			[picture setString:pictureFile];
			
			[pictureFileArray addObject:picture];
			
			[picture release];
		}
	}
	
	NSSortDescriptor *timeDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"seconds" ascending:YES] autorelease];
	[pictureFileArray sortUsingDescriptors:[NSArray arrayWithObject:timeDescriptor]];
	
	return pictureFileArray;
	
}

@end
