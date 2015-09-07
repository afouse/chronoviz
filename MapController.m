//
//  MapController.m
//  Annotation
//
//  Created by Adam Fouse on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MapController.h"
#import "MapView.h"
#import "AnnotationDocument.h"
#import "TimeSeriesData.h"
#import "GeographicTimeSeriesData.h"
#import "ColorTaggedTextCell.h"
#import "SpatialAnnotationOverlay.h"

@implementation MapController

- (id)init
{
	if(![super initWithWindowNibName:@"MapVisualization"])
		return nil;
	
	toolbarZoomInButtonIdentifier = @"DPToolbarZoomInItem";
	toolbarZoomOutButtonIdentifier = @"DPToolbarZoomOutItem";
	toolbarCursorButtonIdentifier = @"DPToolbarCursorItem";
	toolbarPanButtonIdentifier = @"DPToolbarPanItem";
	
	overlay = nil;
	
	[toolbar setDelegate:self];
	
	return self;
}

- (MapView*)mapView
{
	[self window];
	return mapView;
}

- (void) dealloc
{
	[geoDataSets release];
	[super dealloc];
}


- (void)windowDidLoad
{
	NSArray* tableColumns = [dataSetsTable tableColumns];
	
	for(NSTableColumn *column in tableColumns)
	{
		if([[column identifier] isEqualToString:@"DataSet"])
		{
			ColorTaggedTextCell *colorCell = [[[ColorTaggedTextCell alloc] init] autorelease];
			[column setDataCell: colorCell];
		}
	}
}

- (IBAction)showDataSets:(id)sender
{
	if(geoDataSets)
	{
		[geoDataSets removeAllObjects];
	}
	else
	{
		geoDataSets = [[NSMutableArray alloc] init];
	}
	
	NSArray *allData = [[AnnotationDocument currentDocument] timeSeriesData];
	for(TimeSeriesData *data in allData)
	{
		if([data isKindOfClass:[GeographicTimeSeriesData class]])
		{
			[geoDataSets addObject:data];
		}
	}
	
	[dataSetsTable reloadData];
	
	[NSApp beginSheet: dataSetsPanel
	   modalForWindow: [self window]
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

- (IBAction)toggleShowPaths:(id)sender
{
	[mapView togglePathVisiblity:self];
}

- (IBAction)mapTypeButtonPress:(id)sender;
{
	if([sender isKindOfClass:[NSSegmentedControl class]])
	{
		int clickedSegment = [sender selectedSegment];
		int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
		if(clickedSegmentTag == 0)
		{
			[mapView setMapType:AFMapTypeNormal];
		}
		else if(clickedSegmentTag == 1)
		{
			[mapView setMapType:AFMapTypeSatellite];
		}
		else
		{
			[mapView setMapType:AFMapTypeTerrain];
		}
	}
}


- (IBAction)zoomButtonPress:(id)sender
{
	if([sender isKindOfClass:[NSSegmentedControl class]])
	{
		int clickedSegment = [sender selectedSegment];
		int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
		if(clickedSegmentTag)
		{
			[mapView zoomIn:nil];
		}
		else
		{
			[mapView zoomOut:nil];
		}
	}
}

- (IBAction)cursorButtonPress:(id)sender
{
	if([sender isKindOfClass:[NSSegmentedControl class]])
	{
		int clickedSegment = [sender selectedSegment];
		int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
		if(clickedSegmentTag)
		{
			[mapView setDragTool:YES];
		}
		else
		{
			[mapView setDragTool:NO];
		}
	}
}

- (IBAction)showOverlay:(id)sender
{
	if(!overlay)
	{
		overlay = [[SpatialAnnotationOverlay alloc] initForView:mapView];
	}
	[overlay showOverlay];
}

#pragma mark Toolbar Delegate

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects: 
			@"CursorGroupItem",
			@"MapTypeItem",
			@"MapDataItem",
			NSToolbarFlexibleSpaceItemIdentifier,
			@"ZoomGroupItem",
			nil];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects: 
			@"CursorGroupItem",
			@"MapTypeItem",
			@"MapDataItem",
			NSToolbarFlexibleSpaceItemIdentifier,
			@"ZoomGroupItem",
			nil];
}

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar
      itemForItemIdentifier:(NSString *)itemIdentifier
  willBeInsertedIntoToolbar:(BOOL)flag
{
    if ([itemIdentifier isEqual: @"CursorGroupItem"]) {
		
		NSToolbarItem *cursorItem = [[[NSToolbarItem alloc] initWithItemIdentifier:toolbarCursorButtonIdentifier] autorelease];
		NSToolbarItem *panItem = [[[NSToolbarItem alloc] initWithItemIdentifier:toolbarPanButtonIdentifier] autorelease];
		[[NSCursor arrowCursor] image];
		[cursorItem setImage:[NSImage imageNamed:@"DPArrowCursor"]];
		[panItem setImage:[[NSCursor openHandCursor] image]];
		[cursorItem setLabel:@"Select"];
		[panItem setLabel:@"Pan"];
		
		NSSegmentedControl *cursorControl = [[NSSegmentedControl alloc] initWithFrame:NSMakeRect(0, 0, 77, 23)];
		[cursorControl setSegmentCount:2];
		[cursorControl setSegmentStyle:NSSegmentStyleCapsule];
		[cursorControl setLabel:nil forSegment:0];
		[cursorControl setWidth:35 forSegment:0];
		[cursorControl setImage:[NSImage imageNamed:@"DPArrowCursor"] forSegment:0];
		[cursorControl setLabel:nil forSegment:1];
		[cursorControl setWidth:35 forSegment:1];
		[cursorControl setImage:[[NSCursor openHandCursor] image] forSegment:1];
		
		[[cursorControl cell] setTag:0 forSegment:0];
		[[cursorControl cell] setTag:1 forSegment:1];
		
		[cursorControl setSelectedSegment:0];
		
		[cursorControl setTarget:self];
		[cursorControl setAction:@selector(cursorButtonPress:)];
		
		NSToolbarItemGroup *group = [[[NSToolbarItemGroup alloc] initWithItemIdentifier:@"CursorGroupItem"] autorelease];
		[group setSubitems:[NSArray arrayWithObjects:cursorItem, panItem, nil]];
		[group setView:cursorControl];
		
		return group;
    } else  {
		// itemIdentifier referred to a toolbar item that is not
		// provided or supported by us or Cocoa
		// Returning nil will inform the toolbar
		// that this kind of item is not supported
		return nil;
    }
}

#pragma mark Table View Delegate Methods
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
	
	return [geoDataSets count];
}


- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTextFieldCell *cell = [tableColumn dataCell];
	if([[tableColumn identifier] isEqualToString: @"DataSet"])
	{
		GeographicTimeSeriesData *dataSet = [geoDataSets objectAtIndex:row];
		[cell setBackgroundColor:[dataSet color]];	
	}
	else {
		[cell setDrawsBackground:NO];
	}
	return cell;
}


- (id) tableView:(NSTableView*) aTableView objectValueForTableColumn:(NSTableColumn*) tableColumn row:(NSInteger) rowIndex {
	NSString *identifier = [tableColumn identifier];
	NSParameterAssert(rowIndex >= 0 && rowIndex < [geoDataSets count]);
	GeographicTimeSeriesData *dataSet = [geoDataSets objectAtIndex:rowIndex];
	if([identifier isEqualToString:@"DataSet"])
	{
		return [[[dataSet source] name] stringByAppendingFormat:@" - %@",[dataSet name]];
	}
	else if([identifier isEqualToString:@"Visible"])
	{
		return [NSNumber numberWithBool:[[mapView dataSets] containsObject:dataSet]];
	}
	else
	{
		return @"";
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	NSString *identifier = [tableColumn identifier];
	if([identifier isEqualToString:@"Visible"])
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	NSString *identifier = [tableColumn identifier];
	NSParameterAssert(rowIndex >= 0 && rowIndex < [geoDataSets count]);
	GeographicTimeSeriesData *dataSet = [geoDataSets objectAtIndex:rowIndex];
	if([identifier isEqualToString:@"Visible"])
	{
		if([anObject boolValue])
		{
			[mapView addData:dataSet];
		}
		else
		{
			[mapView removeData:dataSet];
		}
	}

}


@end
