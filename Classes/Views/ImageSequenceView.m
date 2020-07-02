//
//  ImageSequenceView.m
//  Annotation
//
//  Created by Adam Fouse on 11/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ImageSequenceView.h"
#import "AppController.h"
#import "TimeCodedString.h"
#import "TimeCodedImageFiles.h"
#import "AnnotationDocument.h"
#import "DPViewManager.h"
#import "Annotation.h"

@implementation ImageSequenceView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		maxItems = 500;
        imageSequence = nil;
        imageFiles = nil;
		currentPictureFile = nil;
		currentImage = nil;
		imageCache = [[NSMutableDictionary alloc] initWithCapacity:maxItems];
    }
    return self;
}

- (void) dealloc
{
    [imageSequence release];
    [imageFiles release];
	[imageCache release];
	[currentImage release];
	[super dealloc];
}


- (void)drawRect:(NSRect)dirtyRect {
	
	[[NSColor blackColor] drawSwatchInRect:[self bounds]];
	
    if(currentImage)
	{
		//[currentImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
		
		float aspectRatio = [currentImage size].width/[currentImage size].height;
		float viewAspect = [self bounds].size.width/[self bounds].size.height;
		NSRect destination = [self bounds];
		
		if(aspectRatio >= viewAspect)
		{
			destination.size.height = destination.size.width/aspectRatio;
			destination.origin.y = ([self bounds].size.height - destination.size.height)/2;
		}
		else
		{
			destination.size.width = destination.size.height * aspectRatio;
			destination.origin.x = ([self bounds].size.width - destination.size.width)/2;
		}
		
		[currentImage drawInRect:destination fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	}
}


-(void)setTimeCodedImageFiles:(TimeCodedImageFiles*)files
{
    [files retain];
    [imageFiles release];
    imageFiles = files;
    
    NSArray *sequence = [files dataPoints];
    [sequence retain];
	[imageSequence release];
	imageSequence = sequence;
}

- (void)addData:(TimeCodedData*)data
{
    if([data isKindOfClass:[TimeCodedImageFiles class]])
    {
        [self setTimeCodedImageFiles:(TimeCodedImageFiles*)data];
    }
}

- (BOOL)removeData:(TimeCodedData*)data
{
    if(data == imageFiles)
    {
        [self setTimeCodedImageFiles:nil];
        return YES;
    }
    return NO;
}

-(NSArray*)dataSets
{
    if(imageFiles)
        return [NSArray arrayWithObject:imageFiles];
    else
        return [NSArray array];
}


-(void)update
{
	CMTime currentTime = [[[AppController currentApp] movie] currentTime];
	
	TimeCodedString *nextPictureFile = [imageSequence objectAtIndex:0];
	int index = 0;
	for(TimeCodedString *pictureFile in imageSequence)
	{
		// First check to see if the image is flagged as bad
		if([pictureFile value] > -1)
		{
			if(CMTIME_COMPARE_INLINE([pictureFile time], >=, currentTime))
			{
				break;
			}
			nextPictureFile = pictureFile;
			currentIndex = index;
		}
		index++;
	}
	
	if(nextPictureFile != currentPictureFile)
	{
		currentPictureFile = nextPictureFile;
		[currentImage release];
		currentImage = [[NSImage alloc] initWithContentsOfFile:[imageFiles imageFileForTimeCodedString:currentPictureFile]];
		
		// Sometimes the SenseCam images are corrupt, in which case currentImage will be nil.
		while(!currentImage && (index < [imageSequence count]))
		{
			// Set a flag so we know this is a bad image in the future.
			[currentPictureFile setValue:-1];
			currentPictureFile = [imageSequence objectAtIndex:index];
			currentImage = [[NSImage alloc] initWithContentsOfFile:[imageFiles imageFileForTimeCodedString:currentPictureFile]];
			currentIndex = index;
			index++;
		}
		[self setNeedsDisplay:YES];
		
	}										   
}

-(NSImage*)imageAtTime:(CMTime)time
{
	TimeCodedString *nextPictureFile = [imageSequence objectAtIndex:0];
	int index = 0;
	for(TimeCodedString *pictureFile in imageSequence)
	{
		// First check to see if the image is flagged as bad
		if([pictureFile value] > -1)
		{
			if(CMTIME_COMPARE_INLINE([pictureFile time], >=, time))
			{
				break;
			}
			nextPictureFile = pictureFile;
			currentIndex = index;
		}
		index++;
	}
	return [[[NSImage alloc] initWithContentsOfFile:[imageFiles imageFileForTimeCodedString:nextPictureFile]] autorelease];
		
}

-(CGImageRef)cgImageAtTime:(CMTime)time
{
	TimeCodedString *nextPictureFile = [imageSequence objectAtIndex:0];
	int index = 0;
	for(TimeCodedString *pictureFile in imageSequence)
	{
		// First check to see if the image is flagged as bad
		if([pictureFile value] > -1)
		{
			if(CMTIME_COMPARE_INLINE([pictureFile time], >=, time))
			{
				break;
			}
			nextPictureFile = pictureFile;
			currentIndex = index;
		}
		index++;
	}
	
	NSURL* nsurl = [NSURL fileURLWithPath:[imageFiles imageFileForTimeCodedString:nextPictureFile]];
	
	CFURLRef url = (CFURLRef)nsurl;
	
    CGDataProviderRef provider = CGDataProviderCreateWithURL (url);
	
    CGImageRef image = CGImageCreateWithJPEGDataProvider (provider,
											   NULL,
											   true,
											   kCGRenderingIntentDefault);
    CGDataProviderRelease (provider);
	return image;
}


-(NSUInteger)showPictureAtIndex:(NSUInteger)index
{
	if(index != currentIndex)
	{
		TimeCodedString* pictureFile = [imageSequence objectAtIndex:index];
		while([pictureFile value] < 0)
		{
			if(index < currentIndex)
			{
				index--;
				pictureFile = [imageSequence objectAtIndex:index];
			}
			else
			{
				index++;
				pictureFile = [imageSequence objectAtIndex:index];
			}
		}
		CMTime time = [pictureFile time];
		time.value = time.value + (time.timescale)/10;
		[[AppController currentApp] moveToTime:time fromSender:self];
		
//		[currentImage release];
//		currentImage = nil;
//		
//		currentPictureFile = [imageSequence objectAtIndex:index];
//		if([currentPictureFile value] > -1)
//		{
//			currentImage = [[NSImage alloc] initWithContentsOfFile:[imageFiles imageFileForTimeCodedString:currentPictureFile]];
//		}
//		
//		
//		while(!currentImage)
//		{
//			if(index < currentIndex)
//			{
//				index--;
//			}
//			else
//			{
//				index++;
//			}
//			currentPictureFile = [imageSequence objectAtIndex:index];
//			if([currentPictureFile value] > -1)
//			{
//				currentImage = [[NSImage alloc] initWithContentsOfFile:[imageFiles imageFileForTimeCodedString:currentPictureFile]];
//			}
//		}
//		
//		currentIndex = index;
//		[self setNeedsDisplay:YES];
	}
	return index;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)keyDown:(NSEvent *)event
{
	unsigned short theKey = [event keyCode];
	//NSLog(@"KeyDown %i",theKey);
	if(theKey == 36)
	{
		[[AppController currentApp] newAnnotation:self];	
	} else if(theKey == 123) // Left Arrow
	{
		[self showPictureAtIndex:(currentIndex - 1)];
	} else if(theKey == 124) // Right Arrow
	{
		[self showPictureAtIndex:(currentIndex + 1)];	
	} else if(theKey == 126) // Up Arrow
	{
		[[AppController currentApp] stepBack:self];		
	} else if(theKey == 125) // Down Arrow
	{
		[[AppController currentApp] stepForward:self];		
	}
    else {
        if([[NSUserDefaults standardUserDefaults] integerForKey:AFAnnotationShortcutActionKey] == AFCategoryShortcutEditor)
        {
            AnnotationCategory *category = [[AnnotationDocument currentDocument] annotationCategoryForKeyEquivalent:[event characters]];
            if(category)
            {
                [[AppController currentApp] showAnnotationQuickEntryForCategory:category];
            }
        }
        else if([event isARepeat] && lastAddedAnnotation &&
                ([lastAddedAnnotation category] == [[AnnotationDocument currentDocument] annotationCategoryForKeyEquivalent:[event characters]]))
        {
            [lastAddedAnnotation setIsDuration:YES];
            [lastAddedAnnotation setEndTime:[[AppController currentApp] currentTime]];
        }
        else
        {
            lastAddedAnnotation = [[AnnotationDocument currentDocument] addAnnotationForCategoryKeyEquivalent:[event characters]];
        }
        if(!lastAddedAnnotation)
        {
            [super keyDown:event];
        }		
    }
    
    
    
	//else {
	//	[super keyDown:event];
	//}
}


- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenu *theMenu = [[[NSMenu alloc] initWithTitle:@"Contextual Menu"] autorelease];
	[theMenu setAutoenablesItems:NO];
	

    NSMenuItem *item = [theMenu addItemWithTitle:@"Show in Main Window" action:@selector(showDataInMainViewAction:) keyEquivalent:@""];
    [item setRepresentedObject:imageFiles];
    [item setTarget:[[AppController currentApp] viewManager]];
	
    
	return theMenu;
}



-(NSData*)currentState:(NSDictionary*)stateFlags
{
	NSString* dataSetID = @"";
    if(imageFiles)
    {
        dataSetID = [imageFiles uuid];
    }
    
	return [NSKeyedArchiver archivedDataWithRootObject:[NSDictionary dictionaryWithObjectsAndKeys:
														dataSetID,@"DataSetID",
														nil]];
}

-(BOOL)setState:(NSData*)stateData
{
	NSDictionary *stateDict;
	@try {
		stateDict = [NSKeyedUnarchiver unarchiveObjectWithData:stateData];
	}
	@catch (NSException *e) {
		NSLog(@"Invalid archive, %@", [e description]);
		return NO;
	}
	
	
    
    NSString* dataSetID = [stateDict objectForKey:@"DataSetID"];
    if([dataSetID length] > 0)
    {
		for(TimeCodedData* dataSet in [[AnnotationDocument currentDocument] dataSets])
		{
			if([[dataSet uuid] isEqualToString:dataSetID])
			{
				[self addData:dataSet];
				break;
			}
		}
	}
    
    
    
	return YES;
}



@end
