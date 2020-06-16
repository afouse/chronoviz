//
//  DPExportMovieClips.m
//  DataPrism
//
//  Created by Adam Fouse on 3/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DPExportMovieClips.h"
#import "AnnotationCategory.h"
#import "Annotation.h"
#import "AnnotationDocument.h"
#import "VideoProperties.h"
#import "NSStringTimeCodes.h"

@interface DPExportMovieClips (Private) 

-(void) exportClip:(Annotation*)clip fromVideo:(VideoProperties*)props toFile:(NSString*)filepath;
-(void) addMovieInfoMetaData:(QTMovie *)aQTMovie infoString:(NSString *)aNameStr;
-(const char *)langCode;

@end

@implementation DPExportMovieClips

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
	return @"Video Clips";
}

- (BOOL)export:(AnnotationDocument*)doc;
{
	if(annotation && video)
	{
		NSSavePanel *clipSavePanel = [NSSavePanel savePanel];
		[clipSavePanel setTitle:@"Save Video Clip"];
		[clipSavePanel setCanSelectHiddenExtension:YES];
		
		[clipSavePanel setRequiredFileType:@"mov"];
		[clipSavePanel setExtensionHidden:YES];
		
		NSString *filename = nil;
		if([[annotation title] length] > 0)
		{
			filename = [annotation title];	
		}
		else
		{
			filename = @"Video Clip";
		}
		
		// files are filtered through the panel:shouldShowFilename: method above
		if ([clipSavePanel runModalForDirectory:nil file:filename] == NSOKButton) {
			[self exportClip:annotation fromVideo:video toFile:[clipSavePanel filename]];
		}
		return YES;
	}
	
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
					
					CMTimeRange sourceMovieRange = QTMakeTimeRange(kCMTimeZero, [sourceMovie duration]);
					CMTime startTime = CMTimeAdd([clip startTime], [props offset]);
					CMTime endTime = CMTimeAdd([clip endTime], [props offset]);
					
					// Make sure the selected time actually exists in the movie
					CMTimeRange selectionRange = QTIntersectionTimeRange(sourceMovieRange, QTMakeTimeRange(startTime, CMTimeSubtract(endTime, startTime)));
					startTime = selectionRange.time;
					endTime = CMTimeAdd(selectionRange.time, selectionRange.duration);
					
					QTMovie *newMovie = [[QTMovie alloc] initToWritableFile:filename error:&err];
					[sourceMovie setSelection:QTMakeTimeRange(startTime, CMTimeSubtract(endTime, startTime))];
					[newMovie appendSelectionFromMovie:sourceMovie];
					
					NSTimeInterval startTimeInterval;
					NSTimeInterval endTimeInterval;
					startTimeInterval = CMTimeGetSeconds(startTime);
					endTimeInterval = CMTimeGetSeconds(endTime);
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
}

-(void) exportClip:(Annotation*)clip fromVideo:(VideoProperties*)props toFile:(NSString*)filepath
{
	QTMovie *sourceMovie = [props movie];
	
	CMTimeRange sourceMovieRange = QTMakeTimeRange(kCMTimeZero, [sourceMovie duration]);
	CMTime startTime = CMTimeAdd([clip startTime], [props offset]);
	CMTime endTime = CMTimeAdd([clip endTime], [props offset]);
	
	// Make sure the selected time actually exists in the movie
	CMTimeRange selectionRange = QTIntersectionTimeRange(sourceMovieRange, QTMakeTimeRange(startTime, CMTimeSubtract(endTime, startTime)));
	startTime = selectionRange.time;
	endTime = CMTimeAdd(selectionRange.time, selectionRange.duration);
	
	NSError* err = nil;
	QTMovie *newMovie = [[QTMovie alloc] initToWritableFile:filepath error:&err];
	[sourceMovie setSelection:QTMakeTimeRange(startTime, CMTimeSubtract(endTime, startTime))];
	[newMovie appendSelectionFromMovie:sourceMovie];
	
	NSTimeInterval startTimeInterval;
	NSTimeInterval endTimeInterval;
	startTimeInterval = CMTimeGetSeconds(startTime);
	endTimeInterval = CMTimeGetSeconds(endTime);
	NSString *infoString = [NSString stringWithFormat:@"Original Source: %@\nOriginal Time: %@ - %@",
							[props videoFile],
							[NSString stringWithTimeInterval:startTimeInterval],
							[NSString stringWithTimeInterval:endTimeInterval]];
	
	[self addMovieInfoMetaData:newMovie infoString:infoString];
	
	NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] 
													 forKey:QTMovieFlatten];
	[newMovie updateMovieFile];
	[newMovie writeToFile:filepath withAttributes:dict];	
}

// Add the artist name metadata item to a movie file
-(void) addMovieInfoMetaData:(QTMovie *)aQTMovie infoString:(NSString *)aNameStr
{
    NSLog(@"Metadata export needs to be updated for AV Foundation!");
    /*
	NSLog(@"Write meta data: %@",aNameStr);
	
    QTMetaDataRef   metaDataRef;
    Movie           theMovie;
    OSStatus        status;
	
    theMovie = [aQTMovie quickTimeMovie];
    status = QTCopyMovieMetaData (theMovie, &metaDataRef );
    NSAssert(status == noErr,@"QTCopyMovieMetaData failed!");
	
    if (status == noErr)
    {
        const char *nameCStringPtr = [aNameStr UTF8String];
        NSAssert(nameCStringPtr != nil,@"UTF8String failed!");
		
        if (nameCStringPtr)
        {
            //OSType key = kQTMetaDataCommonKeyArtist;
			OSType key = kQTMetaDataCommonKeyInformation;
            QTMetaDataItem outItem;
            status = QTMetaDataAddItem(metaDataRef,
									   kQTMetaDataStorageFormatQuickTime, 
									   kQTMetaDataKeyFormatCommon,
									   (const UInt8 *)&key,
									   sizeof(key),
									   (const UInt8 *)nameCStringPtr,
									   strlen(nameCStringPtr),
									   kQTMetaDataTypeUTF8,
									   &outItem);
            NSAssert(status == noErr,@"QTMetaDataAddItem failed!");
			
            // it is also recommended you set the locale identifier
            const char *langCodeStr = [self langCode];
            status = QTMetaDataSetItemProperty(
											   metaDataRef,
											   outItem,
											   kPropertyClass_MetaDataItem,
											   kQTMetaDataItemPropertyID_Locale,
											   strlen(langCodeStr) + 1,
											   langCodeStr);
			
            if (status == noErr)
            {
                // we must update the movie file to save the
                // metadata items that were added
                BOOL success = [aQTMovie updateMovieFile];
                NSAssert(success == YES,@"updateMovieFile failed!");
            }
        }
		
        QTMetaDataRelease(metaDataRef);
    }
     */
}

// Return the default language set by the user 
// in the language tab of the International preference
// pane.
-(const char *)langCode
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSAssert(defaults != NULL,@"standardUserDefaults failed!");
	
    NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
    NSAssert(languages != NULL,@"objectForKey failed!");
	
    NSString *langStr = [languages objectAtIndex:0];
	
    return ([langStr cStringUsingEncoding:NSMacOSRomanStringEncoding]);
}

@end
