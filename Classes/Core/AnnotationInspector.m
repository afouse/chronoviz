//
//  AnnotationInspector.m
//  Annotation
//
//  Created by Adam Fouse on 6/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationInspector.h"
#import "Annotation.h"
#import "AppController.h"
#import "DataPrismLog.h"
#import "AnnotationDocument.h"
#import "TimelineView.h"
#import "VideoProperties.h"
#import "NSColorHexadecimalValue.h"
#import "AnnotationCategory.h"
#import "ColorCell.h"

@implementation AnnotationInspector

- (id) init
{
	self = [super init];
	if (self != nil) {
		annotationsInCategory = [[NSMutableArray alloc] init];
		colors = [[NSArray alloc] initWithObjects:
				  @"Blue",
				  @"Red",
				  @"Green",
				  @"Orange",
				  @"Yellow",
				  nil];
		
	}
	return self;
}

- (void)awakeFromNib
{
	NSTableColumn* column;
	ColorCell* colorCell;
	
	column = [[categoriesTable tableColumns] objectAtIndex: 0];
	[column setIdentifier:@"color"];
	colorCell = [[[ColorCell alloc] init] autorelease];
    [colorCell setEditable: YES];
	[colorCell setTarget: self];
	[colorCell setAction: @selector (colorClick:)];
	[column setDataCell: colorCell];
	
	// Category selection sheet
	column = [categoryOutlineView tableColumnWithIdentifier:@"Color"];
	//column = [[categoryOutlineView tableColumns] objectAtIndex: 2];
	colorCell = [[[ColorCell alloc] init] autorelease];
	[colorCell setEditable: YES];
	[colorCell setTarget: self];
	//[colorCell setAction: @selector (colorClick:)];
	[column setDataCell: colorCell];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(buildCategoryList)
												 name:CategoriesChangedNotification
											   object:nil];
    
}
		
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[colors release];
	[annotationsInCategory release];
	[super dealloc];
}


-(NSWindow*)window
{
	return inspector;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender
{
	return [[AppController currentApp] undoManager];
}

-(void)configureWindow
{
	if([annotation isDuration])
	{
		[startTimeLabel setStringValue:@"Start Time:"];
		[endTimeLabel setHidden:NO];
		[endTimeButton setHidden:NO];
		[endTimeField setHidden:NO];
		[useAsCategoryButton setHidden:NO];
	} else {
		[startTimeLabel setStringValue:@"Time:"];
		[endTimeLabel setHidden:YES];
		[endTimeButton setHidden:YES];
		[endTimeField setHidden:YES];
		[useAsCategoryButton setHidden:YES];
	}
	if([annotation isCategory])
	{
		NSRect position = [colorButton frame];
		NSRect colorFrame = [colorWell frame];
		colorFrame.origin.x = position.origin.x + 2;
		[colorWell setFrame:colorFrame];
		[colorButton setHidden:YES];
		[colorWell setHidden:NO];
		[colorLabel setHidden:NO];
		[colorLabel setStringValue:@"Color:"];
		
		CGFloat height = ([categoriesLabel frame].origin.y + [categoriesLabel frame].size.height) - [categoriesScrollView frame].origin.y ;
		
		NSRect tableFrame = [categoriesScrollView frame];
		tableFrame.size.height = height;
		[categoriesScrollView setFrame:tableFrame];
		[categoriesLabel setHidden:NO];
	}
	else
	{
		//[colorButton setHidden:NO];
		[colorWell setHidden:YES];
		[colorLabel setStringValue:@"Categories:"];
		
		[colorButton setHidden:YES];
		[categoriesLabel setHidden:YES];
		
		CGFloat height = ([colorButton frame].origin.y + [colorButton frame].size.height) - [categoriesScrollView frame].origin.y ;
		
		NSRect tableFrame = [categoriesScrollView frame];
		tableFrame.size.height = height;
		[categoriesScrollView setFrame:tableFrame];
	}
	[categoriesTable reloadData];
}

-(void)buildCategoryList
{
	//VideoProperties *properties = [[AppController currentApp] videoProperties];
	
	NSArray* categories = [[AppController currentDoc] categories];
	
	if([categories count] > 0)
	{
		[colorButton removeAllItems];
		[colorButton addItemWithTitle:@""];
		
		[[colorButton menu] addItem:[NSMenuItem separatorItem]];
		
		BOOL annotationCategories = NO;
		
		// First add all the categories tied to annotations
		for(AnnotationCategory *category in categories)
		{
			if([category annotation])
			{
				annotationCategories = YES;
				[colorButton addItemWithTitle:[category name]];
				[[colorButton lastItem] setRepresentedObject:category];
			}
		}
		
		if(annotationCategories)
			[[colorButton menu] addItem:[NSMenuItem separatorItem]];
		
		// Then add the default and custom categories
		for(AnnotationCategory *category in categories)
		{
			if(![category annotation])
			{
				if([[category values] count] == 0)
				{
					[colorButton addItemWithTitle:[category name]];
					[[colorButton lastItem] setRepresentedObject:category];
				}
				else
				{
					for(AnnotationCategory *value in [category values])
					{
						[colorButton addItemWithTitle:[NSString stringWithFormat:@"%@ : %@",[category name],[value name]]];
						[[colorButton lastItem] setRepresentedObject:value];
					}
				}
			}
		}
		
		[colorLabel setStringValue:@"Category:"];
	}
	else if ([categories count] == 0)
	{
		[colorButton removeAllItems];
		[colorButton addItemsWithTitles:colors];
		[colorLabel setStringValue:@"Color:"];
	}
	
	NSPopUpButtonCell *tableButton = [[[categoriesTable tableColumns] objectAtIndex:1] dataCell];
	[tableButton removeAllItems];
	
	for(NSMenuItem *item in [[colorButton menu] itemArray])
	{
		if([item isSeparatorItem])
		{
			[[tableButton menu] addItem:[NSMenuItem separatorItem]];
		}
		else
		{
			[tableButton addItemWithTitle:[item title]];
		}
	}
}


- (void)setAnnotation:(Annotation*)theAnnotation
{
	
	[self buildCategoryList];
	
	[self willChangeValueForKey:@"annotation"];
	
	// First, save current annotation
	[self saveChanges];

	// Now deal with the new annotation
	
	annotation = theAnnotation;
	
	if(annotation == nil)
	{
		BOOL hide = YES;
		[startTimeLabel setHidden:hide];
		[endTimeLabel setHidden:hide];
		[startTimeField setHidden:hide];
		[endTimeField setHidden:hide];
		
		[startTimeStepper setHidden:hide];
		[startTimeButton setHidden:hide];
		[endTimeButton setHidden:hide];
		[typeButton setHidden:hide];
		[titleField setHidden:hide];
		[annotationField setHidden:hide];
		[keywordsField setHidden:hide];
		[colorLabel setHidden:hide];
		[colorButton setHidden:hide];
		[titleFieldLabel setHidden:hide];
		[annotationFieldLabel setHidden:hide];
		
		[typeButtonLabel setHidden:hide];
		[keywordsFieldLabel setHidden:hide];
		
		[categoriesScrollView setHidden:hide];
		[categoriesTable setHidden:hide];
		[categoriesLabel setHidden:hide];
		[addCategoryButton setHidden:hide];
		[removeCategoryButton setHidden:hide];
		
		[useAsCategoryButton setHidden:hide];
		[colorWell setHidden:hide];
		
		[saveAnnotationButton setEnabled:!hide];
		[deleteAnnotationButton setEnabled:!hide];
		
		[titleField setStringValue:@""];
		//[titleField setEnabled:NO];
		[annotationField setStringValue:@""];
		//[annotationField setEnabled:NO];
		[keywordsField setObjectValue:[NSArray array]];
		//[captionField setEnabled:NO];
		return;
	} 
	else
	{	
		
		BOOL hide = NO;
		[startTimeLabel setHidden:hide];
		[endTimeLabel setHidden:hide];
		[startTimeField setHidden:hide];
		[endTimeField setHidden:hide];
		
		[startTimeStepper setHidden:hide];
		[startTimeButton setHidden:hide];
		[endTimeButton setHidden:hide];
		[typeButton setHidden:hide];
		[titleField setHidden:hide];
		[annotationField setHidden:hide];
		[keywordsField setHidden:hide];
		[colorLabel setHidden:hide];
		[colorButton setHidden:hide];
		[titleFieldLabel setHidden:hide];
		[annotationFieldLabel setHidden:hide];
		
		[typeButtonLabel setHidden:hide];
		[keywordsFieldLabel setHidden:hide];
		
		[categoriesScrollView setHidden:hide];
		[categoriesTable setHidden:hide];
		[categoriesLabel setHidden:hide];
		[addCategoryButton setHidden:hide];
		[removeCategoryButton setHidden:hide];
		
		[useAsCategoryButton setHidden:hide];
		[colorWell setHidden:hide];
		
		[saveAnnotationButton setEnabled:!hide];
		[deleteAnnotationButton setEnabled:!hide];
		
		[titleField setEnabled:YES];
		[annotationField setEnabled:YES];
		[keywordsField setEnabled:YES];
		
		//[startTimeField setStringValue:[annotation startTimeString]];
		
		if([annotation isDuration])
		{
			[typeButton selectItemAtIndex:1];
			
			if([annotation category])
			{
				[colorButton selectItemWithTitle:[[annotation category] name]];
			} 
			else if([annotation color])
			{
				[colorButton selectItemWithTitle:[annotation color]];
			} else {
				[colorButton selectItemAtIndex:0];
			}
			
			if([annotation isCategory])
			{
				[useAsCategoryButton setState:NSOnState];
				[colorWell setColor:[annotation colorObject]];
				
				[annotationsInCategory removeAllObjects];
				
				NSArray *annotations = [[AppController currentDoc] annotations];
				for(Annotation* ann in annotations)
				{
					if([ann category] == [annotation category])
					{
						[annotationsInCategory addObject:ann];
					}
				}
			}
			else
			{
				[useAsCategoryButton setState:NSOffState];
			}
			
		} else {
			[typeButton selectItemAtIndex:0];
			
			if([annotation category])
			{
				[colorButton selectItemWithTitle:[[annotation category] name]];
			} 
			else if([annotation textColor])
			{
				[colorButton selectItemWithTitle:[annotation textColor]];
			} else {
				[colorButton selectItemAtIndex:0];
			}
			
			[useAsCategoryButton setState:NSOffState];
		}
		
		[titleField setStringValue:[annotation title]];
		[annotationField setStringValue:[annotation annotation]];
		
		[keywordsField setObjectValue:[annotation keywords]];
		
		[self configureWindow];
	
	}
	
	[self didChangeValueForKey:@"annotation"];
}

/*
- (IBAction)toggleUseAsCategory:(id)sender
{
	if([useAsCategoryButton state])
	{
		[annotation setIsCategory:YES];
		AnnotationCategory *category = [[AnnotationCategory alloc] init];
		[category setAnnotation:annotation];
		[annotation setCategory:category];
		[[[[AppController currentApp] videoProperties] categories] addObject:category];
		[annotation setColorObject:[colorWell color]];
		
		[annotation setUpdated];
		[category release];
	}
	else
	{
		[annotation setIsCategory:NO];
		[[AnnotationDocument currentDocument] removeCategory:[annotation category]];
		
		[self buildCategoryList];
	}
	[self configureWindow];
}
 */

- (IBAction)setColor:(id)sender
{
	NSString *color = nil;
	AnnotationCategory *category = nil;
	
	if([colorButton indexOfSelectedItem] > 0)
	{
		category = [[colorButton selectedItem] representedObject];
		color = [[category color] hexadecimalValueOfAnNSColor];
	}
	
	
	[annotation setCategory:category];
	if([annotation isDuration])
	{
		[annotation setColor:color];
		[annotation setTextColor:nil];
	}
	else
	{
		[annotation setTextColor:color];
		[annotation setColor:nil];
	}
	[annotation setUpdated];
}

- (IBAction)setColorViaWell:(id)sender
{
	[annotation setColorObject:[colorWell color]];
	[annotation setUpdated];
	for(Annotation *ann in annotationsInCategory)
	{
		[ann setUpdated];
	}
}

- (IBAction)addCategory:(id)sender
{	
	[categoryOutlineView reloadData];
	[categoryOutlineView expandItem:nil expandChildren:YES];
	[categoryOutlineView deselectAll:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:categoryOutlineView
											 selector:@selector(reloadData)
												 name:CategoriesChangedNotification
											   object:[AnnotationDocument currentDocument]];
	
	[NSApp beginSheet:categorySheet
	   modalForWindow:inspector
		modalDelegate:nil
	   didEndSelector:NULL
		  contextInfo:nil];
	
	// Add the first category that isn't already part of the annotation
//	for(NSMenuItem* item in [colorButton itemArray])
//	{
//		AnnotationCategory* category = [item representedObject];
//		if(category && ![[annotation categories] containsObject:category])
//		{
//			[annotation addCategory:category];
//			[categoriesTable reloadData];
//			return;
//		}
//	}
	
//	for(AnnotationCategory* category in [[AppController currentDoc] categories])
//	{		
//		
//		if(![[annotation categories] containsObject:category])
//		{
//			if([[category values] count] > 0)
//			{
//				category = [[category values] objectAtIndex:0];
//			}
//			[annotation addCategory:category];
//			[categoriesTable reloadData];
//			return;
//		}
//	}
}

- (IBAction)removeCategory:(id)sender
{
	AnnotationCategory* category = [[annotation categories] objectAtIndex:[categoriesTable selectedRow]];
	[annotation removeCategory:category];
	[categoriesTable reloadData];
}

- (IBAction)finishCategorySelection:(id)sender
{
	AnnotationCategory *category = (AnnotationCategory*)[categoryOutlineView itemAtRow:[categoryOutlineView selectedRow]];
	if(category && ![[annotation categories] containsObject:category])
	{
		[annotation addCategory:category];
		[categoriesTable reloadData];
	}
	
	[self cancelCategorySelection:self];
}

- (IBAction)cancelCategorySelection:(id)sender
{
	[NSApp endSheet:categorySheet];
	[categorySheet orderOut:self];
	[[NSNotificationCenter defaultCenter] removeObserver:categoryOutlineView];
}

- (void)selectAnnotationText
{
	[annotationField selectText:self];
}

- (void)saveChanges
{
	if(annotation != nil)
	{
		NSString *title = [titleField stringValue];
//		if([title length] == 0)
//		{
//			NSArray *words = [[annotationField stringValue] componentsSeparatedByString:@" "];
//			if([words count] < 5)
//			{
//				title = [annotationField stringValue];
//			} else if (words) {
//				title = [NSString stringWithFormat:@"%@ %@ %@ %@...",[words objectAtIndex:0],[words objectAtIndex:1],[words objectAtIndex:2],[words objectAtIndex:3]];
//			}
//		}
		[annotation setTitle:title];
		[annotation setAnnotation:[annotationField stringValue]];
		[annotation setKeywords:[keywordsField objectValue]];
		
		if([typeButton indexOfSelectedItem] == 1)
		{
			[annotation setIsDuration:YES];
		}
		
		
		
		[annotation setUpdated];
		
		if([annotation keyframeImage])
		{
			[[AppController currentApp] updateAnnotationKeyframe:annotation];
		}
		
		//[[AppController currentApp] updateAnnotation:annotation];
		[[AppController currentDoc] saveAnnotations];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	//NSLog(@"Window will close");

	// Finalize any editors
	[inspector makeFirstResponder:inspector];
	
	[self saveChanges];
	[[AppController currentApp] setSelectedAnnotation:nil];
}

- (IBAction)changeType:(id)sender
{
	if([typeButton indexOfSelectedItem] == 1)
	{
		[startTimeLabel setStringValue:@"Start Time:"];
		[endTimeLabel setHidden:NO];
		[endTimeButton setHidden:NO];
		[endTimeField setHidden:NO];
		[useAsCategoryButton setHidden:NO];
		[annotation setIsDuration:YES];
		CMTime qttime = [annotation startTime];
		NSTimeInterval duration;
		duration = CMTimeGetSeconds([[[AppController currentDoc] movie] duration]);
		qttime.value += qttime.timescale * (duration * .1);
		[annotation setEndTime:qttime];
		[endTimeField setStringValue:[annotation endTimeString]];
		if([colorButton indexOfSelectedItem] > 0)
		{
			[annotation setColor:[colorButton titleOfSelectedItem]];
			[annotation setTextColor:nil];
		}
		
		NSUndoManager* undoManager = [[AppController currentApp] undoManager];
		[[undoManager prepareWithInvocationTarget:annotation] setIsDuration:NO];
		[undoManager setActionName:@"Change Annotation Type"];
		
		[[[AppController currentApp] interactionLog] addEditOfAnnotation:annotation
															forAttribute:@"Type" 
															   withValue:@"Duration"];
		
	} else {
		[startTimeLabel setStringValue:@"Time:"];
		[endTimeLabel setHidden:YES];
		[endTimeButton setHidden:YES];
		[endTimeField setHidden:YES];
		[annotation setIsDuration:NO];
		[useAsCategoryButton setHidden:YES];
		if([colorButton indexOfSelectedItem] > 0)
		{
			[annotation setTextColor:[colorButton titleOfSelectedItem]];
			[annotation setColor:nil];
		}
		
		NSUndoManager* undoManager = [[AppController currentApp] undoManager];
		[[undoManager prepareWithInvocationTarget:annotation] setIsDuration:YES];
		[undoManager setActionName:@"Change Annotation Type"];
		
		[[[AppController currentApp] interactionLog] addEditOfAnnotation:annotation
															forAttribute:@"Type" 
															   withValue:@"Point"];
	}
	[annotation setUpdated];
}


// Sets the start time to the current movie time
- (IBAction)setStartTime:(id)sender
{
	CMTime time = [[[AppController currentApp] movie] currentTime];
	[annotation setStartTime:time];

}

// Sets the end time to the current movie time
- (IBAction)setEndTime:(id)sender
{	
	CMTime time = [[[AppController currentApp] movie] currentTime];
	[annotation setEndTime:time];
}

- (IBAction)saveAndContinue:(id)sender
{
//	[inspector close];
	[[AppController currentApp] bringVideoToFront];
	[[AppController currentApp] resumePlaying];
	[[AppController currentApp] setSelectedAnnotation:nil];
//	[self setAnnotation:nil];
}

- (Annotation*)annotation
{
	return annotation;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"selectedAnnotation"]) {
		[self setAnnotation:[object selectedAnnotation]];
		[self selectAnnotationText];
		//[inspector setIsVisible:YES];
    }
	else
	{
    [super observeValueForKeyPath:keyPath
						 ofObject:object
						   change:change
						  context:context];
	}
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {
	//NSLog(NSStringFromSelector(commandSelector));

	if([annotationField currentEditor])
	{
		if(commandSelector == @selector(insertNewline:))
		{
			[fieldEditor insertNewlineIgnoringFieldEditor:nil];
			return YES;
		}
		else
		{
			return NO;
		}
	}
	
	if([keywordsField currentEditor])
	{
		return NO;
	}
	
	BOOL retval = NO;
	if (commandSelector == @selector(moveRight:)) {
		retval = YES;
		[[AppController currentApp] stepOneFrameForward:self];
	}
	else if (commandSelector == @selector(moveLeft:)) {
		retval = YES;
		[[AppController currentApp] stepOneFrameBackward:self];
	}
	else if ((commandSelector == @selector(scrollPageDown:))
			 || (commandSelector == @selector(moveDown:))) {
		retval = YES;
		[[AppController currentApp] stepForward:self];
	}
	else if ((commandSelector == @selector(scrollPageUp:))
			 || (commandSelector == @selector(moveUp:))) {
		retval = YES;
		[[AppController currentApp] stepBack:self];
	}
	else if (commandSelector == @selector(cancel:)) {
		retval = YES;
		[[AppController currentApp] togglePlay:self];
	}


	if([startTimeField currentEditor])
	{
		if(retval)
		{
			[self setStartTime:self];
		}
		else if(([[startTimeField currentEditor] selectedRange].length == 0)
			&& (commandSelector == @selector(insertNewline:)))
		{
			retval = YES;
			[startTimeField selectText:self];
		}
	}
	else if([endTimeField currentEditor])
	{
		[self setEndTime:self];
	}	
	
	return retval;
}

#pragma mark Keywords TokenView Delegate

- (NSArray *)tokenField:(NSTokenField *)tokenFieldArg 
completionsForSubstring:(NSString *)substring 
		   indexOfToken:(NSInteger)tokenIndex 
	indexOfSelectedItem:(NSInteger *)selectedIndex 
{
	
    NSArray *keywords = [[AnnotationDocument currentDocument] keywords];
    NSArray *matchingKeywords = [keywords filteredArrayUsingPredicate:
							   [NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", substring]];
    return matchingKeywords;
}

#pragma mark TableView Delegate
// Table View
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
	return [[annotation categories] count];
}

- (id) tableView: (NSTableView*) aTableView objectValueForTableColumn: 
(NSTableColumn*) tableColumn row: (NSInteger) rowIndex {
	AnnotationCategory* category = [[annotation categories] objectAtIndex:rowIndex];

	if([[tableColumn identifier] isEqualToString:@"color"])
	{
		return category.color;
	}
	else
	{
		int index = [[colorButton menu] indexOfItemWithRepresentedObject:category];
		
		return [NSNumber numberWithInteger:index];
	}
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	AnnotationCategory *category = [[[colorButton menu] itemAtIndex:[object intValue]] representedObject];
	if(category)
	{
		[annotation replaceCategory:[[annotation categories] objectAtIndex:row] withCategory:category];
		[tableView reloadData];
	}
	else
	{
		[tableView deselectAll:self];
		[annotation removeCategory:[[annotation categories] objectAtIndex:row]];
		[tableView reloadData];
	}
	
	
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[removeCategoryButton setEnabled:[categoriesTable selectedRow] > -1];
}

# pragma mark Categories

- (void) colorClick: (id) sender {    // sender is the table view
	NSColorPanel* panel;
	
	editingCategory = [[annotation categories] objectAtIndex:[sender clickedRow]];
	NSColor *color = [editingCategory color];
	panel = [NSColorPanel sharedColorPanel];
	[panel setTarget: self];
	[panel setColor: color];
	[panel setContinuous:NO];
	[panel setAction: @selector (colorChanged:)];
	[panel makeKeyAndOrderFront: self];
}

- (void) colorChanged: (id) sender {    // sender is the NSColorPanel
	[editingCategory setColor:[sender color]];
	[categoriesTable reloadData];
}

#pragma mark Categories Outline View

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
		[self finishCategorySelection:self];
		return NO;
	}
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
	if([[(AnnotationCategory*)[categoryOutlineView itemAtRow:[proposedSelectionIndexes firstIndex]] values] count] > 0)
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
	[self finishCategorySelection:self];
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
	[self finishCategorySelection:self];
}


#pragma mark Key Value Observing

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
	BOOL automatic = NO;
	
    if ([theKey isEqualToString:@"annotation"]) {
        automatic=NO;
    } else {
        automatic=[super automaticallyNotifiesObserversForKey:theKey];
    }
	
    return automatic;
}

@end
