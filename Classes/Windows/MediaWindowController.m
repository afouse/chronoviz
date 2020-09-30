//
//  MediaWindowController.m
//  Annotation
//
//  Created by Adam Fouse on 12/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MediaWindowController.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "VideoProperties.h"
#import "VideoPropertiesController.h"

@implementation MediaWindowController

- (id)init
{
	if(![super initWithWindowNibName:@"MediaWindow"])
		return nil;
	
	return self;
}

- (void)windowDidLoad
{
	[mainVideoField setStringValue:[[[[AppController currentDoc] videoProperties] videoFile] lastPathComponent]];
}


-(IBAction)showWindow:(id)sender
{
	[mainVideoField setStringValue:[[[[AppController currentDoc] videoProperties] videoFile] lastPathComponent]];
	[mediaTableView reloadData];
}

-(IBAction)addMedia:(id)sender
{
	//[[AppController currentApp] importMedia:self];
	[mediaTableView reloadData];
}

-(IBAction)removeMedia:(id)sender
{
	VideoProperties *properties = [[[AppController currentDoc] mediaProperties] objectAtIndex:[mediaTableView selectedRow]];
	[[AppController currentApp] removeMedia:properties];
	[mediaTableView reloadData];
}

-(IBAction)editMedia:(id)sender
{
	if(!videoPropertiesController) {
		videoPropertiesController = [[VideoPropertiesController alloc] init];
	}
	
	VideoProperties *properties = [[[AppController currentDoc] mediaProperties] objectAtIndex:[mediaTableView selectedRow]];
	[videoPropertiesController setVideoProperties:properties];
	[videoPropertiesController setAnnotationDoc:[AppController currentDoc]];
	[videoPropertiesController showWindow:self];
	[[videoPropertiesController window] makeKeyAndOrderFront:self];
}

-(IBAction)reloadMediaListing:(id)sender
{
	[mediaTableView reloadData];
}

#pragma mark Table View Delegate Methods
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
	return [[[AppController currentDoc] mediaProperties] count];
}

- (id) tableView:(NSTableView*) aTableView objectValueForTableColumn:(NSTableColumn*) tableColumn row:(NSInteger) rowIndex {
	NSString *identifier = [tableColumn identifier];
	VideoProperties *video = [[[AppController currentDoc] mediaProperties] objectAtIndex:rowIndex];
	if([identifier isEqualToString:@"active"])
	{
		return [NSNumber numberWithBool:[video enabled]];
	}
	else if([identifier isEqualToString:@"hasVideo"])
	{
		return [video hasVideo] ? @"•" : @"";
	}
	else if([identifier isEqualToString:@"hasAudio"])
	{
		return [video hasAudio] ? @"•" : @"";
	}
	else if([identifier isEqualToString:@"offset"])
	{
		NSTimeInterval interval;
		interval = CMTimeGetSeconds([video offset]);
		return [NSNumber numberWithDouble:interval];
	}
	else if([identifier isEqualToString:@"title"])
	{
		return [video title];
	}
	else {
		return nil;
	}

}

//- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
//	NSTextFieldCell *cell = [tableColumn dataCell];
//	if([[tableColumn identifier] isEqualToString:@"names"])
//	{
//		AnnotationCategory *category = [[[AppController currentDoc] categories] objectAtIndex:rowIndex];
//		[cell setBackgroundColor:[category color]];	
//	}
//	return cell;
//}

- (void)    tableView:(NSTableView*) tv setObjectValue:(id) val 
	   forTableColumn:(NSTableColumn*) aTableColumn row:(NSInteger) rowIndex
{
    if([[aTableColumn identifier] isEqualToString:@"active"])
    {
		VideoProperties *video = [[[AppController currentDoc] mediaProperties] objectAtIndex:rowIndex];		
		[video setEnabled:[val boolValue]];
		[[AppController currentApp] setRate:[[[AppController currentApp] movie] rate] fromSender:self];
    }
	else if([[aTableColumn identifier] isEqualToString:@"offset"])
    {
		CMTime offset = CMTimeMakeWithSeconds([val floatValue], 600);
		if(offset.value == 0)
		{
			offset = kCMTimeZero;
		}
		
		VideoProperties *video = [[[AppController currentDoc] mediaProperties] objectAtIndex:rowIndex];
		[video setOffset:offset];
		[[AppController currentDoc] saveVideoProperties:video];
    }
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	return ([[tableColumn identifier] isEqualToString:@"active"] || [[tableColumn identifier] isEqualToString:@"offset"]);
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if(([mediaTableView selectedRow] > -1) && ([mediaTableView selectedRow] < [[[AppController currentDoc] mediaProperties] count]))
	{	
		[editMediaButton setEnabled:YES];
		[removeMediaButton setEnabled:YES];
	}
	else
	{
		[editMediaButton setEnabled:NO];
		[removeMediaButton setEnabled:NO];
	}
}

@end
