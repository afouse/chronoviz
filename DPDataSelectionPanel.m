//
//  DPDataSelectionPanel.m
//  ChronoViz
//
//  Created by Adam Fouse on 6/14/12.
//  Copyright (c) 2012 University of California, San Diego. All rights reserved.
//

#import "DPDataSelectionPanel.h"
#import "ColorCell.h"
#import "DataSource.h"
#import "TimeCodedData.h"
#import "AnnotationDocument.h"
#import "AnnotationCategory.h"

@implementation DPDataSelectionPanel

@synthesize allowGroupColorChange, allowItemRename, allowGroupRename, changeCategoryNames;

- (id)initForView:(NSView<AnnotationView>*)view;
{
    self = [super init];
    if (self) {
        dataView = [view retain];
        dataClass = [TimeCodedData class];
        dataSetsPanel = nil;
        self.allowGroupColorChange = YES;
        self.allowItemRename = NO;
        self.allowGroupRename = NO;
        self.changeCategoryNames = NO;
    }
    return self;
}


- (void)setDataClass:(Class)theDataClass;
{
    if([theDataClass isSubclassOfClass:[TimeCodedData class]])
    {
        dataClass = theDataClass;
    }
}

- (void) dealloc
{
    [dataView release];
    [dataSources release];
    [dataSetsPerSource release];
	[super dealloc];
}

- (IBAction)showDataSets:(id)sender
{
    if (!dataSetsPanel)
    {
        [NSBundle loadNibNamed: @"DPDataSelectionPanel" owner:self];
        
        NSTableColumn *column = [[dataSetsOutlineView tableColumns] objectAtIndex:1];
        
        ColorCell* colorCell = [[[ColorCell alloc] init] autorelease];
        [colorCell setEditable: YES];
        [colorCell setTarget: self];
        [colorCell setAction: @selector (colorClick:)];
        [column setDataCell: colorCell];
    }
    
    if(dataSources)
    {
        [dataSources removeAllObjects];
        [dataSetsPerSource removeAllObjects];
    }
    else
    {
        dataSources = [[NSMutableArray alloc] init];
        dataSetsPerSource = [[NSMutableDictionary alloc] init];
    }
    
    NSArray *allData = [[AnnotationDocument currentDocument] dataSets];
    
	for(TimeCodedData *data in allData)
	{
		if([data isKindOfClass:dataClass])
		{
            NSMutableArray *dataSets = nil;
            if([dataSources containsObject:[data source]])
            {
                dataSets = [dataSetsPerSource objectForKey:[[data source] uuid]];
            }
            else
            {
                [dataSources addObject:[data source]];
                dataSets = [[NSMutableArray alloc] init];
                [dataSetsPerSource setObject:dataSets forKey:[[data source] uuid]];
                [dataSets release];
            }
            [dataSets addObject:data];
		}
	}
    
    [dataSetsOutlineView reloadData];
    [dataSetsOutlineView expandItem:nil expandChildren:YES];
	
	[NSApp beginSheet: dataSetsPanel
	   modalForWindow: [dataView window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
}


- (IBAction)closeDataSets:(id)sender
{
	[NSApp endSheet:dataSetsPanel];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

#pragma mark Sources Outline View


- (void) colorClick: (id) sender {    // sender is the table view
	//editingCategory = [[[AppController currentDoc] categories] objectAtIndex:[sender clickedRow]];
    
	colorEditDataSet = [dataSetsOutlineView itemAtRow:[dataSetsOutlineView selectedRow]];
	
    NSColor* color = nil;
    
    if([colorEditDataSet isKindOfClass:[DataSource class]])
    {
        color = [[[dataSetsPerSource objectForKey:[colorEditDataSet uuid]] objectAtIndex:0] color];
    }
    else
    {
        color = [colorEditDataSet color];
    }
    
	NSColorPanel* colorPanel = [NSColorPanel sharedColorPanel];
	[colorPanel setTarget: self];
	[colorPanel setColor: color];
	[colorPanel setContinuous:NO];
	[colorPanel setAction: @selector (colorChanged:)];
	[colorPanel makeKeyAndOrderFront: self];
}

- (void) colorChanged: (id) sender {    // sender is the NSColorPanel
    
    if([colorEditDataSet isKindOfClass:[DataSource class]])
    {
        for(TimeCodedData *data in [dataSetsPerSource objectForKey:[colorEditDataSet uuid]])
        {
            [data setColor:[sender color]];
        }
    }
    else
    {
        [colorEditDataSet setColor:[sender color]];
    }
	[dataSetsOutlineView reloadData];
	[dataView update];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	
    if(item == nil) 
    {
        return [dataSources count];
    }
    else
    {
        NSArray *sets = [dataSetsPerSource objectForKey:[item uuid]];
        if(sets)
        {
            return [sets count];
        }
        else
        {
            return 0;
        }
    }
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [dataSources containsObject:item];
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	
	if(item == nil)
	{
		return [dataSources objectAtIndex:index];
	}
	else if ([item isKindOfClass:[DataSource class]])
    {
        return [[dataSetsPerSource objectForKey:[item uuid]] objectAtIndex:index];
    }
	else
	{
		return nil;
	}
    
}


- (BOOL)outlineView:(NSOutlineView *)sender isGroupItem:(id)item {
	if ([item isKindOfClass:[DataSource class]])
		return YES;
	else
		return NO;
}

//- (void)outlineView:(NSOutlineView *)sender willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
//	if ([((DPTimelineOption*)item).options count] > 0) {
//		NSMutableAttributedString *newTitle = [[cell attributedStringValue] mutableCopy];
//		[newTitle replaceCharactersInRange:NSMakeRange(0,[newTitle length]) withString:[[newTitle string] uppercaseString]];
//		[cell setAttributedStringValue:newTitle];
//		[newTitle release];
//	}
//}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    return YES;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{    
    if([[outlineView tableColumns] indexOfObject:tableColumn] == 0)
    {
        NSArray *sets = [dataSetsPerSource objectForKey:[item uuid]];
        
        if(!sets)
        {
            return [NSNumber numberWithBool:[[dataView dataSets] containsObject:item]];
        }
        else
        {        
            int total = [sets count];
            int active = 0;
            NSArray *current = [dataView dataSets];
            for(TimeCodedData *data in sets)
            {
                if([current containsObject:data])
                {
                    active++;
                }
            }
            if(total == active)
            {
                return [NSNumber numberWithInt:1];
            }
            else if (active == 0)
            {
                return [NSNumber numberWithInt:0];
            }
            else
            {
                return [NSNumber numberWithInt:-1];
            }
        }
    }
    else if([[outlineView tableColumns] indexOfObject:tableColumn] == 1)
    {
        if([item isKindOfClass:[DataSource class]])
        {
            if(self.allowGroupColorChange)
            {
                return [NSColor whiteColor];
            }
            else 
            {
                return [NSColor clearColor];
            }
        }
        else
        {
            return [item color];
        }
    }
    else
    {
        if([item respondsToSelector:@selector(displayName)])
        {
            return [item displayName];  
        }
        else 
        {
            return [item name];
        }
    }
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSUInteger columnIndex = [[outlineView tableColumns] indexOfObject:tableColumn];
	if(columnIndex == 0)
    {
        if([item isKindOfClass:[DataSource class]])
        {
            NSArray *sets = [dataSetsPerSource objectForKey:[item uuid]];
            if([object boolValue])
            {
                for(TimeCodedData *data in sets)
                {
                    [dataView addData:data]; 
                }
                
            }
            else
            {
                for(TimeCodedData *data in sets)
                {
                    [dataView removeData:data]; 
                }
            }
            [outlineView reloadData];
        }
        else if ([item isKindOfClass:dataClass])
        {		
            if([object boolValue])
            {
                [dataView addData:(TimeCodedData*)item];
            }
            else
            {
                [dataView removeData:(TimeCodedData*)item];
            }
        }
    }
    else if(columnIndex == 2)
    {
        BOOL group = [self outlineView:outlineView isGroupItem:item];
        if(self.allowGroupRename && group)
        {
            if(self.changeCategoryNames)
            {
                AnnotationCategory *category = [[AnnotationDocument currentDocument] categoryForName:[item name]];
                if(category)
                {
                    [category setName:object];
                }
            }
            
            [(DataSource*)item setName:object];
        }
        else if (self.allowItemRename && !group)
        {
            if(self.changeCategoryNames)
            {
                AnnotationCategory *category = [[AnnotationDocument currentDocument] categoryForName:[item name]];
                if(category)
                {
                    [category setName:object];
                }
            }
            
            [(TimeCodedData*)item setName:object];
        }
    }
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if([[outlineView tableColumns] indexOfObject:tableColumn] == 1)
    {
        if([self outlineView:outlineView isGroupItem:item] && !self.allowGroupColorChange)
        {
            [(ColorCell*)cell setEnabled:NO];
        }
        else 
        {
            [(ColorCell*)cell setEnabled:YES];
        }
    }
    
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    NSUInteger columnIndex = [[outlineView tableColumns] indexOfObject:tableColumn];
	if(columnIndex == 0)
    {
        return YES;
    }
    else if(columnIndex == 2)
    {
        BOOL group = [self outlineView:outlineView isGroupItem:item];
        if(self.allowGroupRename && group)
        {
            return YES;
        }
        else if (self.allowItemRename && !group)
        {
            return YES;
        } 
        else 
        {
            return NO;
        }
    
    }
    else
    {
        return NO;
    }
}


@end
