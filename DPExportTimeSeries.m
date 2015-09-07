//
//  DPExportTimeSeries.m
//  ChronoViz
//
//  Created by Adam Fouse on 12/5/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPExportTimeSeries.h"
#import "TimeSeriesData.h"
#import "DataSource.h"
#import "AnnotationDocument.h"

@implementation DPExportTimeSeries

-(NSString*)name
{
	return @"Time Series Data";
}

- (BOOL)export:(AnnotationDocument*)doc;
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	[savePanel setCanCreateDirectories:YES];
	[savePanel setTitle:@"Time Series Export"];
	[savePanel setPrompt:@"Export"];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"csv"]];
	[savePanel setExtensionHidden:NO];
	[savePanel setCanSelectHiddenExtension:YES];
	
	NSRect viewFrame = NSMakeRect(0, 0, 450, 100);
	NSRect buttonFrame = NSMakeRect(140, 16, 280, 26);
	NSRect labelFrame = NSMakeRect(0, 22, 138, 17);
	NSRect instructionsFrame = NSMakeRect(10,50,430,40);
	
	NSView *view = [[NSView alloc] initWithFrame:viewFrame];
	
	NSPopUpButton *button = [[NSPopUpButton alloc] initWithFrame:buttonFrame pullsDown:NO];
	
	NSTextField *label = [[NSTextField alloc] initWithFrame:labelFrame];
	[label setStringValue:@"Data set to export:"];
	[label setEditable:NO];
	[label setDrawsBackground:NO];
	[label setBordered:NO];
	[label setAlignment:NSRightTextAlignment];
	
	NSTextField *instructions = [[NSTextField alloc] initWithFrame:instructionsFrame];
	[instructions setStringValue:@"Select a data set to export."];
	[instructions setEditable:NO];
	[instructions setDrawsBackground:NO];
	[instructions setBordered:NO];
	[instructions setAlignment:NSCenterTextAlignment];
	
	[view addSubview:instructions];
	[view addSubview:button];
	[view addSubview:label];
	
	[instructions release];
	[label release];
	[button release];
	
	for(TimeSeriesData *data in [[AnnotationDocument currentDocument] timeSeriesData])
	{
        [button addItemWithTitle:[NSString stringWithFormat:@"%@ - %@",[[data source] name],[data name]]];
        [[button lastItem] setRepresentedObject:data];
	}
	
	[savePanel setAccessoryView:view];
	
	if([savePanel runModal] == NSOKButton) {
		
		//NSString *file = [savePanel filename];	
		TimeSeriesData *selectedData = [[button selectedItem] representedObject];
        
        NSError *err = nil;
        
        NSString *csvData = [NSString stringWithFormat:@"Time,\"%@\"\n%@",[selectedData name],[selectedData csvData]];
        
		[csvData writeToURL:[savePanel URL]
                                atomically:YES
                                  encoding:NSUTF8StringEncoding
                                     error:&err];
		
        if(err)
        {
            return NO;
        }
        else
        {
            return YES;
        }

	}
	else
	{
		return NO;
	}
}

@end
