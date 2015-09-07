//
//  XPlaneDataSource.m
//  DataPrism
//
//  Created by Adam Fouse on 3/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XPlaneDataSource.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "NSStringFileManagement.h"
#import "NSStringParsing.h"


@implementation XPlaneDataSource

+(NSString*)dataTypeName
{
	return @"XPlane";
}


+(BOOL)validateFileName:(NSString*)fileName
{
	return ([[fileName pathExtension] caseInsensitiveCompare:@"txt"] == NSOrderedSame);
}

-(id)initWithPath:(NSString*)theFile
{
	self = [super initWithPath:theFile];
	if (self != nil) {
		[self setPredefinedTimeCode:YES];
		[self setTimeCoded:YES];
		timeColumn = 1;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		self.predefinedTimeCode = YES;
		self.timeCoded = YES;	
        timeColumn = 1;
	}
    return self;
}

-(NSArray*)possibleDataTypes
{
	return [NSArray arrayWithObjects:
			DataTypeTimeSeries,
			DataTypeGeographicLat,
			DataTypeGeographicLon,
			nil];
}

-(QTTime)timeForRowArray:(NSArray*)row;
{
	long timeScale = range.time.timeScale;
	double relativeTime = [[row objectAtIndex:timeColumn] doubleValue];
	return QTMakeTime(range.time.timeValue + (relativeTime * timeScale), timeScale);
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
		
		[delegate dataSourceLoadStart];
		[delegate dataSourceLoadStatus:0.2];
		
		NSMutableString *dataString = [[NSMutableString alloc] initWithContentsOfFile:dataFile encoding:NSUTF8StringEncoding error:&error];
		
		[delegate dataSourceLoadStatus:0.5];
		
		if(!dataString)
		{
			NSLog(@"Error loading data: %@",[error localizedDescription]);
			return nil;
		}
		[self setDataArray:[dataString barRows]];
		
		//float initialOffset = -[[[dataArray objectAtIndex:1] objectAtIndex:0] doubleValue];
		//range.time = QTMakeTimeWithTimeInterval(initialOffset);
		
		QTTime last = [self timeForRowArray:[dataArray lastObject]];
		
		int index = [dataArray count] - 1;
		while(last.timeValue == 0)
		{
			last = [self timeForRowArray:[dataArray objectAtIndex:index]];
			index--;
		}
		
		QTTime duration = QTTimeDecrement(last,[self timeForRowArray:[dataArray objectAtIndex:1]]);
		
		range.duration = duration;
		
		[delegate dataSourceLoadStatus:0.9];

		
		[dataString release];
		
		[delegate dataSourceLoadFinished];
	}
	return dataArray;
}

@end
