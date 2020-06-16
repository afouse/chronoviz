//
//  ProtoVisExport.m
//  DataPrism
//
//  Created by Adam Fouse on 2/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ProtoVisExport.h"
#import "TimeSeriesData.h"
#import "TimeCodedDataPoint.h"
#import "VideoProperties.h"
#import "AnnotationDocument.h"
#import <AVKit/AVKit.h>

@implementation ProtoVisExport

@synthesize video;
@synthesize width;
@synthesize height;

- (id) init
{
	self = [super init];
	if (self != nil) {
		dataSets = [[NSMutableArray alloc] init];
		annotations = [[NSMutableArray alloc] init];
		width = 800;
		height = 200;
	}
	return self;
}

- (void) dealloc
{
	[dataSets release];
	[annotations release];
	[super dealloc];
}

-(NSString*)name
{
	return @"ProtoVis Timelines";
}

-(BOOL)export:(AnnotationDocument*)doc
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setTitle:@"Select Directory for ProtoVis Files"];
	[openPanel setPrompt:@"Choose folder"];
	[openPanel setCanChooseFiles:NO];
	
	NSString *directory;
	
	if([openPanel runModalForTypes:nil] == NSOKButton) {
		directory = [openPanel filename];		
	} else {
		return NO;
	}
	
	[self setVideo:[doc videoProperties]];
	[self setHeight:200];
	
	for(TimeSeriesData *data in [doc timeSeriesData])
	{
		[self addDataSet:data];
	}
	
	[self exportDataToProtoVisFile:directory];
	
	return YES;
}

- (void)addDataSet:(TimeSeriesData*)data
{
	[dataSets addObject:data];
}

- (void)exportDataToProtoVisFile:(NSString*)directory
{
	BOOL isDir;
	if([[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDir] && isDir && ([dataSets count] > 0))
	{	
		NSBundle* myBundle = [NSBundle mainBundle];
		NSString* sourceFile = [myBundle pathForResource:@"protovis" ofType:@"js"];
		NSString* indexFile = [myBundle pathForResource:@"protovischart" ofType:@"html"];
		
		NSMutableString *jsData = [[NSMutableString alloc] initWithString:@"var data = [\n"];
		
		for(TimeSeriesData *dataSet in dataSets)
		{
			[jsData appendFormat:@"{name: \"%@\", values: [",[dataSet name]];
			
			
			NSArray* dataPoints = [dataSet subsetOfSize:width 
											   forRange:CMTimeRangeMake(CMTimeMake(0,600), [[video movie] duration])];
			
			for(TimeCodedDataPoint *point in dataPoints)
			{
				NSTimeInterval time;
				time = CMTimeGetSeconds([point time]);
				[jsData appendFormat:@"{val: %f, time: %f},\n",(float)[point value], time];
			}
			
			[jsData deleteCharactersInRange:NSMakeRange([jsData length] - 1, 1)];
			[jsData appendString:@"]},"];
		}
		
		[jsData appendString:@"];"];
		
		//NSLog(filename);
		NSError *error;
		NSMutableString *html = [[NSMutableString alloc] initWithContentsOfFile:indexFile encoding:NSUTF8StringEncoding error:&error];
		
		if(!html)
		{
			NSLog(@"%@",[error localizedDescription]);
			return;
		}
		
		[html replaceOccurrencesOfString:@"<!-- Title -->" 
							  withString:[video title] 
								 options:NSLiteralSearch 
								   range:NSMakeRange(0, [html length])];
		
		NSURL *videoURL = [NSURL fileURLWithPath:[video videoFile]];
		[html replaceOccurrencesOfString:@"<!-- VideoFile -->" 
							  withString:[videoURL absoluteString]
								 options:NSLiteralSearch 
								   range:NSMakeRange(0, [html length])];
		
		[html replaceOccurrencesOfString:@"<!-- ChartHeight -->" 
							  withString:[NSString stringWithFormat:@"%i",height]
								 options:NSLiteralSearch 
								   range:NSMakeRange(0, [html length])];
		
		[html replaceOccurrencesOfString:@"<!-- FigureHeight -->" 
							  withString:[NSString stringWithFormat:@"%i",((height + 30) * [dataSets count])]
								 options:NSLiteralSearch 
								   range:NSMakeRange(0, [html length])];
		
		[html replaceOccurrencesOfString:@"<!-- Title -->" 
							  withString:[video title] 
								 options:NSLiteralSearch 
								   range:NSMakeRange(0, [html length])];
		
		[html replaceOccurrencesOfString:@"<!-- data -->" 
							  withString:jsData
								 options:NSLiteralSearch 
								   range:NSMakeRange(0, [html length])];
		
		[html writeToFile:[directory stringByAppendingPathComponent:@"index.html"]  atomically:YES encoding:NSUTF8StringEncoding error:&error];
		
		[[NSFileManager defaultManager] copyItemAtPath:sourceFile toPath:[directory stringByAppendingPathComponent:@"protovis.js"] error:&error];
				
		[html release];
		[jsData release];
	}
	
}

@end
