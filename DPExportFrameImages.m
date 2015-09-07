//
//  DPExportFrameImages.m
//  ChronoViz
//
//  Created by Adam Fouse on 5/3/12.
//  Copyright (c) 2012 University of California, San Diego. All rights reserved.
//

#import "DPExportFrameImages.h"
#import "AnnotationCategory.h"
#import "Annotation.h"
#import "AnnotationDocument.h"
#import "VideoProperties.h"
#import "NSStringTimeCodes.h"
#import <QuickTime/QuickTime.h>

@interface DPExportFrameImages (Private) 

-(void) exportFrame:(Annotation*)clip fromVideo:(VideoProperties*)props toFile:(NSString*)filepath;

@end

@implementation DPExportFrameImages

@synthesize annotation;
@synthesize video;

- (id) init
{
	self = [super init];
	if (self != nil) {
		annotation = nil;
		video = nil;
	}
	return self;
}

-(NSString*)name
{
	return @"Frame Images";
}

- (BOOL)export:(AnnotationDocument*)doc;
{
	if(annotation && video)
	{
		NSSavePanel *clipSavePanel = [NSSavePanel savePanel];
		[clipSavePanel setTitle:@"Save Frame Image"];
		[clipSavePanel setCanSelectHiddenExtension:YES];
		
		[clipSavePanel setRequiredFileType:@"jpg"];
		[clipSavePanel setExtensionHidden:YES];
		
		NSString *filename = nil;
		if([[annotation title] length] > 0)
		{
			filename = [annotation title];	
		}
		else
		{
			filename = @"Frame Image";
		}
		
		// files are filtered through the panel:shouldShowFilename: method above
		if ([clipSavePanel runModalForDirectory:nil file:filename] == NSOKButton) {
			[self exportFrame:annotation fromVideo:video toFile:[clipSavePanel filename]];
		}
		return YES;
	}
    
    return NO;
	
    // TODO: Menu Implementation
    /*
	NSInteger allVideosTag = 2;
	BOOL chooseMovie = ([[doc mediaProperties] count] > 0);
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setTitle:@"Video Clip Export"];
	[openPanel setPrompt:@"Export"]; // Should be localized
	[openPanel setCanChooseFiles:NO];
	
	NSRect viewFrame = chooseMovie ? NSMakeRect(0, 0, 350, 130) : NSMakeRect(0, 0, 350, 100);
	NSRect instructionsFrame = chooseMovie ? NSMakeRect(10,80,330,40) : NSMakeRect(10,50,330,40);
	
	NSRect buttonFrame = NSMakeRect(140, 16, 180, 26);
	NSRect labelFrame = NSMakeRect(0, 22, 138, 17);	
	
	NSRect videoButtonFrame = NSMakeRect(140, 46, 180, 26);
	NSRect videoLabelFrame = NSMakeRect(0, 52, 138, 17); 
	
	NSView *view = [[NSView alloc] initWithFrame:viewFrame];
	
	NSPopUpButton *button = [[NSPopUpButton alloc] initWithFrame:buttonFrame pullsDown:NO];
	
	NSTextField *label = [[NSTextField alloc] initWithFrame:labelFrame];
	[label setStringValue:@"Category to export:"];
	[label setEditable:NO];
	[label setDrawsBackground:NO];
	[label setBordered:NO];
	[label setAlignment:NSRightTextAlignment];
	
	NSTextField *instructions = [[NSTextField alloc] initWithFrame:instructionsFrame];
	[instructions setStringValue:@"Select a location for the video clips above,\nand a category of annotation to export."];
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
	
	NSPopUpButton *videoButton = nil;
	if(chooseMovie)
	{
		videoButton = [[NSPopUpButton alloc] initWithFrame:videoButtonFrame pullsDown:NO];
		
		NSTextField *videoLabel = [[NSTextField alloc] initWithFrame:videoLabelFrame];
		[videoLabel setStringValue:@"Video to export:"];
		[videoLabel setEditable:NO];
		[videoLabel setDrawsBackground:NO];
		[videoLabel setBordered:NO];
		[videoLabel setAlignment:NSRightTextAlignment];
		
		[instructions setStringValue:@"Select a location for the video clips above,\nand a video and category of annotation to export."];
		
		[view addSubview:videoButton];
		[view addSubview:videoLabel];
		
		[videoButton addItemWithTitle:[[doc videoProperties] title]];
		[[videoButton lastItem] setRepresentedObject:[doc videoProperties]];
		for(VideoProperties *videoProps in [doc mediaProperties])
		{
			[videoButton addItemWithTitle:[videoProps title]];
			[[videoButton lastItem] setRepresentedObject:videoProps];
		}
		[[videoButton menu] addItem:[NSMenuItem separatorItem]];
		[videoButton addItemWithTitle:@"All Videos"];
		[[videoButton lastItem] setTag:allVideosTag];
		
		[videoButton release];
		[videoLabel release];
		
	}
    
	for(AnnotationCategory* category in [doc categories])
	{
		[button addItemWithTitle:[category name]];
		[[button lastItem] setRepresentedObject:category];
		for(AnnotationCategory* value in [category values])
		{
			[button addItemWithTitle:[NSString stringWithFormat:@"%@ : %@",[category name],[value name]]];
			[[button lastItem] setRepresentedObject:value];
		}
	}
	
	[openPanel setAccessoryView:view];
	
	if([openPanel runModalForTypes:nil] == NSOKButton) {
		
		NSString *directory = [openPanel filename];	
		AnnotationCategory *selectedCategory = [[button selectedItem] representedObject];
		
		//QTMovie *newMovie = [QTMovie movie];
		NSError *err;
        
		NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] 
														 forKey:QTMovieFlatten];
		
		NSMutableArray *sourceVideos = [NSMutableArray array];
		if(chooseMovie)
		{
			if([[videoButton selectedItem] tag] == allVideosTag)
			{
				[sourceVideos addObject:[doc videoProperties]];
				for(VideoProperties *props in [doc mediaProperties])
				{
					[sourceVideos addObject:props];
				}
			}
			else
			{
				[sourceVideos addObject:[[videoButton selectedItem] representedObject]];
			}
		}
		else
		{
			[sourceVideos addObject:[doc videoProperties]];
		}
		
		for(Annotation* clip in [doc annotations])
		{
			if([clip isDuration] && [[clip category] matchesCategory:selectedCategory])
			{
				for(VideoProperties *props in sourceVideos)
				{
					QTMovie *sourceMovie = [props movie];
					NSString *filename = nil;
					if([[clip title] length] > 0)
					{
						filename = [directory stringByAppendingPathComponent:[clip title]];	
					}
					else
					{
						filename = [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ - %@",
																			  [clip startTimeString],
																			  [clip endTimeString]]];	
					}
					
					if(chooseMovie)
					{
						filename = [filename stringByAppendingFormat:@" - %@",[props title]];
					}
					
					filename = [filename stringByAppendingPathExtension:@"mov"];
					
					QTTimeRange sourceMovieRange = QTMakeTimeRange(QTZeroTime, [sourceMovie duration]);
					QTTime startTime = QTTimeIncrement([clip startTime], [props offset]);
					QTTime endTime = QTTimeIncrement([clip endTime], [props offset]);
					
					// Make sure the selected time actually exists in the movie
					QTTimeRange selectionRange = QTIntersectionTimeRange(sourceMovieRange, QTMakeTimeRange(startTime, QTTimeDecrement(endTime, startTime)));
					startTime = selectionRange.time;
					endTime = QTTimeIncrement(selectionRange.time, selectionRange.duration);
					
					QTMovie *newMovie = [[QTMovie alloc] initToWritableFile:filename error:&err];
					[sourceMovie setSelection:QTMakeTimeRange(startTime, QTTimeDecrement(endTime, startTime))];
					[newMovie appendSelectionFromMovie:sourceMovie];
					
					NSTimeInterval startTimeInterval;
					NSTimeInterval endTimeInterval;
					QTGetTimeInterval(startTime,&startTimeInterval);
					QTGetTimeInterval(endTime,&endTimeInterval);
					NSString *infoString = [NSString stringWithFormat:@"Original Source: %@\nOriginal Time: %@ - %@",
											[props videoFile],
											[NSString stringWithTimeInterval:startTimeInterval],
											[NSString stringWithTimeInterval:endTimeInterval]];
					
					[self addMovieInfoMetaData:newMovie infoString:infoString];
					
					[newMovie updateMovieFile];
					[newMovie writeToFile:filename withAttributes:dict];	
				}
			}
		}
		
		return YES;
	}
	else
	{
		return NO;
	}
    */
}

-(void) exportFrame:(Annotation*)clip fromVideo:(VideoProperties*)props toFile:(NSString*)filepath
{
	QTMovie *sourceMovie = [props movie];
	
	QTTime startTime = QTTimeIncrement([clip startTime], [props offset]);
	
	// Make sure the selected time actually exists in the movie
    if(QTTimeCompare(startTime, [sourceMovie duration]) == NSOrderedDescending)
    {
        startTime = [sourceMovie duration];
    }
	
    
    NSImage *image = [sourceMovie frameImageAtTime:[annotation startTime]];

    for(NSImageRep *imageRep in [image representations])
    {
        if([imageRep isKindOfClass:[NSBitmapImageRep class]])
        {
            NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
            NSData *imageData = [(NSBitmapImageRep*)imageRep representationUsingType:NSJPEGFileType properties:imageProps];
            [imageData writeToFile:filepath atomically:NO];
        }
    }

}

@end
