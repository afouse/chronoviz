//
//  CategoriesWindowController.m
//  Annotation
//
//  Created by Adam Fouse on 1/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CategoriesWindowController.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "AnnotationCategory.h"
#import "ColorCell.h"
#import "DPExportCategories.h"

#define SIMPLE_BPOARD_TYPE           @"DPCategoriesOutlineViewPboardType"

@implementation CategoriesWindowController

- (id)init
{
	if(![super initWithWindowNibName:@"CategoriesWindow"])
		return nil;
	
	colorPanel = nil;
	editingCategory = nil;
	
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void)awakeFromNib {
    // Register to get our custom type, strings, and filenames. Try dragging each into the view!
    //[outlineView registerForDraggedTypes:[NSArray arrayWithObjects:SIMPLE_BPOARD_TYPE, NSFilenamesPboardType, nil]];
	[outlineView registerForDraggedTypes:[NSArray arrayWithObjects:SIMPLE_BPOARD_TYPE, nil]];
    [outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    [outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
}

- (void)windowDidLoad
{
	
	NSTableColumn* column;
	ColorCell* colorCell;
	
//	column = [[tableView tableColumns] objectAtIndex: 1];
//	colorCell = [[[ColorCell alloc] init] autorelease];
//    [colorCell setEditable: YES];
//	[colorCell setTarget: self];
//	[colorCell setAction: @selector (colorClick:)];
//	[column setDataCell: colorCell];
	
	column = [[outlineView tableColumns] objectAtIndex: 2];
	colorCell = [[[ColorCell alloc] init] autorelease];
    [colorCell setEditable: YES];
	[colorCell setTarget: self];
	[colorCell setAction: @selector (colorClick:)];
	[column setDataCell: colorCell];
	
}

- (IBAction)showWindow:(id)sender
{
	//[tableView reloadData];
	[outlineView reloadData];
	[super showWindow:sender];
}

- (BOOL)windowShouldClose:(NSNotification *)notification
{
    if([outlineView currentEditor])
    {
        if (![[self window] makeFirstResponder:[self window]]) {
            /* Force first responder to resign. */
            [[self window] endEditingFor:nil];
        }
    }
    
    if([[self window] attachedSheet])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (void)windowWillClose:(NSNotification *)notification
{

    
	if(colorPanel)
	{
		[colorPanel setTarget:nil];
	}
	[[AppController currentDoc] saveCategories];
}

-(IBAction)addValue:(id)sender
{
	AnnotationCategory *category = [outlineView itemAtRow:[outlineView selectedRow]];
	if([category category])
	{
		category = [category category];
	}
	
	AnnotationCategory *value = [[AnnotationCategory alloc] init];
	[value setName:@"Possible value"];
	[category addValue:value];
	
	[outlineView reloadItem:category reloadChildren:YES];
	[outlineView expandItem:category];
	
	NSUInteger index = [outlineView rowForItem:value];
	
	[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	
	[outlineView editColumn:0 row:index withEvent:nil select:YES];
}

-(IBAction)addCategory:(id)sender
{
	NSString *name = @"New Category...";
	AnnotationCategory *category = [[AnnotationCategory alloc] init];
	[category setName:name];
	[category setColor:[NSColor greenColor]];	
	[[AppController currentDoc] addCategory:category];
	[outlineView reloadData];
	
	NSUInteger index = [outlineView rowForItem:category];
	[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[outlineView editColumn:0 row:index withEvent:nil select:YES];
//	[tableView reloadData];
//	[tableView editColumn:0 row:[[[AppController currentDoc] categories] count] - 1 withEvent:nil select:YES];
}

-(IBAction)removeCategory:(id)sender
{
	int index = [outlineView selectedRow];
	
	AnnotationCategory *category = [outlineView itemAtRow:index];
	
	if([category category])
	{
		[[category category] removeValue:category];
	}
	else
	{
		[[AppController currentDoc] removeCategory:category];
	}
	
	[outlineView reloadData];
	
//	int index = [tableView selectedRow];
//	AnnotationCategory *category = [[[AppController currentDoc] categories] objectAtIndex:index];
//	
//	[[AppController currentDoc] removeCategory:category];
//	
//	[tableView reloadData];
}

-(IBAction)exportCategories:(id)sender
{
	DPExportCategories* exporter = [[DPExportCategories alloc] init];
	[exporter export:[AnnotationDocument currentDocument]];
	[exporter release];
}

-(IBAction)importCategories:(id)sender
{	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"xml"]];
	
	if ([openPanel runModal] == NSOKButton) {
		NSArray *categories = [NSKeyedUnarchiver unarchiveObjectWithFile:[openPanel filename]];
		
		AnnotationDocument *doc = [AnnotationDocument currentDocument];
		
		if(categories)
		{
			NSArray *oldCategories = [[doc categories] copy];
			
			for(AnnotationCategory *category in oldCategories)
			{
				NSInteger count = [[doc annotationsForCategory:category] count];
				if(count == 0)
				{
					[doc removeCategory:category];	
				}
				else
				{
					for(AnnotationCategory *newcategory in categories)
					{
						if([[category name] isEqualToString:[newcategory name]])
						{
							[newcategory setName:[[newcategory name] stringByAppendingString:@"-Imported"]];
						}
					}
				}
			}
			
			for(AnnotationCategory *category in categories)
			{
				[doc addCategory:category];
			}
			
			[outlineView reloadData];
			
		}	
	}
}

#pragma mark Outline View

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	
    return (item == nil) ? [[[AppController currentDoc] categories] count] : [[item values] count];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return ([[item values] count] > 0) ? YES : NO;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	
    if(item == nil)
	{
		return [[[AppController currentDoc] categories] objectAtIndex:index];
	} else 
	{
		return [[(AnnotationCategory *)item values] objectAtIndex:index];
	}
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	AnnotationCategory *category = (AnnotationCategory*)item;
	if([[tableColumn identifier] isEqualToString:@"Category"])
	{
		return category.name;
	}
	else if([[tableColumn identifier] isEqualToString:@"Shortcut"])
	{
		return category.keyEquivalent;
	}
	else
	{
		return category.color;
	}
}

- (void)outlineView:(NSOutlineView *)theOutlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if([[tableColumn identifier] isEqualToString:@"Category"])
	{
        NSString *newName = (NSString*)object;
        NSArray *compareCategories = nil;
        if([(AnnotationCategory*)item category])
        {
            compareCategories = [[(AnnotationCategory*)item category] values];
        }
        else
        {
            compareCategories = [[AnnotationDocument currentDocument] categories];
        }
        
        for(AnnotationCategory* category in compareCategories)
        {
            if((item != category) && [[category name] isEqualToString:newName])
            {
                NSAlert *samename = [[NSAlert alloc] init];
                if([(AnnotationCategory*)item category])
                {
                    [samename setMessageText:[NSString stringWithFormat:@"Another value in this category is already named “%@”",newName]];
                }
                else
                {
                    [samename setMessageText:[NSString stringWithFormat:@"Another category is already named “%@”",newName]];
                }
                [samename setInformativeText:@"Please choose another name for this category"];
                [samename beginSheetModalForWindow:[self window]
                                     modalDelegate:nil
                                    didEndSelector:NULL
                                       contextInfo:NULL];
                
                NSUInteger columnIndex = [[theOutlineView tableColumns] indexOfObject:tableColumn];
                NSUInteger rowIndex = [theOutlineView rowForItem:item];
                [outlineView editColumn:columnIndex row:rowIndex withEvent:nil select:NO];
                return;
            }
        }
		[(AnnotationCategory*)item setName:object];
	}
	else if([[tableColumn identifier] isEqualToString:@"Shortcut"])
	{
		[(AnnotationCategory*)item setKeyEquivalent:object];
	}
}

- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	[addValueButton setEnabled:([outlineView selectedRow] > -1)];
	[removeCategoryButton setEnabled:([outlineView selectedRow] > -1)];
}

#pragma mark Dragging

static NSString *GenerateUniqueFileNameAtPath(NSString *path, NSString *basename, NSString *extension) {
    NSString *filename = [NSString stringWithFormat:@"%@.%@", basename, extension];
    NSString *result = [path stringByAppendingPathComponent:filename];
    NSInteger i = 1;
    while ([[NSFileManager defaultManager] fileExistsAtPath:result]) {
        filename = [NSString stringWithFormat:@"%@ %ld.%@", basename, (long)i, extension];
        result = [path stringByAppendingPathComponent:filename];
        i++;
    }    
    return result;
}

// We promised the files, so now lets make good on that promise!
- (NSArray *)outlineView:(NSOutlineView *)outlineView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items {
    NSMutableArray *result = nil;
    
    for (NSInteger i = 0; i < [items count]; i++) {
        NSString *filepath  = GenerateUniqueFileNameAtPath([dropDestination path], @"ExportedCategory", @"xml");
        // We write out the tree node's description
        NSError *error = nil;
		
		NSData *categoriesData = [NSKeyedArchiver archivedDataWithRootObject:draggedNodes];
		
		 if (![categoriesData writeToURL:[NSURL fileURLWithPath:filepath] options:0 error:&error]) {
            [NSApp presentError:error];
            
        }
    }
    return result;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    draggedNodes = items; // Don't retain since this is just holding temporaral drag information, and it is only used during a drag!  We could put this in the pboard actually.
    
    // Provide data for our custom type, and simple NSStrings.
    // [pboard declareTypes:[NSArray arrayWithObjects:SIMPLE_BPOARD_TYPE, NSStringPboardType, NSFilesPromisePboardType, nil] owner:self];
	[pboard declareTypes:[NSArray arrayWithObjects:SIMPLE_BPOARD_TYPE, nil] owner:self];
	
    // the actual data doesn't matter since SIMPLE_BPOARD_TYPE drags aren't recognized by anyone but us!.
    [pboard setData:[NSData data] forType:SIMPLE_BPOARD_TYPE]; 
    
    // Put string data on the pboard... notice you can drag into TextEdit!
    //[pboard setString:[draggedNodes description] forType:NSStringPboardType];
    
    // Put the promised type we handle on the pasteboard.
    //[pboard setPropertyList:[NSArray arrayWithObjects:@"txt", nil] forType:NSFilesPromisePboardType];
	
    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex {
    // To make it easier to see exactly what is called, uncomment the following line:
	//   NSLog(@"outlineView:validateDrop:proposedItem:%@ proposedChildIndex:%ld", item, (long)childIndex);
    
    // This method validates whether or not the proposal is a valid one.
    // We start out by assuming that we will do a "generic" drag operation, which means we are accepting the drop. If we return NSDragOperationNone, then we are not accepting the drop.
    NSDragOperation result = NSDragOperationGeneric;
	
	// If the source is the category view
	if([info draggingSource] == outlineView)
	{
		AnnotationCategory *proposedCategory = (AnnotationCategory*)[draggedNodes objectAtIndex:0];
		AnnotationCategory *targetCategory = (AnnotationCategory*)item;
		if(item && ![proposedCategory category])
		{
			// This is a base category, so it can't be dragged to another
			result = NSDragOperationNone;
		}
		else if(!item && [proposedCategory category])
		{
			// This is a category value, so it can needs a target category
			result = NSDragOperationNone;
		}
		else if([proposedCategory category] && [targetCategory category])
		{
			// Can't drag onto an existing value
			result = NSDragOperationNone;
		}
	}
	else
	{
		[outlineView setDropItem:nil dropChildIndex:NSOutlineViewDropOnItemIndex];
	}

    // To see what we decide to return, uncomment this line
	//    NSLog(result == NSDragOperationNone ? @" - Refusing drop" : @" + Accepting drop");
    
    return result;    
}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex {
    //NSArray *oldSelectedNodes = [self selectedNodes];
    
	AnnotationCategory *targetCategory = nil;
	
	if([info draggingSource] == outlineView)
	{
		AnnotationCategory *draggedCategory = (AnnotationCategory*)[draggedNodes objectAtIndex:0];
		
		[draggedCategory retain];
		
		if([item isKindOfClass:[AnnotationCategory class]] && [draggedCategory category])
		{
			// Dropping onto an existing category
			
			targetCategory = (AnnotationCategory*)item;
		
			// If we're moving the category in the 
//			if(targetCategory == [draggedCategory category])
//			{
//				if(childIndex > [[targetCategory values] indexOfObject:draggedCategory])
//				{
//					childIndex--;	
//				}
//			}			
//			
//			[[draggedCategory category] removeValue:draggedCategory];
			
			if (childIndex == NSOutlineViewDropOnItemIndex) {
				if([[targetCategory values] containsObject:draggedCategory])
				{
					[targetCategory moveValue:draggedCategory toIndex:[[targetCategory values] count]];	
				}
				else
				{
					[[draggedCategory category] removeValue:draggedCategory];
					[targetCategory addValue:draggedCategory];
				}
			} else {
				if([[targetCategory values] containsObject:draggedCategory])
				{
					[targetCategory moveValue:draggedCategory toIndex:childIndex];	
				}
				else
				{
					[[draggedCategory category] removeValue:draggedCategory];
					[targetCategory addValue:draggedCategory atIndex:childIndex];
				}
			}
			
		}
		else
		{
//			NSInteger draggedIndex = [[[AnnotationDocument currentDocument] categories] indexOfObject:draggedCategory];
//			if(childIndex > draggedIndex)
//			{
//				childIndex--;	
//			}
//			
//			[[AnnotationDocument currentDocument]removeCategory:draggedCategory];
			
			if (childIndex == NSOutlineViewDropOnItemIndex) {
				[[AnnotationDocument currentDocument] moveCategory:draggedCategory toIndex:[[[AnnotationDocument currentDocument] categories] count]];
			} else {
				[[AnnotationDocument currentDocument] moveCategory:draggedCategory toIndex:childIndex];
			}
		}
		
		[draggedCategory release];
	}
	
    
    [outlineView reloadData];
    // Make sure the target is expanded
	if(targetCategory)
	{
	    [outlineView expandItem:targetCategory];	
	}
    // Reselect old items.
   // [outlineView setSelectedItems:oldSelectedNodes];
    
    // Return YES to indicate we were successful with the drop. Otherwise, it would slide back the drag image.
    return YES;
}


#pragma mark Table View
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
	return [[[AppController currentDoc] categories] count];
}

- (id) tableView: (NSTableView*) aTableView objectValueForTableColumn: 
(NSTableColumn*) tableColumn row: (NSInteger) rowIndex {
	AnnotationCategory *category = [[[AppController currentDoc] categories] objectAtIndex:rowIndex];
	if([[tableColumn identifier] isEqualToString:@"Category"])
	{
		return category.name;
	}
	else
	{
		return category.color;
	}
}

- (void) tableView: (NSTableView*)aTableView setObjectValue:(id)value forTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
	if([[tableColumn identifier] isEqualToString:@"Category"])
	{
		[(AnnotationCategory*)[[[AppController currentDoc] categories] objectAtIndex:row] setName:value];
	}	
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[removeCategoryButton setEnabled:[tableView selectedRow] > -1];
}

- (void) colorClick: (id) sender {    // sender is the table view
	//editingCategory = [[[AppController currentDoc] categories] objectAtIndex:[sender clickedRow]];
	editingCategory = [outlineView itemAtRow:[outlineView selectedRow]];
	NSColor *color = [editingCategory color];
	colorPanel = [NSColorPanel sharedColorPanel];
	[colorPanel setTarget: self];
	[colorPanel setColor: color];
	[colorPanel setContinuous:NO];
	[colorPanel setAction: @selector (colorChanged:)];
	[colorPanel makeKeyAndOrderFront: self];
}

- (void) colorChanged: (id) sender {    // sender is the NSColorPanel
	[editingCategory setColor:[sender color]];
	[tableView reloadData];
}

@end
