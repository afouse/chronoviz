//
//  SenseCamImport.m
//  Annotation
//
//  Created by Adam Fouse on 11/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SenseCamDataSource.h"
#import "NSStringParsing.h"
#import "TimeCodedString.h"
#import "TimeCodedImageFiles.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "NSStringFileManagement.h"
//#import "VideoProperties.h"

NSString * const SenseCamVersionData = @"VER";
NSString * const SenseCamFilenameData = @"FIL";
NSString * const SenseCamSystemData = @"SYS";
NSString * const SenseCamClockData = @"RTC";
NSString * const SenseCamAccelerationData = @"ACC";
NSString * const SenseCamTemperatureData = @"TMP";
NSString * const SenseCamWhiteLightData = @"CLR";
NSString * const SenseCamIRData = @"PIR";
NSString * const SenseCamBatteryData = @"BAT";
NSString * const SenseCamCameraData = @"CAM";

NSString * const SenseCamDataDateColumn = @"Date";
NSString * const SenseCamDataXAccelerationColumn = @"X Acc";
NSString * const SenseCamDataYAccelerationColumn = @"Y Acc";
NSString * const SenseCamDataZAccelerationColumn = @"Z Acc";
NSString * const SenseCamDataTemperatureColumn = @"Temperature";
NSString * const SenseCamDataVisibleLightColumn = @"Visible Light";
NSString * const SenseCamDataIRColumn = @"IR";
NSString * const SenseCamDataBatteryColumn = @"Battery";
NSString * const SenseCamDataImageFileColumn = @"Image File";
NSString * const SenseCamDataImageReasonColumn = @"Image Reason";


@implementation SenseCamDataSource

+(NSString*)dataTypeName
{
	return @"SenseCam";
}


+(BOOL)validateFileName:(NSString*)fileName
{
	return [[fileName lastPathComponent] isEqualToString:@"SENSOR.CSV"];
}

-(id)initWithPath:(NSString*)theFile
{
	self = [super initWithPath:theFile];
	if (self != nil) {
		[self setPredefinedTimeCode:YES];
		[self setTimeCoded:YES];
        version = 2;
		
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
			DataTypeTimeSeries,
			DataTypeImageSequence,
			nil];
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
                [images setSource:self];
                [images setRelativeToSource:YES];
				[newDataSets addObject:images];
				[dataSets addObject:images];
				[images setVariableName:variable];
				[images release];
			}
		}
	}
	
	return newDataSets;
}
	
-(CMTime)timeForRowArray:(NSArray*)row;
{
	NSDate *dataTime = [row objectAtIndex:timeColumn];
	
	return CMTimeMake([dataTime timeIntervalSinceDate:startDate], 1000000); // TODO: Check if the timescale is correct.
}

-(NSDate*)startDate
{
	return startDate;
}

-(NSArray*)dataArray
{
	if(!dataArray)
	{
		[delegate dataSourceLoadStatus:0];
		
		if(![dataFile fileExists])
		{
			dataFile = [[dataFile stringByAskingForReplacement] retain];
			[[AppController currentDoc] saveData];
		}
		
		NSError *error;
		NSMutableString *dataString = [[NSMutableString alloc] initWithContentsOfFile:dataFile encoding:NSUTF8StringEncoding error:&error];
		if(!dataString)
		{
			NSLog(@"Error loading data: %@",[error localizedDescription]);
			return nil;
		}
		NSArray *data = [dataString csvQuickRows];
		[dataString release];
		
		NSMutableArray *senseCamData = [NSMutableArray arrayWithCapacity:[data count]/5];
		
        for(NSArray *row in data)
        {
            if([[row objectAtIndex:0] caseInsensitiveCompare:SenseCamVersionData] == NSOrderedSame)
            {
                if([[row objectAtIndex:1] length] > 2)
                {
                    version = [[row objectAtIndex:2] integerValue];
                    break;
                }
            }
        }
        
        
        if(version > 3)
        {
            [self processVersionFourData:data intoArray:senseCamData];
        }
        else
        {

            NSArray *headers = [NSArray arrayWithObjects:
                                @"Date",
                                @"X Acc",
                                @"Y Acc",
                                @"Z Acc",
                                @"Temperature",
                                @"Visible Light",
                                @"IR",
                                @"Battery",
                                @"Image File",
                                @"Image Reason",
                                nil];
            
            [senseCamData addObject:headers];
		
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
            NSDateComponents *dateComponents = [gregorian components:unitFlags fromDate:[NSDate date]];
            
            NSMutableArray *currentRow = nil;
            NSDate *currentDate = nil;
            
            CGFloat rowNum = 0;
            NSDate *date;
            for(NSArray* row in data)
            {
                if([delegate dataSourceCancelLoad])
                {
                    [gregorian release];
                    return nil;
                }
                
                NSString *type = [row objectAtIndex:0];
                if([type isEqualToString:SenseCamVersionData] ||
                   [type isEqualToString:SenseCamFilenameData]||
                   [type isEqualToString:SenseCamSystemData])
                {
                    continue;
                }
                
                if([type isEqualToString:SenseCamClockData])
                {
                    [dateComponents setYear:[[row objectAtIndex:1] integerValue]];
                    [dateComponents setMonth:[[row objectAtIndex:2] integerValue]];
                    [dateComponents setDay:[[row objectAtIndex:3] integerValue]];
                    [dateComponents setHour:[[row objectAtIndex:4] integerValue]];
                    [dateComponents setMinute:[[row objectAtIndex:5] integerValue]];
                    [dateComponents setSecond:[[row objectAtIndex:6] integerValue]];
                    continue;
                }
                
                [dateComponents setHour:[[row objectAtIndex:1] integerValue]];
                [dateComponents setMinute:[[row objectAtIndex:2] integerValue]];
                [dateComponents setSecond:[[row objectAtIndex:3] integerValue]];
                date = [gregorian dateFromComponents:dateComponents];
                if(![date isEqualToDate:currentDate])
                {
                    if(currentDate == nil)
                    {
                        startDate = [date retain];
                    }
                    
                    currentDate = date;
                    if(currentRow)
                    {
                        NSArray *immutableCopy = [currentRow copy];
                        [senseCamData  addObject:immutableCopy];
                        [immutableCopy release];
                    }
                    
                    currentRow = [NSMutableArray arrayWithCapacity:[headers count]];
                    [currentRow addObject:currentDate];
                    int i;
                    for(i = 1; i < [headers count]; i++)
                    {
                        [currentRow addObject:[NSNull null]];
                    }
                }
                
                if ([type isEqualToString:SenseCamAccelerationData])
                {
                    [currentRow replaceObjectAtIndex:1 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:4] integerValue]]];
                    [currentRow replaceObjectAtIndex:2 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:5] integerValue]]];
                    [currentRow replaceObjectAtIndex:3 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:6] integerValue]]];
                }
                else if ([type isEqualToString:SenseCamTemperatureData])
                {
                    [currentRow replaceObjectAtIndex:4 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:4] integerValue]]];
                }
                else if ([type isEqualToString:SenseCamWhiteLightData])
                {
                    [currentRow replaceObjectAtIndex:5 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:4] integerValue]]];
                }
                else if ([type isEqualToString:SenseCamIRData])
                {
                    [currentRow replaceObjectAtIndex:6 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:4] integerValue]]];
                }
                else if ([type isEqualToString:SenseCamBatteryData])
                {
                    [currentRow replaceObjectAtIndex:7 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:4] integerValue]]];
                }
                else if ([type isEqualToString:SenseCamCameraData])
                {
                    [currentRow replaceObjectAtIndex:8 withObject:[row objectAtIndex:4]];
                    [currentRow replaceObjectAtIndex:9 withObject:[row objectAtIndex:5]];
                }
                
                rowNum++;
                [delegate dataSourceLoadStatus:(rowNum/[data count])];
                
            }
            
            if(currentRow)
            {
                NSArray *immutableCopy = [currentRow copy];
                [senseCamData addObject:immutableCopy];
                [immutableCopy release];
            }
            
            [gregorian release];
            
            CMTime duration = CMTimeMake([date timeIntervalSinceDate:startDate], 1000000); // TODO: Check if the timescale is correct.
            range = CMTimeRangeMake(CMTimeMake(0, duration.timescale),duration);
            
        }
        
        [self setDataArray:senseCamData];
            
        [delegate dataSourceLoadFinished];
	}
	return dataArray;
}

- (void)processVersionFourData:(NSArray*)data intoArray:(NSMutableArray*)senseCamData;
{
    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    
    NSMutableArray *currentRow = nil;
    NSDate *currentDate = nil;
    
    NSArray *headers = [NSArray arrayWithObjects:
                        @"Date",
                        @"X Acc",
                        @"Y Acc",
                        @"Z Acc",
                        @"Temperature",
                        @"Visible Light",
                        @"IR",
                        @"Battery",
                        @"Image File",
                        @"Image Reason",
                        nil];
    
    [senseCamData addObject:headers];
    
    CGFloat rowNum = 0;
    NSDate *date;
    for(NSArray* row in data)
    {
        if([delegate dataSourceCancelLoad])
        {
            [senseCamData removeAllObjects];
            break;
        }
        
        NSString *type = [row objectAtIndex:0];
        NSString *timestamp = [row objectAtIndex:1];
        if([type isEqualToString:SenseCamVersionData] ||
           [type isEqualToString:SenseCamFilenameData]||
           [type isEqualToString:SenseCamClockData] ||
           [type isEqualToString:SenseCamSystemData])
        {
            continue;
        }
        
        date = [dateFormatter dateFromString:timestamp];
        if(![date isEqualToDate:currentDate])
        {
            if(currentDate == nil)
            {
                startDate = [date retain];
            }
            
            currentDate = date;
            if(currentRow)
            {
                NSArray *immutableCopy = [currentRow copy];
                [senseCamData  addObject:immutableCopy];
                [immutableCopy release];
            }
            
            currentRow = [NSMutableArray arrayWithCapacity:[headers count]];
            [currentRow addObject:currentDate];
            int i;
            for(i = 1; i < [headers count]; i++)
            {
                [currentRow addObject:[NSNull null]];
            }
        }
        
        if ([type isEqualToString:SenseCamAccelerationData])
        {
            [currentRow replaceObjectAtIndex:1 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:2] doubleValue]]];
            [currentRow replaceObjectAtIndex:2 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:3] doubleValue]]];
            [currentRow replaceObjectAtIndex:3 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:4] doubleValue]]];
        }
        else if ([type isEqualToString:SenseCamTemperatureData])
        {
            [currentRow replaceObjectAtIndex:4 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:2] doubleValue]]];
        }
        else if ([type isEqualToString:SenseCamWhiteLightData])
        {
            [currentRow replaceObjectAtIndex:5 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:2] integerValue]]];
        }
        else if ([type isEqualToString:SenseCamIRData])
        {
            [currentRow replaceObjectAtIndex:6 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:2] integerValue]]];
        }
        else if ([type isEqualToString:SenseCamBatteryData])
        {
            [currentRow replaceObjectAtIndex:7 withObject:[NSNumber numberWithInteger:[[row objectAtIndex:2] integerValue]]];
        }
        else if ([type isEqualToString:SenseCamCameraData])
        {
            [currentRow replaceObjectAtIndex:8 withObject:[row objectAtIndex:2]];
            [currentRow replaceObjectAtIndex:9 withObject:[row objectAtIndex:3]];
        }
        
        rowNum++;
        [delegate dataSourceLoadStatus:(rowNum/[data count])];
        
    }
    
    if(currentRow)
    {
        NSArray *immutableCopy = [currentRow copy];
        [senseCamData addObject:immutableCopy];
        [immutableCopy release];
    }
    
    [dateFormatter release];
    
    CMTime duration = CMTimeMake([date timeIntervalSinceDate:startDate], 1000000); // TODO: Check if the timescale is correct.
    range = CMTimeRangeMake(CMTimeMake(0, duration.timescale),duration);
}

- (NSArray*)imageFiles
{
	NSArray* data = [self dataArray];
	NSUInteger pictureColumn = [[data objectAtIndex:0] indexOfObject:@"Image File"];
	
	//NSDate *startDate = [[data objectAtIndex:1] objectAtIndex:0];
	//NSString *directory = [dataFile stringByDeletingLastPathComponent];
	
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
            
            NSString *pictureFile = nil;

            if([[NSFileManager defaultManager] fileExistsAtPath:[[[self dataFile] stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName]])
            {
                pictureFile = fileName;
            }
            else
            {
                        
                int imageNum = [[fileName stringByDeletingPathExtension] intValue];
                int highlevel = imageNum/10000;
                int midlevel = imageNum/100;
                
                //NSString *pictureFile = [NSString stringWithFormat:@"%@/H%.2i/M%.4i/%@",directory,highlevel,midlevel,fileName];
                pictureFile = [NSString stringWithFormat:@"H%.2i/M%.4i/%@",highlevel,midlevel,fileName];
			}
            
			NSDate *date = [row objectAtIndex:0];
			
			TimeCodedString *picture = [[TimeCodedString alloc] init];
			[picture setValue:0];
			[picture setTime:CMTimeMake([date timeIntervalSinceDate:startDate], 1000000)]; // TODO: Check if the timescale is correct.
			[picture setString:pictureFile];
			
			[pictureFileArray addObject:picture];
			
			[picture release];
		}
	}
	
	return pictureFileArray;
	
}



@end
