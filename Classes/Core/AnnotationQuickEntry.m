//
//  AnnotationQuickEntry.m
//  DataPrism
//
//  Created by Adam Fouse on 4/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AnnotationQuickEntry.h"
#import "AnnotationDocument.h"
#import "MAAttachedWindow.h"
#import "Annotation.h"
#import "AnnotationCategory.h"
#import "TimelineView.h"
#import "ColorCell.h"
#import "AFHUDOutlineView.h"

@interface AnnotationQuickEntry (AnnotationQuickEntryPrivateMethods)

- (void)finishQuickEntry;
- (BOOL)handleKeyDownEvent:(NSEvent*)theEvent;

@end

@implementation AnnotationQuickEntry

- (id) init
{
	self = [super init];
	if (self != nil) {
		shortcuts = [[NSMutableArray alloc] init];
	}
	return self;
}


- (void) dealloc
{
    if(hoverWindow)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:categoriesView];
        [hoverWindow release];
    }
	[shortcuts release];
	[super dealloc];
}


- (void)displayQuickEntryWindowAtTime:(QTTime)time inTimeline:(TimelineView*)timeline
{
	[self displayQuickEntryWindowAtTime:time inTimeline:timeline forCategory:nil];
}

- (void)displayQuickEntryWindowAtTime:(QTTime)time inTimeline:(TimelineView*)timeline forCategory:(AnnotationCategory*)category
{	
	NSWindow  *mMovieWindow = [timeline window];
	
	NSPoint bottom = [mMovieWindow convertBaseToScreen:[timeline convertPoint:[timeline frame].origin toView:nil]];
	
	int position = MAPositionRight;
	if(bottom.y < 190)
	{
		position = MAPositionRightTop;
	}
	
	
	// Find the x coordinate in window-space
	NSPoint point = [timeline pointFromTime:time];
	point = [[mMovieWindow contentView] convertPoint:point fromView:timeline];
	if(point.x + [quickEntryView frame].size.width > [[mMovieWindow contentView] bounds].size.width)
	{
		position = MAPositionLeft;
	}
	
	// Find the y coordinate so that it's at the middle of the timeline
	point.y = point.y + [timeline frame].size.height/2.0;
	
	[shortcuts removeAllObjects];
	for(AnnotationCategory *category in [[AnnotationDocument currentDocument] categories])
	{
		for(AnnotationCategory *value in [category values])
		{
			if([[value keyEquivalent] length] > 0)
			{
				[shortcuts addObject:[value keyEquivalent]];
			}
		}
		if(([[category values] count] == 0) && ([[category keyEquivalent] length] > 0))
		{
			[shortcuts addObject:[category keyEquivalent]];
		}
		
	}
	
	if(hoverWindow)
	{
		[annotationTextField setString:@""];
		[hoverWindow setPoint:point side:position];
	}
	else
	{
		NSTableColumn* column;
		ColorCell* colorCell;
		column = [[categoriesView tableColumns] objectAtIndex: 2];
		colorCell = [[[ColorCell alloc] init] autorelease];
		[colorCell setEditable: YES];
		[colorCell setTarget: self];
		[colorCell setAction: @selector (colorClick:)];
		[column setDataCell: colorCell];
		
		hoverWindow = [[MAAttachedWindow alloc] initWithView:quickEntryView
											 attachedToPoint:point 
													inWindow:mMovieWindow 
													  onSide:position
												  atDistance:0];
		[hoverWindow setViewMargin:5.0];
		[hoverWindow setReleasedWhenClosed:NO];
		
		[annotationTextField setDelegate:self];
		[annotationTextField setString:@""];
		[annotationTextField setTextColor:[NSColor whiteColor]];
		
		[categoriesView setAllowsTypeSelect:YES];
		[(AFHUDOutlineView*)categoriesView setNextView:annotationTextField];
        [categoriesView reloadData];
        
        [[NSNotificationCenter defaultCenter] addObserver:categoriesView
                                                 selector:@selector(reloadData)
                                                     name:CategoriesChangedNotification
                                                   object:nil];
	}
	
	typeSelect = NO;
	[mMovieWindow addChildWindow:hoverWindow ordered:NSWindowAbove];
	[hoverWindow makeKeyAndOrderFront:self];
	[categoriesView expandItem:nil expandChildren:YES];
	if(category)
	{
		NSInteger catIndex = [categoriesView rowForItem:category];
		[categoriesView selectRowIndexes:[NSIndexSet indexSetWithIndex:catIndex] byExtendingSelection:NO];
		[hoverWindow makeFirstResponder:annotationTextField];
	}
	else
	{
		[hoverWindow makeFirstResponder:categoriesView];
		[categoriesView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
	
	currentTime = time;
}

- (void)cancelQuickEntry
{
	[[hoverWindow parentWindow] removeChildWindow:hoverWindow];
	[hoverWindow close];
}

- (void)finishQuickEntry
{
	if([hoverWindow isVisible])
	{
		Annotation* annotation = [[Annotation alloc] initWithQTTime:currentTime];
		AnnotationCategory *category = (AnnotationCategory*)[categoriesView itemAtRow:[categoriesView selectedRow]];
		[annotation setCategory:category];
		
		NSString *annotationText = [annotationTextField string];
		if(!annotationText)
		{
			annotationText = @"";
		}
		[annotation setAnnotation:annotationText];
		
		[[AnnotationDocument currentDocument] addAnnotation:annotation];
		
		[annotation release];
		
		[[hoverWindow parentWindow] removeChildWindow:hoverWindow];
		[hoverWindow close];
		
		if(actionSelector)
		{
			[NSApp sendAction:actionSelector to:actionTarget from:self];	
		}
		
	}

}

- (void)setEntryTarget:(id)target
{
	actionTarget = target;
}

- (void)setEntrySelector:(SEL)selector
{
	actionSelector = selector;
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)commandSelector
{	
	if(commandSelector == @selector(insertNewline:))
	{
		[self finishQuickEntry];
		return YES;
		//return NO;
	}
	else if(commandSelector == @selector(insertTab:))
	{
		[hoverWindow makeFirstResponder:categoriesView];
		return YES;
	}
	else if (commandSelector == @selector(cancelOperation:)) {
		NSLog(@"cancel");
		[self cancelQuickEntry];
		return YES;
	}
	else
	{
		return NO;
	}
}

#pragma mark Outline View

- (NSString *)outlineView:(NSOutlineView *)outlineView typeSelectStringForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSString* shortcut = [(AnnotationCategory*)item keyEquivalent];
	if(shortcut && ([shortcut length] > 0))
	{
		return shortcut;
	}
	else
	{
		return [(AnnotationCategory*)item name];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldTypeSelectForEvent:(NSEvent *)event withCurrentSearchString:(NSString *)searchString
{
	if([searchString caseInsensitiveCompare:[(AnnotationCategory*)[outlineView itemAtRow:[outlineView selectedRow]] keyEquivalent]] == NSOrderedSame)
	{
		[self finishQuickEntry];
		return NO;
	}
	typeSelect = YES;
	return YES;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	
    return (item == nil) ? [[[AnnotationDocument currentDocument] categories] count] : [[item values] count];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return ([[item values] count] > 0) ? YES : NO;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	
    if(item == nil)
	{
		return [[[AnnotationDocument currentDocument] categories] objectAtIndex:index];
	} else 
	{
		return [[(AnnotationCategory *)item values] objectAtIndex:index];
	}
}


- (NSIndexSet *)outlineView:(NSOutlineView *)outlineView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
	if([[(AnnotationCategory*)[categoriesView itemAtRow:[proposedSelectionIndexes firstIndex]] values] count] > 0)
	{
		return [NSIndexSet indexSetWithIndex:[proposedSelectionIndexes firstIndex] + 1];
	}
	else
	{
		return proposedSelectionIndexes;
	}
	
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	AnnotationCategory *category = (AnnotationCategory*)item;
	if([[tableColumn identifier] isEqualToString:@"Category"])
	{
		return category.name;
	}
	else if([[tableColumn identifier] isEqualToString:@"Color"])
	{
		return category.color;
	}
	else if([[tableColumn identifier] isEqualToString:@"Shortcut"])
	{
		NSString* shortcutKey = category.keyEquivalent;
		if(!shortcutKey)
		{
			return @"";
		}
		else
		{
			return shortcutKey;
		}
	}
	return @"";
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	[self finishQuickEntry];
	return NO;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if([[tableColumn identifier] isEqualToString:@"Category"])
	{
		[(AnnotationCategory*)item setName:object];
	}
}

- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	if(typeSelect && ([categoriesView selectedRow] >= 0))
	{
		[self finishQuickEntry];
	}
	typeSelect = NO;
}


@end
