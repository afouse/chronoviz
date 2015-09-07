//
//  LinkedFilesController.m
//  ChronoViz
//
//  Created by Adam Fouse on 7/11/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "LinkedFilesController.h"
#import "AnnotationDocument.h"
#import "AppController.h"
#import "VideoProperties.h"
#import "VideoPropertiesController.h"
#import "DataImportController.h"
#import "NSString+NDCarbonUtilities.h"

#import "DataSource.h"
#import "VideoDataSource.h"
#import "CompoundDataSource.h"
#import "XPlaneDataSource.h"
#import "SenseCamDataSource.h"
#import "ActivityTrailsDataSource.h"
#import "InqScribeDataSource.h"
#import "ElanDataSource.h"
#import "DPImageSequenceDataSource.h"

@interface LinkedFilesController(SourceManagement)

- (void)editSources:(NSArray*)sources;
- (BOOL)sourceArray:(NSArray*)sources containsVideo:(VideoProperties*)video;
- (void)addVideo:(VideoProperties*)video;
- (void)addDataSource:(DataSource*)data;
- (void)propertiesWindowClosed:(NSNotification*)notification;
- (NSArray*)selectedDataSources;

@end

@implementation LinkedFilesController

static NSMutableArray *possibleDataSources = nil;

@synthesize annotationDocument;

+ (void)initialize
{
    if(!possibleDataSources)
    {
        possibleDataSources = [[NSMutableArray alloc] initWithObjects:
                               [XPlaneDataSource class],
                               [SenseCamDataSource class],
                               [DataSource class],
                               [ActivityTrailsDataSource class],
                               [InqScribeDataSource class],
                               [ElanDataSource class],
                               [DPImageSequenceDataSource class],
                               [VideoDataSource class],
                               nil]; 
    }
}

- (id)init
{
	if(![super initWithWindowNibName:@"LinkedFiles"])
		return nil;
	
	filesArray = [[NSMutableArray alloc] init];
	propertiesControllers = [[NSMutableArray alloc] init];
	mainVideoSource = nil;
	openDataTypeButton = nil;
    openDataTypeLabel = nil;
	
	return self;
}
+(void)registerDataSourceClass:(Class)dataSourceClass
{
    if([dataSourceClass isSubclassOfClass:[DataSource class]])
    {
        [possibleDataSources insertObject:dataSourceClass atIndex:0];
    }
}

- (void)panelSelectionDidChange:(id)sender
{   
    [openDataTypeButton removeAllItems];
    
    NSOpenPanel *panel = (NSOpenPanel*)sender;
    
    NSArray *selection = [panel URLs];
    
    if([selection count] == 1)
    {
        NSString *file = [[selection lastObject] path];
        for(Class sourceClass in possibleDataSources)
        {
            if([sourceClass validateFileName:file])
            {
                [openDataTypeButton addItemWithTitle:[sourceClass dataTypeName]];
                [[openDataTypeButton lastItem] setRepresentedObject:sourceClass];
            }
        }
        
        NSUInteger count = [[openDataTypeButton itemArray] count];
        if(count == 1)
        {
            [openDataTypeButton setHidden:YES];
            [openDataTypeLabel setAlignment:NSCenterTextAlignment];
            [openDataTypeLabel setStringValue:[NSString stringWithFormat:@"Data Type: %@",[[openDataTypeButton itemAtIndex:0] title]]];
        }
        else if (count > 1)
        {
            [openDataTypeButton setHidden:NO];
            [openDataTypeLabel setAlignment:NSLeftTextAlignment];
            [openDataTypeLabel setStringValue:@"Data Type:"];
        }
        else
        {
            [openDataTypeButton setHidden:YES];
            [openDataTypeLabel setAlignment:NSCenterTextAlignment];
            [openDataTypeLabel setStringValue:@"Data Type: (unsupported)"];
        }
        
        //[openDataTypeButton setEnabled:([[openDataTypeButton itemArray] count] > 0)];
        
    }
    else 
    {
        [openDataTypeButton setHidden:YES];
        [openDataTypeLabel setAlignment:NSCenterTextAlignment];
        [openDataTypeLabel setStringValue:@"Data Type: (no file selected)"];
    }
    
}

- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename
{
	BOOL isDir = NO;
	
	[[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDir];
	
	if(isDir && ![[filename pathExtension] isEqualToString:@"annotation"])
	{
		return YES;
	}
	else if ([filename isAliasFinderInfoFlag])
	{
		return YES;
	}
	else
	{
		for(Class sourceClass in possibleDataSources)
		{
			if([sourceClass validateFileName:filename])
				return YES;
		}
		return NO;
	}
	
}

- (void) dealloc
{
    [openDataTypeLabel release];
    [openDataTypeButton release];
	[filesArray release];
	[super dealloc];
}


-(IBAction)showWindow:(id)sender
{
	if([sender respondsToSelector:@selector(tag)] && ([sender tag] > 1))
	{
		[[sender window] close];
		[NSApp stopModal];
	}
	[linkDataButton setEnabled:NO];
	[self reloadData];
	[super showWindow:sender];
	[[self window] makeKeyAndOrderFront:self];
}

-(IBAction)addData:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:@"Select Data File"];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setDelegate:self];
	
    NSRect viewFrame = NSMakeRect(0, 0, 350, 50);
    
    CGFloat offset = 0;
    if([filesArray count] > 0)
	{
        viewFrame.size.height = 100;
        offset = 50;
    }
    
	NSRect buttonFrame = NSMakeRect(120, 16 + offset, 170, 26);
	NSRect labelFrame = NSMakeRect(50, 22 + offset, 250, 17);
    
    NSView *view = [[NSView alloc] initWithFrame:viewFrame];
	
    [openDataTypeButton release];
	openDataTypeButton = [[NSPopUpButton alloc] initWithFrame:buttonFrame pullsDown:NO];
	[openDataTypeButton setHidden:YES];
    
    [openDataTypeLabel release];
	openDataTypeLabel = [[NSTextField alloc] initWithFrame:labelFrame];
	[openDataTypeLabel setStringValue:@"Data Type:"];
	[openDataTypeLabel setEditable:NO];
	[openDataTypeLabel setDrawsBackground:NO];
	[openDataTypeLabel setBordered:NO];
	[openDataTypeLabel setAlignment:NSLeftTextAlignment];
	
	[view addSubview:openDataTypeLabel];
    [view addSubview:openDataTypeButton];
    
	if([filesArray count] > 0)
	{
		NSButton *showFilesButton = [[NSButton alloc] initWithFrame:NSMakeRect(25,16,300,32)];
		[showFilesButton setBezelStyle:NSRoundedBezelStyle];
		[showFilesButton setTitle:@"Edit Existing Data Sources…"];
		[showFilesButton setAction:@selector(showWindow:)];
		[showFilesButton setTarget:self];
		[showFilesButton setTag:2];
		
        [view addSubview:showFilesButton];
        
		//[openPanel setAccessoryView:showFilesButton];
		
		[showFilesButton release];		
	}

    
    [openPanel setAccessoryView:view];
	
	if([openPanel runModal] == NSOKButton)
	{
		[self openDataFile:[openPanel filename]];
		[self reloadData];
	}

	//[[AppController currentApp] importMedia:self];
}


- (BOOL)openDataFile:(NSString*)file asType:(Class)dataSourceClass
{
    [self window];
	
	if([annotationDocument hasDataFile:file])
	{
		return NO;
	}
	
	if(dataSourceClass == nil)
    {
        NSMutableArray *possibleDataTypes = [NSMutableArray array];
        for(Class sourceClass in possibleDataSources)
        {
            if([sourceClass validateFileName:file])
            {
                [possibleDataTypes addObject:sourceClass];
                //			dataSourceClass = sourceClass;
                //			break;
            }
        }
        
        if([possibleDataTypes count] == 1)
        {
            dataSourceClass = [possibleDataTypes lastObject];
        }
        else if([possibleDataTypes count] > 1)
        {
            dataSourceClass = [[openDataTypeButton selectedItem] representedObject];
        }
        else
        {
            return NO;
        }
    }
    
	DataSource *dataSource = [[dataSourceClass alloc] initWithPath:file];
	[[AppController currentDoc] addDataSource:dataSource];
	
	[self editSources:[NSArray arrayWithObject:dataSource]];
	
    [dataSource release];
    
	return YES;
}

- (BOOL)openDataFile:(NSString*)file
{
	return [self openDataFile:file asType:nil];
}

-(IBAction)removeData:(id)sender
{
	NSIndexSet *dataSources = [linkedFilesView selectedRowIndexes];
	
	NSAlert *removeAlert = [[NSAlert alloc] init];
	if([dataSources count] > 1)
	{
		[removeAlert setMessageText:@"Are you sure you want to remove the selected data sources?"];
	}
	else
	{
		[removeAlert setMessageText:@"Are you sure you want to remove the selected data source?"];
	}
	[removeAlert setInformativeText:@"This action cannot be undone"];
	[removeAlert addButtonWithTitle:@"Remove Data Sources"];
	[removeAlert addButtonWithTitle:@"Cancel"];
	[removeAlert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	
}


- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertFirstButtonReturn) {
		NSArray *dataSources = [self selectedDataSources];
		for(DataSource *source in dataSources)
		{
			[annotationDocument removeDataSource:source];
			//[[AppController currentApp] updateViewMenu];
		}
		[self reloadData];
    }
}

-(IBAction)editProperties:(id)sender
{
	NSArray *selectedSources = [self selectedDataSources];
	[self editSources:selectedSources];
}

- (void)editSources:(NSArray*)sources
{
	for(DataSource *source in sources)
	{
		NSWindowController *controller = nil;
		if([source isKindOfClass:[VideoDataSource class]])
		{
			VideoPropertiesController *videoController = [[VideoPropertiesController alloc] init];
			[videoController setVideoProperties:[(VideoDataSource*)source videoProperties]];
			[videoController setAnnotationDoc:annotationDocument];
			controller = videoController;
			
		}
		else if ([source isKindOfClass:[CompoundDataSource class]])
		{
			
		}
		else
		{
			DataImportController *dataController = [[DataImportController alloc] init];
			[dataController setDataSource:source];
			controller = dataController;
		}
		
		[controller showWindow:self];
		[[controller window] makeKeyAndOrderFront:self];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(propertiesWindowClosed:)
													 name:NSWindowWillCloseNotification
												   object:[controller window]];
		[propertiesControllers addObject:controller];
		[controller release];
		
	}
}

- (void)propertiesWindowClosed:(NSNotification*)notification
{
	NSWindowController *controller = [(NSWindow*)[notification object] windowController];
	if([propertiesControllers containsObject:controller])
	{
		[controller retain];
		[propertiesControllers removeObject:controller];
		[controller autorelease];
	}
}

-(IBAction)linkDataFiles:(id)sender
{
	NSArray *selectedSources = [self selectedDataSources];
	if(mainVideoSource && [selectedSources containsObject:mainVideoSource])
	{
		return;
	}
	CompoundDataSource *newSource = [annotationDocument createCompoundDataSource:selectedSources];
	[self reloadData];
	if(newSource)
	{
		[linkedFilesView expandItem:newSource];
		
		[linkedFilesView selectRowIndexes:[NSIndexSet indexSetWithIndex:[linkedFilesView rowForItem:newSource]]
					 byExtendingSelection:NO];
	}
}

-(IBAction)showFileInFinder:(id)sender
{
    NSInteger selected = [linkedFilesView selectedRow];
    if((selected >= 0) && (selected < [filesArray count]))
    {
        DataSource *source = [filesArray objectAtIndex:selected];
        [[NSWorkspace sharedWorkspace] selectFile:[source dataFile] inFileViewerRootedAtPath:@""];
    }
}

-(void)reloadData
{
	[filesArray removeAllObjects];
	
	if(![[annotationDocument videoProperties] localVideo])
	{
		[self addVideo:[annotationDocument videoProperties]];
		mainVideoSource = [filesArray lastObject];
	}
	for(DataSource *source in [annotationDocument dataSources])
	{
		[self addDataSource:source];
	}
	
	[linkedFilesView reloadData];
}

- (BOOL)sourceArray:(NSArray*)sources containsVideo:(VideoProperties*)video;
{
	for(DataSource* source in sources)
	{
		if([source isKindOfClass:[VideoDataSource class]])
		{
			if(((VideoDataSource*)source).videoProperties == video)
			{
				return YES;
			}
		}
		else if ([source isKindOfClass:[CompoundDataSource class]])
		{
			if([self sourceArray:[(CompoundDataSource*)source dataSources] containsVideo:video])
			{
				return YES;
			}
		}
	}
	return NO;
}

- (void)addVideo:(VideoProperties*)video
{	
	if(![self sourceArray:filesArray containsVideo:video])
	{
		VideoDataSource *videoSource = [[VideoDataSource alloc] initWithVideoProperties:video];
		[filesArray addObject:videoSource];
		[videoSource release];	
	}
}

- (void)addDataSource:(DataSource*)data
{
	if([data isKindOfClass:[VideoDataSource class]]
	   && [self sourceArray:filesArray containsVideo:((VideoDataSource*)data).videoProperties])
	{
		return;
	}
	
	[filesArray addObject:data];
}

#pragma mark OutlineView

- (NSArray*)selectedDataSources
{
	NSMutableArray *array = [NSMutableArray array];
	
	NSIndexSet *selectedRows = [linkedFilesView selectedRowIndexes];
	NSUInteger index = [selectedRows firstIndex];
	while(index != NSNotFound)
	{
		[array addObject:[linkedFilesView itemAtRow:index]];
		index = [selectedRows indexGreaterThanIndex: index];
	}
	
	return array;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	
    if(item == nil)
	{
		return [filesArray count];
	}
	else if([item isKindOfClass:[CompoundDataSource class]])
	{
		return [[(CompoundDataSource*)item dataSources] count];
	}
	else
	{
		return 0;
	}
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [item isKindOfClass:[CompoundDataSource class]] ;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	
    if(item == nil)
	{
		return [filesArray objectAtIndex:index];
	} 
	else if([item isKindOfClass:[CompoundDataSource class]])
	{
		return [[(CompoundDataSource*)item dataSources] objectAtIndex:index];
	}
	else 
	{
		return nil;
		//return [[(AnnotationCategory *)item values] objectAtIndex:index];
	}
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {

	if([item isKindOfClass:[CompoundDataSource class]])
	{
		CompoundDataSource *data = (CompoundDataSource*)item;
		if([[tableColumn identifier] isEqualToString:@"File"])
		{
			return @"Multiple Files";
		}
		else if([[tableColumn identifier] isEqualToString:@"Title"])
		{
			return [data name];
		}
		else if([[tableColumn identifier] isEqualToString:@"Type"])
		{
			return @"Linked Data Sources";
		}
		else if([[tableColumn identifier] isEqualToString:@"StartTime"])
		{
			NSTimeInterval startTime;
			QTGetTimeInterval([data range].time, &startTime);
			return [NSString stringWithFormat:@"%.2f",startTime];
		}
	}
	else if([item isKindOfClass:[DataSource class]])
	{
		DataSource *data = (DataSource*)item;
		if([[tableColumn identifier] isEqualToString:@"File"])
		{
			return [[data dataFile] lastPathComponent];
		}
		else if([[tableColumn identifier] isEqualToString:@"Title"])
		{
			return [data name];
		}
		else if([[tableColumn identifier] isEqualToString:@"Type"])
		{
			if(item == mainVideoSource)
			{
				return @"Primary Video";
			}
			{
				return [[data class] dataTypeName];
			}
			
		}
		else if([[tableColumn identifier] isEqualToString:@"StartTime"])
		{
			if(item == mainVideoSource)
			{
				return @"0";
			}
			else
			{
				NSTimeInterval startTime;
				QTGetTimeInterval([data range].time, &startTime);
				return [NSString stringWithFormat:@"%.2f",startTime];	
			}
		}
	}
	return @"";
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if([[tableColumn identifier] isEqualToString:@"StartTime"])
	{
		if(item != mainVideoSource)
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
        if([item isKindOfClass:[DataSource class]])
        {
            [self editSources:[NSArray arrayWithObject:item]];
        }
		return NO;
	}
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if([[tableColumn identifier] isEqualToString:@"StartTime"])
	{
		if([item isKindOfClass:[VideoProperties class]])
		{
			VideoProperties *video = (VideoProperties*)item;
			[video setOffset:QTMakeTimeWithTimeInterval(-[object floatValue])];
		}
		else if([item isKindOfClass:[DataSource class]])
		{
			DataSource *data = (DataSource*)item;
			QTTimeRange range = [data range];
			range.time = QTMakeTimeWithTimeInterval([object floatValue]);
			[data setRange:range];
		}
	}

}

- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	NSArray *selection = [self selectedDataSources];
	if(mainVideoSource && [selection containsObject:mainVideoSource])
	{
		[linkDataButton setEnabled:NO];
		[removeDataButton setEnabled:NO];
	}
	else
	{
		[linkDataButton setEnabled:NO]; //([selection count] > 1)];
		[removeDataButton setEnabled:([selection count] > 0)];	
	}
	
	[editPropertiesButton setEnabled:([selection count] > 0)];
}


@end
