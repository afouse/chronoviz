//
//  DPExportAnnotationsTimeSeries.m
//  ChronoViz
//
//  Created by Adam Fouse on 4/19/12.
//  Copyright (c) 2012 University of California, San Diego. All rights reserved.
//

#import "DPExportAnnotationsTimeSeries.h"
#import "AnnotationCategory.h"
#import "AnnotationCategoryFilter.h"
#import "AnnotationDocument.h"
#import "ColorTaggedTextCell.h"
#import "Annotation.h"


@interface DPExportAnnotationsTimeSeries (Internal)

- (NSArray*)createTimeSeriesForCategory:(AnnotationCategory*)category withRate:(CGFloat)entriesPerSecond;

@end


@implementation DPExportAnnotationsTimeSeries

-(NSString*)name
{
	return @"Export Annotations Time Series";
}


-(BOOL)export:(AnnotationDocument*)doc
{
    theDoc = [doc retain];
    
    [doc release];
    
    categories = [[AnnotationCategoryFilter alloc] initForNone];
    
    if(!exportWindow) {
        [NSBundle loadNibNamed: @"DPExportAnnotationsTimeSeriesWindow" owner:self];
        
        NSArray* tableColumns = [categoriesOutlineView tableColumns];
        
        for(NSTableColumn *column in tableColumns)
        {
            if([[column identifier] isEqualToString:@"Category"])
            {
                ColorTaggedTextCell *colorCell = [[[ColorTaggedTextCell alloc] init] autorelease];
                [column setDataCell: colorCell];
            }
        }
        
        [rateButton removeAllItems];
        [rateButton addItemWithTitle:@"1 per second"];
        [[rateButton lastItem] setRepresentedObject:[NSNumber numberWithFloat:1.0]];
        [rateButton addItemWithTitle:@"10 per second"];
        [[rateButton lastItem] setRepresentedObject:[NSNumber numberWithFloat:10.0]];
    }
    
    [exportWindow makeKeyAndOrderFront:nil];
    return YES;
}

- (void)dealloc
{
    [categories release];
    [super dealloc];
}



- (NSArray*)createTimeSeriesForCategory:(AnnotationCategory*)category withRate:(CGFloat)entriesPerSecond
{
    NSTimeInterval docDuration;
    docDuration = CMTimeGetSeconds([theDoc duration]);
    
    NSUInteger entries = docDuration * entriesPerSecond;
    
    NSMutableArray *timeSeries = [NSMutableArray arrayWithCapacity:entries];

    
    NSMutableArray *annotations = [NSMutableArray arrayWithArray:[[[theDoc annotationsForCategory:category] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isDuration==1"]] sortedArrayUsingComparator:^(id obj1, id obj2) {
        Annotation *point1 = (Annotation*)obj1;
        Annotation *point2 = (Annotation*)obj2;
        return CMTimeCompare([point1 time], [point2 time]);
    }]];
    
    NSMutableArray *activeAnnotations = [[NSMutableArray alloc] init];
    NSTimeInterval currentTime;
    for(currentTime = 0; currentTime <= docDuration; currentTime += 1.0/entriesPerSecond)
    {
        if([annotations count]) {
            NSTimeInterval annStartTime = [[annotations objectAtIndex:0] startTimeSeconds];
            while((annStartTime < currentTime) && [annotations count]) {
                if([[annotations objectAtIndex:0] endTimeSeconds] > currentTime)
                {
                    [activeAnnotations addObject:[annotations objectAtIndex:0]];
                    [annotations removeObjectAtIndex:0];
                    if([annotations count] > 0)
                        annStartTime = [[annotations objectAtIndex:0] startTimeSeconds];
                }
            }
        }
        

        NSMutableArray *done = [NSMutableArray array];
        for(Annotation* annotation in activeAnnotations)
        {
            if([annotation endTimeSeconds] < currentTime) {
                [done addObject:annotation];
            }
        }
        [activeAnnotations removeObjectsInArray:done];
        
        [timeSeries addObject:[self outputForArray:activeAnnotations]];
        
    }
    
    

    return timeSeries;
}

- (NSString*)outputForArray:(NSArray*)array
{
    if([array count]) {
        return @"1";
    } else {
        return @"0";
    }
}

- (IBAction)saveOutput:(id)sender {
    
    NSMutableArray *header = [[NSMutableArray alloc] init];
    NSMutableArray *timeSeries = [[NSMutableArray alloc] init];
    CGFloat entriesPerSecond = [[[rateButton selectedItem] representedObject] floatValue];
    
    [header addObject:@"Time"];
    for(AnnotationCategory* category in [categories visibleCategories])
    {
        NSArray *cattimeseries = [self createTimeSeriesForCategory:category withRate:entriesPerSecond];
        [header addObject:[category name]];
        [timeSeries addObject:cattimeseries];
    }

    NSMutableString *output = [[NSMutableString alloc] initWithCapacity:([[timeSeries objectAtIndex:0] count] * [timeSeries count])];
    
    [output appendString:[header componentsJoinedByString:@","]];
    [output appendString:@"\n"];
    
    NSTimeInterval docDuration;
    docDuration = CMTimeGetSeconds([theDoc duration]);
    
    int i,j;
    NSTimeInterval currentTime = 0;
    for(i = 0; i < [[timeSeries objectAtIndex:0] count]; i++)
    {
        [output appendFormat:@"%f,",currentTime];
        currentTime+=1.0/entriesPerSecond;
        for(j = 0; j < [timeSeries count]; j++)
        {
            [output appendString:[[timeSeries objectAtIndex:j] objectAtIndex:i]];
            if(j < [timeSeries count] - 1)
                [output appendString:@","];
            
        }
        [output appendString:@"\n"];
    }
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	[savePanel setCanCreateDirectories:YES];
	[savePanel setTitle:@"Time Series Export"];
	[savePanel setPrompt:@"Export"];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"csv"]];
	[savePanel setExtensionHidden:NO];
	[savePanel setCanSelectHiddenExtension:YES];

    [savePanel beginSheetModalForWindow:exportWindow completionHandler:^(NSInteger result){
        NSError *err = nil;
        if(result == NSFileHandlingPanelOKButton) {
            [output writeToURL:[savePanel URL]
                    atomically:YES
                      encoding:NSUTF8StringEncoding
                         error:&err];
            [exportWindow close];
        } else {
        }
    
    }];
    
    
}


#pragma mark Outline View

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	
    return (item == nil) ? [[theDoc categories] count] : [[item values] count];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return ([[item values] count] > 0) ? YES : NO;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	
    if(item == nil)
	{
		return [[theDoc categories] objectAtIndex:index];
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
	else if([[tableColumn identifier] isEqualToString:@"Buttons"])
	{
        if([categories includesCategory:category])
        {
            return [NSNumber numberWithBool:YES];
        }
        else
        {
            for(AnnotationCategory *value in [category values])
            {
                if([categories includesCategory:value])
                {
                    return [NSNumber numberWithInt:-1];
                }
            }
            return [NSNumber numberWithBool:NO];
        }
	}
	else
	{
		return @"";
	}
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if([[tableColumn identifier] isEqualToString:@"Category"])
	{
		[(AnnotationCategory*)item setName:object];
	}
    else if([[tableColumn identifier] isEqualToString:@"Buttons"])
    {
        BOOL selected = [object boolValue];
        AnnotationCategory *category = (AnnotationCategory*)item;

		if( selected )
			[categories showCategory:category];
		else
			[categories hideCategory:category];
				
		[categoriesOutlineView deselectAll:self];
		
		if([category category])
            [categoriesOutlineView reloadItem:[category category]];
		
		for(id value in [category values])
		{
			[categoriesOutlineView reloadItem:value];
		}
        
    }
}


- (NSCell *) outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSTextFieldCell *cell = [tableColumn dataCell];
	if([[tableColumn identifier] isEqualToString:@"Category"])
	{
		[cell setBackgroundColor:[(AnnotationCategory*)item color]];
	}
	return cell;
}

//- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
//{
//    return;
//
//	if([filtersView selectedRow] > -1)
//	{
//		int index = [filtersView selectedRow];
//
//		AnnotationCategory *category = [filtersView itemAtRow:index];
//
//		AnnotationCategoryFilter* filter = (AnnotationCategoryFilter*)[annotationView annotationFilter];
//
//		BOOL selected;
//		if(!filter)
//		{
//			selected = YES;
//			filter = [[[AnnotationCategoryFilter alloc] init] autorelease];
//		}
//		else
//		{
//			selected = [filter includesCategory:category];
//		}
//
//		if( !selected )
//			[filter showCategory:category];
//		else
//			[filter hideCategory:category];
//
//		[annotationView setAnnotationFilter:filter];
//
//		[filtersView deselectAll:self];
//
//		if([category category])
//		   [filtersView reloadItem:[category category]];
//
//		for(id value in [category values])
//		{
//			[filtersView reloadItem:value];
//		}
//	}
//}



@end
