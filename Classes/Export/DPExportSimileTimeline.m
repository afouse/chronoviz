//
//  DPExportSimileTimeline.m
//  DataPrism
//
//  Created by Adam Fouse on 3/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DPExportSimileTimeline.h"
#import "AnnotationDocument.h"
#import "VideoProperties.h"
#import "AnnotationXMLParser.h"

@interface DPExportSimileTimeline (Private)

- (void)exportDocument:(AnnotationDocument*)doc asSimileTimelineInDirectory:(NSString*)directory;

@end

@implementation DPExportSimileTimeline

-(NSString*)name
{
	return @"Simile Timeline";
}

- (BOOL)export:(AnnotationDocument*)doc
{	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES]; // Added by DustinVoss
	[openPanel setTitle:@"Select Directory for Simile Files"];
	[openPanel setPrompt:@"Choose folder"]; // Should be localized
	[openPanel setCanChooseFiles:NO];
	
	NSString *directory;
	
	if([openPanel runModalForTypes:nil] == NSOKButton) {
		directory = [openPanel filename];		
	} else {
		return NO;
	}
	
	[self exportDocument:doc asSimileTimelineInDirectory:directory];
	return YES;
}

- (void)exportDocument:(AnnotationDocument*)doc asSimileTimelineInDirectory:(NSString*)directory
{
	BOOL isDir;
	if([[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDir] && isDir)
	{	
		NSBundle* myBundle = [NSBundle mainBundle];
		NSString* indexFile = [myBundle pathForResource:@"simile-index" ofType:@"html"];
		NSString* sourceFile = [myBundle pathForResource:@"simile-src" ofType:@"zip"];
		
		//NSLog(filename);
		NSError *error;
		NSMutableString *html = [[NSMutableString alloc] initWithContentsOfFile:indexFile encoding:NSUTF8StringEncoding error:&error];
		
		if(!html)
		{
			NSLog(@"%@",[error localizedDescription]);
			return;
		}
		
		[html replaceOccurrencesOfString:@"<!-- Title -->" 
							  withString:[[doc videoProperties] title] 
								 options:NSLiteralSearch 
								   range:NSMakeRange(0, [html length])];
		
		[html replaceOccurrencesOfString:@"<!-- Date -->" 
							  withString:[[[doc xmlParser] dateFormatter] stringFromDate:[[doc videoProperties] startDate]] 
								 options:NSLiteralSearch 
								   range:NSMakeRange(0, [html length])];
		
		NSURL *videoURL = [NSURL fileURLWithPath:[[doc videoProperties] videoFile]];
		[html replaceOccurrencesOfString:@"<!-- VideoFile -->" 
							  withString:[videoURL absoluteString]
								 options:NSLiteralSearch 
								   range:NSMakeRange(0, [html length])];
		
		[html writeToFile:[directory stringByAppendingPathComponent:@"index.html"] atomically:YES encoding:NSUTF8StringEncoding error:&error];
		
		[[NSFileManager defaultManager] copyItemAtPath:sourceFile toPath:[directory stringByAppendingPathComponent:@"src.zip"] error:&error];
		
		NSTask *task = [[NSTask alloc] init];
		[task setCurrentDirectoryPath:directory];
		[task setLaunchPath:@"/usr/bin/unzip"];
		[task setArguments:[NSArray arrayWithObject:@"src.zip"]];
		[task launch];
		[task waitUntilExit];
		
		[[NSFileManager defaultManager] removeItemAtPath:[directory stringByAppendingPathComponent:@"src.zip"] error:&error];
		
		[doc saveAnnotations];
		
		[[NSFileManager defaultManager] copyItemAtPath:[doc annotationsFile] toPath:[directory stringByAppendingPathComponent:@"annotations.xml"] error:&error];
		
		//[self saveXMLAnnotationsToFile:[directory stringByAppendingPathComponent:@"annotations.xml"]];
		
		[[NSFileManager defaultManager] copyItemAtPath:[doc annotationsImageDirectory] toPath:[directory stringByAppendingPathComponent:@"images"] error:&error];
		
		[task release];
		[html release];
	}
	
}


@end
