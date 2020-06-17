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
	
}

-(void) exportFrame:(Annotation*)clip fromVideo:(VideoProperties*)props toFile:(NSString*)filepath
{
	AVPlayer *sourceMovie = [props movie];
	
	CMTime startTime = CMTimeAdd([clip startTime], [props offset]);
	
	// Make sure the selected time actually exists in the movie
    CMTime duration = [[sourceMovie currentItem] duration];
    if(CMTimeCompare(startTime, duration) == NSOrderedDescending)
    {
        startTime = duration;
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
