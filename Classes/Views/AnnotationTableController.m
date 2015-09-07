//
//  AnnotationTableController.m
//  Annotation
//
//  Created by Adam Fouse on 11/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationTableController.h"
#import "AppController.h"
#import "Annotation.h"
#import "AnnotationCategory.h"
#import "ColorTaggedTextCell.h"
#import "CategoryListCell.h"
#import "AnnotationSearchFilter.h"
#import "DPConstants.h"

NSString * const AnnotationTableColumnStart = @"StartTime";
NSString * const AnnotationTableColumnEnd = @"EndTime";
NSString * const AnnotationTableColumnTitle = @"Title";
NSString * const AnnotationTableColumnAnnotation = @"AnnotationContent";
NSString * const AnnotationTableColumnCategory = @"Category";

int const DPAnnotationTableSpacingTight = 0;
int const DPAnnotationTableSpacingFull = 10;

@implementation AnnotationTableController

- (id)init
{
	if(![super initWithWindowNibName:@"AnnotationTable"])
		return nil;
	
	//annotations = [[[AppController currentDoc] annotations] mutableCopy];
	annotations = [[NSMutableArray alloc] init];
	allAnnotations = [annotations retain];
	
	filter = nil;
	
	NSString* defaultKey = AFTableEditActionKey;
	
	[[AppController currentApp] addObserver:self forKeyPath:@"selectedAnnotation" options:0 context:nil];
	
	NSInteger editOption = [[NSUserDefaults standardUserDefaults] integerForKey:defaultKey];
	
	if(editOption == AFTableEditExternal)
	{
		inlineEdit = NO;
	}
	else
	{
		inlineEdit = YES;
	}
	
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:defaultKey
											   options:0
											   context:NULL];
	
	return self;
}

- (void) dealloc
{
	[tableView setDelegate:nil];
	[tableView setDataSource:nil];
	[annotations release];
	[super dealloc];
}

- (void)windowDidLoad
{
	NSArray* tableColumns = [tableView tableColumns];
	
	NSArray* tableIdentifiers = [NSArray arrayWithObjects:
								 AnnotationTableColumnStart,
								 AnnotationTableColumnEnd,
								 AnnotationTableColumnAnnotation,
								 AnnotationTableColumnTitle,
								 AnnotationTableColumnCategory,
								 nil];
	
	int index = 0;
	for(NSTableColumn *column in tableColumns)
	{
		[column setIdentifier:[tableIdentifiers objectAtIndex:index]];
		 index++;
		
		if([column identifier] == AnnotationTableColumnCategory)
		{
			ColorTaggedTextCell *colorCell = [[[ColorTaggedTextCell alloc] init] autorelease];
			[colorCell setColorTagWidth:16.0];
			[colorCell setColorTagHeight:16.0];
			[column setDataCell: colorCell];
		}
	}
	
	[tableView setUsesAlternatingRowBackgroundColors:YES];
	[tableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask];
	[tableView reloadData];
	
	if(!inlineEdit)
	{
		[tableView setTarget:self];
		[tableView setDoubleAction:@selector(editSelectedAnnotation:)];
	}
    
    NSSortDescriptor *startDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startTimeSeconds" ascending:YES];
    [tableView setSortDescriptors:[NSArray arrayWithObject:startDescriptor]];
    [startDescriptor release];
}

- (void)windowWillClose:(NSNotification *)notification
{
	//[data release];
}


- (IBAction)cancel:(id)sender
{
	[[self window] performClose:self];
}

- (IBAction)updateSearchTerm:(id)sender
{
	NSString *searchString = [searchField stringValue];
	
	AnnotationSearchFilter *theFilter = [[AnnotationSearchFilter alloc] initWithString:searchString];
	[self setAnnotationFilter:theFilter];
	[theFilter release];
}

- (NSArray*)annotationForIndexSet:(NSIndexSet*)theIndices
{
	return [annotations objectsAtIndexes:theIndices];
}

- (IBAction)editSelectedAnnotation:(id)sender
{
	NSLog(@"Table edit action");
	[[AppController currentApp] showAnnotationInspector:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"selectedAnnotation"]) {
		
		NSUInteger index = [annotations indexOfObject:[[AppController currentApp] selectedAnnotation]];
		
		if(index >= [annotations count])
		{
			[tableView deselectAll:self];
		}
		else if([tableView selectedRow] != index)
		{
			[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
				   byExtendingSelection:NO];	
		}
    }
	else if ([keyPath isEqualToString:AFTableEditActionKey]) {
		NSInteger editOption = [[NSUserDefaults standardUserDefaults] integerForKey:AFTableEditActionKey];
		if(editOption == AFTableEditExternal)
		{
			inlineEdit = NO;
			[tableView setTarget:self];
			[tableView setDoubleAction:@selector(editSelectedAnnotation:)];
		}
		else
		{
			inlineEdit = YES;
			[tableView setTarget:nil];
			[tableView setDoubleAction:nil];
		}

    }
	else
	{
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
	}
}

- (IBAction)changeTableSpacing:(id)sender
{
	if([sender isKindOfClass:[NSSegmentedControl class]])
	{
		int clickedSegment = [sender selectedSegment];
		int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
		if(clickedSegmentTag == DPAnnotationTableSpacingTight)
		{
			rowSpacing = DPAnnotationTableSpacingTight;
		}
		else if(clickedSegmentTag == DPAnnotationTableSpacingFull)
		{
			rowSpacing = DPAnnotationTableSpacingFull;
		}
		
		NSTableColumn *categoryColumn = [tableView tableColumnWithIdentifier:AnnotationTableColumnCategory];
		if(rowSpacing == DPAnnotationTableSpacingTight)
		{
			ColorTaggedTextCell *colorCell = [[[ColorTaggedTextCell alloc] init] autorelease];
			[colorCell setColorTagWidth:16.0];
			[colorCell setColorTagHeight:16.0];
			[categoryColumn setDataCell: colorCell];
			[[categoryColumn headerCell] setStringValue:@"Primary Category"];
		}
		else
		{
			CategoryListCell *colorCell = [[[CategoryListCell alloc] init] autorelease];
			[colorCell setColorTagWidth:16.0];
			[colorCell setColorTagHeight:16.0];
			[categoryColumn setDataCell: colorCell];
			[[categoryColumn headerCell] setStringValue:@"Categories"];
		}
		
		NSTableColumn *annotationColumn = [tableView tableColumnWithIdentifier:AnnotationTableColumnAnnotation];
		NSTextFieldCell *cell = [annotationColumn dataCell];
		if(rowSpacing == DPAnnotationTableSpacingTight)
		{
			[cell setLineBreakMode:NSLineBreakByTruncatingTail];
		}
		else
		{
			[cell setLineBreakMode:NSLineBreakByWordWrapping];
		}
		
		[tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [annotations count])]];
	}
}

#pragma mark AnnotationView Methods

-(void)addAnnotation:(Annotation*)annotation
{
	[allAnnotations addObject:annotation];
	if(filter && [[filter predicate] evaluateWithObject:annotation])
	{
		[annotations addObject:annotation];	
        [annotations sortUsingDescriptors:[tableView sortDescriptors]];
	}
	[tableView reloadData];
}

-(void)addAnnotations:(NSArray*)array
{
	[allAnnotations addObjectsFromArray:array];
	if(filter)
	{
		NSArray *filteredAnnotations = [array filteredArrayUsingPredicate:[filter predicate]];
		[annotations addObjectsFromArray:filteredAnnotations];	
        [annotations sortUsingDescriptors:[tableView sortDescriptors]];
	}
	[tableView reloadData];
}

-(void)removeAnnotation:(Annotation*)annotation
{
	[allAnnotations removeObject:annotation];
	if(allAnnotations != annotations)
	{
		[annotations removeObject:annotation];
	}
	[tableView reloadData];
}

-(void)updateAnnotation:(Annotation*)annotation
{
	[tableView reloadData];
}

-(void)setAnnotationFilter:(AnnotationFilter*)theFilter
{
	filter = [theFilter retain];
	[annotations release];
	if(filter)
	{
		annotations = [allAnnotations mutableCopy];
		[annotations filterUsingPredicate:[filter predicate]];
	}
	else
	{
		annotations = [allAnnotations retain];
	}
	[tableView reloadData];
}

-(AnnotationFilter*)annotationFilter
{
	return filter;
}

-(NSArray*)dataSets
{
	return [NSArray array];
}

-(void)update
{
	
}

-(NSData*)currentState:(NSDictionary*)stateFlags
{
	return nil;
}

-(BOOL)setState:(NSData*)stateDict
{
	return YES;
}

#pragma mark Table View Delegate Methods
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
	return [annotations count];
}

//- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
//{
//	Annotation *annotation = [annotations objectAtIndex:row];
//	NSTextFieldCell *cell = [tableColumn dataCellForRow:row];
//	[cell setBackgroundColor:[annotation colorObject]];
//	return cell;
//}

- (NSCell *)tableView:(NSTableView *)theTableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTextFieldCell *cell = [tableColumn dataCell];
	if([tableColumn identifier] == AnnotationTableColumnCategory)
	{
		Annotation *annotation = [annotations objectAtIndex:row];
		//[cell setDrawsBackground:YES];
		[cell setBackgroundColor:[annotation colorObject]];	
	}
	else if([tableColumn identifier] == AnnotationTableColumnAnnotation)
	{
//		CGFloat width = [tableColumn width];
//		NSRect boundsrect = NSMakeRect(0, 0, width, FLT_MAX);
//		[cell cellSizeForBounds:boundsrect];

		[cell setDrawsBackground:NO];
	}
	else
	{
		[cell setDrawsBackground:NO];
	}
	return cell;
}

- (CGFloat)tableView:(NSTableView *)theTableView heightOfRow:(NSInteger)row
{
	if(rowSpacing == DPAnnotationTableSpacingTight)
	{
		return 17;
	}
	else
	{
		NSTableColumn *column = [tableView tableColumnWithIdentifier:AnnotationTableColumnAnnotation];
		CGFloat width = [column width];
		NSRect boundsrect = NSMakeRect(0, 0, width, FLT_MAX);
		Annotation *annotation = [annotations objectAtIndex:row];
		NSTextFieldCell *cell = [column dataCellForRow:row];
		[cell setStringValue:[annotation annotation]];
		return fmax([cell cellSizeForBounds:boundsrect].height,[[annotation categories] count] * 17);
	}
	
}

//- (void)tableView: (NSTableView *)aTableView willDisplayCell:(id)aCell 
//   forTableColumn:(NSTableColumn *)tableColumn row:(int)row
//{
//	if([aCell isMemberOfClass:[NSTextFieldCell class]])
//	{
//		NSTextFieldCell *cell = (NSTextFieldCell*)aCell;
//		if([tableColumn identifier] == AnnotationTableColumnCategory)
//		{
//			Annotation *annotation = [annotations objectAtIndex:row];
//			[cell setDrawsBackground:YES];
//			[cell setBackgroundColor:[annotation colorObject]];	
//		}
//		else {
//			[cell setDrawsBackground:NO];
//		}
//
//
//	}
//}

- (id) tableView:(NSTableView*) aTableView objectValueForTableColumn:(NSTableColumn*) tableColumn row:(NSInteger) rowIndex {
	NSString *identifier = [tableColumn identifier];
	NSParameterAssert(rowIndex >= 0 && rowIndex < [annotations count]);
	Annotation *annotation = [annotations objectAtIndex:rowIndex];
	if(identifier == AnnotationTableColumnStart)
	{
		return [annotation startTimeString];
	}
	else if(identifier == AnnotationTableColumnEnd)
	{
		return [annotation endTimeString];
	}
	else if(identifier == AnnotationTableColumnTitle)
	{
		return [annotation title];
	}
	else if(identifier == AnnotationTableColumnAnnotation)
	{
		return [annotation annotation];
	}
	else if(identifier == AnnotationTableColumnCategory)
	{
		if(rowSpacing == DPAnnotationTableSpacingTight)
		{
			return [[annotation category] name];
		}
		else
		{
			return [annotation categories];
		}
		
		
	}
	else
	{
		return @"";
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	if(!inlineEdit)
	{
		return NO;
	}
	
	NSString *identifier = [tableColumn identifier];
	if((identifier == AnnotationTableColumnStart)
	   ||(identifier == AnnotationTableColumnEnd)
	   ||(identifier == AnnotationTableColumnCategory))
	{
		return NO;
	}
	else
	{
		return YES;
	}
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	NSString *identifier = [tableColumn identifier];
	NSParameterAssert(rowIndex >= 0 && rowIndex < [annotations count]);
	Annotation *annotation = [annotations objectAtIndex:rowIndex];
	if(identifier == AnnotationTableColumnTitle)
	{
		[annotation setTitle:(NSString*)anObject];
	}
	else if(identifier == AnnotationTableColumnAnnotation)
	{
		[annotation setAnnotation:(NSString*)anObject];
	}
}

- (void)tableView:(NSTableView *)theTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    [annotations sortUsingDescriptors:[tableView sortDescriptors]];
    [tableView reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([tableView selectedRow] > -1)
	{
		[[AppController currentApp] moveToTime:[[annotations objectAtIndex:[tableView selectedRow]] startTime] fromSender:self];
		[[AppController currentApp] setSelectedAnnotation:[annotations objectAtIndex:[tableView selectedRow]]];
	}
}

@end
