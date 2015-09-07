//
//  AnnotationTableView.m
//  Annotation
//
//  Created by Adam Fouse on 10/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationTableView.h"
#import "AnnotationDocument.h"
#import "AnnotationTableController.h"

@implementation AnnotationTableView

- (void)deleteSelection
{
	NSIndexSet *selectedRows = [self selectedRowIndexes];
	
	NSString *message;
	if([selectedRows count] < 1)
	{
		return;
	}
	else if ([selectedRows count] == 1)
	{
		message = @"Are you sure you want to delete the currently selected annotation?";
	}
	else
	{
		message = @"Are you sure you want to delete the currently selected annotations?";
	}
	
	NSAlert *confirmation = [[NSAlert alloc] init];
	[confirmation setMessageText:message];
	[[confirmation addButtonWithTitle:@"Delete"] setKeyEquivalent:@""];
	[[confirmation addButtonWithTitle:@"Cancel"] setKeyEquivalent:@"\r"];
	
	NSInteger result = [confirmation runModal];
	
	if(result == NSAlertFirstButtonReturn)
	{
		NSArray *selected = [(AnnotationTableController*)[self delegate] annotationForIndexSet:selectedRows];
		[self deselectAll:self];
		[[AnnotationDocument currentDocument] removeAnnotations:selected];
	}
}

- (void)deleteBackward:(id)inSender
{
	[self deleteSelection];
}

- (void)deleteForward:(id)inSender
{
	[self deleteSelection];
}

- (void)keyDown:(NSEvent*)event
{
	BOOL deleteKeyEvent = NO;
	
	if ([event type] == NSKeyDown)
	{
		NSString* pressedChars = [event characters];
		if ([pressedChars length] == 1)
		{
			unichar pressedUnichar = [pressedChars characterAtIndex:0];

			if ( (pressedUnichar == NSDeleteCharacter) || (pressedUnichar == NSDeleteFunctionKey) )
			{
				deleteKeyEvent = YES;
			}
		}
	}
	
	if (deleteKeyEvent)
	{
		// This will end up calling deleteBackward: or deleteForward:.
		[self interpretKeyEvents:[NSArray arrayWithObject:event]];
	}
	else
	{
		[super keyDown:event];
	}
}

@end
