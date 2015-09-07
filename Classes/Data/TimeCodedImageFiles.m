//
//  TimeCodedStringData.m
//  Annotation
//
//  Created by Adam Fouse on 11/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TimeCodedImageFiles.h"
#import "TimeCodedString.h"
#import "DataSource.h"
#import "NSStringFileManagement.h"

@implementation TimeCodedImageFiles

@synthesize relativeToSource;

- (NSString*)imageFileForTimeCodedString:(TimeCodedString*)dataPoint
{
    if(self.relativeToSource)
    {
        NSString *sourcePath = [[self source] dataFile];
        if(![sourcePath isDirectory])
        {
            sourcePath  = [sourcePath stringByDeletingLastPathComponent];
        }
    
        return [sourcePath stringByAppendingPathComponent:[dataPoint string]];
    }
    else
    {
        return [dataPoint string];
    }
}

-(id)initWithDataPointArray:(NSArray*)data
{
    self = [super initWithDataPointArray:data];
	if (self != nil) {
        self.relativeToSource = NO;
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
		TimeCodedString *dataPoint = [[TimeCodedString alloc] init];
		[dataPoint setValue:[[row objectAtIndex:1] doubleValue]];
		if(timeIntervals)
		{
			[dataPoint setTime:QTMakeTimeWithTimeInterval([[row objectAtIndex:0] floatValue])];
		}
		else
		{
			[dataPoint setTime:QTMakeTime([[row objectAtIndex:0] longLongValue],timeScale)];
		}
		//[dataPoint setTime:QTMakeTime([[row objectAtIndex:0] longLongValue],timeScale)];
		[dataPoint setString:[row objectAtIndex:2]];
		[dataPointArray addObject:dataPoint];
		[dataPoint release];
	}
	return dataPointArray;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeBool:relativeToSource forKey:@"DPTimeCodedImageFilesRelativeToSource"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
        if([coder containsValueForKey:@"DPTimeCodedImageFilesRelativeToSource"])
        {
            self.relativeToSource = [coder decodeBoolForKey:@"DPTimeCodedImageFilesRelativeToSource"];   
        }
        else
        {
            self.relativeToSource = NO;
            
        }
	}
    return self;
}

@end
