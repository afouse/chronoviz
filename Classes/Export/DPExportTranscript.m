//
//  DPExportTranscript.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/21/12.
//
//

#import "DPExportTranscript.h"
#import "TranscriptData.h"
#import "TimeCodedSourcedString.h"
#import "DataSource.h"
#import "AnnotationDocument.h"
#import "NSStringTimeCodes.h"
#import "NSStringParsing.h"

@implementation DPExportTranscript

-(NSString*)name
{
	return @"Transcript";
}

- (BOOL)export:(AnnotationDocument*)doc;
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	[savePanel setCanCreateDirectories:YES];
	[savePanel setTitle:@"Transcript Export"];
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
	
	for(TimeSeriesData *data in [[AnnotationDocument currentDocument] dataSetsOfClass:[TranscriptData class]])
	{
        [button addItemWithTitle:[NSString stringWithFormat:@"%@ - %@",[[data source] name],[data name]]];
        [[button lastItem] setRepresentedObject:data];
	}
	
	[savePanel setAccessoryView:view];
	
	if([savePanel runModal] == NSOKButton) {
		
		//NSString *file = [savePanel filename];
		selectedData = [[button selectedItem] representedObject];
        
        NSMutableString *csvData = [NSMutableString stringWithString:@"Name,Text,StartTime\n"];
        
        NSMutableArray *alignment = [NSMutableArray array];
        
        CMTime lastRowTime;
        
        
        for(TimeCodedSourcedString *string in [(TranscriptData*)selectedData timeCodedStrings])
        {
            //NSLog(@"Transcript view string: %@",[string string]);
            if(![string interpolated] && (CMTimeCompare([string time], lastRowTime) != NSOrderedSame))
            {
                if([alignment count] > 0)
                {
                    [csvData appendString:[self transcriptArrayToCSV:alignment]];
                    [alignment removeAllObjects];
                }
                lastRowTime = [string time];
            }
            
            if([[string source] length] > 0)
            {
                NSArray *lines = [[string string] componentsSeparatedByString:@"\n"];
                if(([lines count] == 1)
                   && [[(TimeCodedSourcedString*)[[alignment lastObject] lastObject] source] isEqualToString:[string source]])
                {
                    [[alignment lastObject] addObject:string];
                }
                else
                {
                    for(NSString *line in lines)
                    {
                        TimeCodedSourcedString *segment = [[TimeCodedSourcedString alloc] init];
                        segment.source = string.source;
                        segment.time = string.time;
                        segment.string = line;
                        [alignment addObject:[NSMutableArray arrayWithObject:segment]];	
                        [segment release];
                    }
                }
            }
            
        }
        
        if([alignment count] > 0)
        {
            [csvData appendString:[self transcriptArrayToCSV:alignment]];
            [alignment removeAllObjects];
        }
        
        
        NSError *err = nil;
                
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

- (NSString*)transcriptArrayToCSV:(NSArray*)array
{
	NSMutableString *result = [NSMutableString stringWithString:@""];
	
	for(NSArray* row in array)
	{
        if([row count] > 0)
        {
            NSString *source = [[row objectAtIndex:0] source];
            if([source rangeOfString:@","].location == NSNotFound)
            {
              [result appendFormat:@"%@,",[[row objectAtIndex:0] source]];  
            }
            else
            {
                [result appendFormat:@"%@,",[[[row objectAtIndex:0] source] quotedString]];
            }
            
            NSString* text = @"";
            
            for(TimeCodedSourcedString *segment in row)
            {
                text = [text stringByAppendingString:[segment string]];
            }
            
            [result appendString:[text quotedString]];
            
            NSTimeInterval timeInterval;
            timeInterval = CMTimeGetSeconds(CMTimeAdd([[row objectAtIndex:0] time],[[(TranscriptData*)selectedData source] range].start));
            [result appendString:@","];
            [result appendString:[NSString stringWithTimeInterval:timeInterval]];
            [result appendString:@"\n"];
        }
	}
    
	return result;
}

@end
