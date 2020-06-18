//
//  VideoPropertiesController.m
//  Annotation
//
//  Created by Adam Fouse on 6/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VideoPropertiesController.h"
#import "VideoProperties.h"
#import "Annotation.h"
#import "AppController.h"
#import "ColorCell.h"
#import "AnnotationCategory.h"
#import "AnnotationDocument.h"


@implementation VideoPropertiesController

@synthesize annotationDoc;

- (id)init
{
	if(![super initWithWindowNibName:@"VideoProperties"])
		return nil;
	
	videoProperties = nil;
//	editingCategory = nil;
	annotationDoc = nil;
	
	return self;
}

- (void) dealloc
{
	[videoProperties release];
	[super dealloc];
}


- (void)windowDidLoad
{
	[videoFileField setStringValue:[[videoProperties videoFile] lastPathComponent]];
	[titleField setStringValue:[videoProperties title]];
	[descriptionField setStringValue:[videoProperties description]];
	[startTimePicker setDateValue:[videoProperties startDate]];	
    [alignmentButton setEnabled:NO];
	//[alignmentButton setEnabled:(videoProperties != [[AnnotationDocument currentDocument] videoProperties])];
    
//	NSTableColumn* column;
//	ColorCell* colorCell;
//	
//	column = [[tableView tableColumns] objectAtIndex: 1];
//	colorCell = [[[ColorCell alloc] init] autorelease];
//    [colorCell setEditable: YES];
//	[colorCell setTarget: self];
//	[colorCell setAction: @selector (colorClick:)];
//	[column setDataCell: colorCell];
	
}

- (IBAction)showWindow:(id)sender
{
//	[tableView reloadData];
	[super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[videoProperties setTitle:[titleField stringValue]];
	[videoProperties setDescription:[descriptionField stringValue]];
	//[videoProperties setStartDate:[startTimePicker dateValue]];
	[annotationDoc saveVideoProperties:videoProperties];
}

-(VideoProperties*)videoProperties
{
	return videoProperties;
}

-(void)setVideoProperties:(VideoProperties *)properties
{
	[properties retain];
	[videoProperties release];
	videoProperties = properties;
	if([self window])
		[self windowDidLoad];
}


-(IBAction)changeTitle:(id)sender
{
	[videoProperties setTitle:[titleField stringValue]];
	[annotationDoc saveVideoProperties:videoProperties];
}

-(IBAction)changeDescription:(id)sender
{
	[videoProperties setDescription:[descriptionField stringValue]];
	[annotationDoc saveVideoProperties:videoProperties];
}

-(IBAction)changeStartTime:(id)sender
{
	NSDate* date = [startTimePicker dateValue];
	[videoProperties setStartDate:date];
	[annotationDoc saveVideoProperties:videoProperties];
	
//	if(videoProperties == [annotationDoc videoProperties])
//	{
//		for(Annotation* annotation in [annotationDoc annotations])
//		{
//			[annotation setReferenceDate:date];
//			[[AppController currentApp] updateAnnotation:annotation];
//		}
//		[Annotation setDefaultReferenceDate:date];	
//	}
}

-(IBAction)autoAlign:(id)sender
{
    VideoProperties *mainProperties = [annotationDoc videoProperties];
    if(videoProperties != mainProperties)
    {
        // NSTimeInterval startTime = [[annotationDoc videoProperties] computeAlignment:videoProperties];
        NSTimeInterval startTime = 0; // TODO: Check why the previous line does not compile. Can't find computeAlignment method.
        [videoProperties setOffset:CMTimeMakeWithSeconds(-startTime, 600)];
    }
}

@end
