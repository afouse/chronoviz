//
//  AnotoViewController.m
//  DataPrism
//
//  Created by Adam Fouse on 2/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AnotoViewController.h"
#import "AnotoView.h"
#import "Annotation.h"
#import "AnnotationCategory.h"
#import "AnnotationCategoryFilter.h"
#import "AnnotationVisualizer.h"
#import "EthnographerNotesView.h"
#import "AnotoNotesData.h"
#import "AnotoDataSource.h"
#import "AnotoTrace.h"
#import "AnnotationDocument.h"
#import "AppController.h"
#import "TimelineView.h"
#import "DPMaskedSelectionView.h"
#import "ColorTaggedTextCell.h"
#import "ColorCell.h"

@interface AnotoViewController (Printing)

- (void)checkPrintStatus:(id)sender;

@end

@implementation AnotoViewController

- (id)init
{
	if(![super initWithWindowNibName:@"AnotoWindow"])
		return nil;
	
	printQueue = nil;
	selectionTimeline = nil;
	selectionCategory = nil;
	
	return self;
}

- (void) dealloc
{
	[selectionCategory release];
	[notesDataSets release];
	[printQueue release];
	[super dealloc];
}

- (void)windowDidLoad
{
	NSArray* tableColumns = [dataSetsTable tableColumns];
	
	for(NSTableColumn *column in tableColumns)
	{
		if([[column identifier] isEqualToString:@"Color"])
		{
			ColorCell* colorCell = [[[ColorCell alloc] init] autorelease];
			[colorCell setEditable: YES];
			[colorCell setTarget: self];
			[colorCell setAction: @selector (colorClick:)];
			[column setDataCell: colorCell];
		}
//		if([[column identifier] isEqualToString:@"DataSet"])
//		{
//			ColorTaggedTextCell *colorCell = [[[ColorTaggedTextCell alloc] init] autorelease];
//			[column setDataCell: colorCell];
//		}
	}
}

- (EthnographerNotesView*)anotoView
{
	[self window];
	return anotoView;
}

- (IBAction)changePageButtonClick:(id)sender
{
	if([sender isKindOfClass:[NSSegmentedControl class]])
	{
		int clickedSegment = [sender selectedSegment];
		int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
		if(clickedSegmentTag)
		{
			[anotoView nextPage:self];
		}
		else
		{
			[anotoView previousPage:self];
		}
	}
}

- (IBAction)rotatePageButtonClick:(id)sender
{
	if([sender isKindOfClass:[NSSegmentedControl class]])
	{
		int clickedSegment = [sender selectedSegment];
		int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
		if(clickedSegmentTag)
		{
			[anotoView rotateCW:self];
		}
		else
		{
			[anotoView rotateCCW:self];
		}
	}
}

- (IBAction)zoomButtonClick:(id)sender
{
	if([sender isKindOfClass:[NSSegmentedControl class]])
	{
		int clickedSegment = [sender selectedSegment];
		int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
		if(clickedSegmentTag)
		{
			[anotoView zoomIn:self];
		}
		else
		{
			[anotoView zoomOut:self];
		}
	}
}

- (void)updateSelection:(id)sender
{
	NSArray *currentAnnotations = [[selectionTimeline annotations] copy];
	for(Annotation* annotation in currentAnnotations)
	{
		[selectionTimeline removeAnnotation:annotation];
	}
	[currentAnnotations release];
	
	NSMutableArray *annotations = [NSMutableArray array];
	NSArray *selectedTraces = [anotoView selectedTraces];
	AnotoDataSource *source = (AnotoDataSource*)[[[anotoView dataSets] objectAtIndex:0] source];
	
	NSTimeInterval start = 0;
	NSTimeInterval end = 0;
	NSMutableArray *currentAnnotationTraces = [NSMutableArray array];
	
	for(AnotoTrace *trace in selectedTraces)
	{		
		start = CMTimeGetSeconds([trace startTime]);
		if((((start - end) > 2) || ((start - end) < -1))
		   && ([currentAnnotationTraces count] > 0))
		{
			Annotation *annotation = [source createAnnotationFromTraces:currentAnnotationTraces saveImage:NO];
			[annotation setIsDuration:NO];
			[annotation setCategory:selectionCategory];
			[annotations addObject:annotation];
			[currentAnnotationTraces removeAllObjects];
		}
		
		[currentAnnotationTraces addObject:trace];
		end = CMTimeGetSeconds([trace endTime]);
	}
	
	if([currentAnnotationTraces count] > 0)
	{
		Annotation *annotation = [source createAnnotationFromTraces:currentAnnotationTraces saveImage:NO];
		[annotation setIsDuration:NO];
		[annotation setCategory:selectionCategory];
		[annotations addObject:annotation];
		[currentAnnotationTraces removeAllObjects];
	}
	
	[selectionTimeline addAnnotations:annotations];
}

- (IBAction)modeButtonClick:(id)sender
{
	if([sender isKindOfClass:[NSSegmentedControl class]])
	{
		int clickedSegment = [sender selectedSegment];
		int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
		if(clickedSegmentTag)
		{
			if(!selectionTimeline)
			{
				NSRect visible = [anotoView visibleRect];
				
				NSRect scrollFrame = [notesScrollView frame];
				scrollFrame.size.height = scrollFrame.size.height - 100;
				scrollFrame.origin.y = 100;
				[notesScrollView setFrame:scrollFrame];
				
				visible.size.height = visible.size.height - 100;

				[anotoView scrollRectToVisible:visible];
				
				NSRect timelineFrame = scrollFrame;
				timelineFrame.size.height = 100;
				timelineFrame.origin.y = 0;
				
				selectionTimeline = [[TimelineView alloc] initWithFrame:timelineFrame];
				[selectionTimeline setMovie:[[AnnotationDocument currentDocument] movie]];
				[selectionTimeline toggleShowAnnotations];
				[selectionTimeline setShowActionButtons:NO];
				[(AnnotationVisualizer*)[selectionTimeline segmentVisualizer] toggleShowLabels];
				[selectionTimeline showTimes:YES];
				[selectionTimeline setAutoresizingMask:(NSViewMaxYMargin | NSViewWidthSizable)];
				[[[self window] contentView] addSubview:selectionTimeline];
				[selectionTimeline release];
				
				if(!selectionCategory)
				{
					selectionCategory = [[AnnotationCategory alloc] init];
					[selectionCategory setName:@"Selected Notes"];
					[selectionCategory setColor:[NSColor yellowColor]];
				}
				[selectionTimeline setAnnotationFilter:[[AnnotationCategoryFilter alloc] initForCategories:[NSArray arrayWithObject:selectionCategory]]];
				[[AppController currentApp] addAnnotationView:selectionTimeline];
				
				[anotoView toggleSelectionMode:self];
				
				[[NSNotificationCenter defaultCenter] addObserver:self
														 selector:@selector(updateSelection:)
															 name:DPMaskedSelectionChangedNotification
														   object:anotoView];
				
			}
		}
		else
		{
			if(selectionTimeline)
			{
				[[AppController currentApp] removeAnnotationView:selectionTimeline];
				[selectionTimeline removeFromSuperview];
				selectionTimeline = nil;
				
				NSRect scrollFrame = [notesScrollView frame];
				scrollFrame.size.height = scrollFrame.size.height + 100;
				scrollFrame.origin.y = 0;
				[notesScrollView setFrame:scrollFrame];
				
				[anotoView toggleSelectionMode:self];
				
			}

		}
	}
}

- (IBAction)showPrintPanel:(id)sender;
{
	AnotoNotesData *notesData = [[anotoView dataSets] objectAtIndex:0];
	AnotoDataSource *dataSource = (AnotoDataSource*)[notesData source];
	NSString *postscriptFile = [dataSource postscriptFile];
	
	if(!postscriptFile || ([postscriptFile length] == 0))
	{
		NSAlert *nofileAlert = [[[NSAlert alloc] init] autorelease];
		[nofileAlert setMessageText:@"There is no Postscript File to print!"];
		[nofileAlert addButtonWithTitle:@"OK"];
		
		[nofileAlert beginSheetModalForWindow:[self window]
								  modalDelegate:self
								 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
									contextInfo:nil];
		
		return;
	}
	
	[printerList removeAllItems];
	
	[printerList addItemsWithTitles:[NSPrinter printerNames]];
	
	NSPrinter *currentPrinter = [[NSPrintInfo sharedPrintInfo] printer];
	[printerList selectItemWithTitle:[currentPrinter name]];
	
	[printProgressIndicator stopAnimation:self];
	[printProgressIndicator setHidden:YES];
	[printerList setHidden:NO];
	[printButton setEnabled:YES];
	[printLabel setStringValue:@"Printer:"];
	
	[NSApp beginSheet: printPanel
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
}

- (IBAction)closePrintPanel:(id)sender
{
	[NSApp endSheet:printPanel];
}

- (IBAction)print:(id)sender
{
	
	NSString *printerName = [printerList titleOfSelectedItem];
	
	NSArray *nameComponents = [printerName componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
	
	NSMutableString *queueName = [NSMutableString string];
	
	BOOL first = YES;
	
	for(NSString *component in nameComponents)
	{
		//NSLog(@"Component: %@",component);
		if(!first)
		{
			[queueName appendString:@"_"];
		}
		
		[queueName appendString:component];
		
		first = NO;
	}
	
	NSLog(@"Print to printer: %@",queueName);
	
	[printQueue release];
	printQueue = [queueName copy];
	
	[printProgressIndicator setIndeterminate:YES];
	[printProgressIndicator startAnimation:self];
	[printProgressIndicator setHidden:NO];
	[printerList setHidden:YES];
	[printButton setEnabled:NO];
	[printLabel setStringValue:[NSString stringWithFormat:@"Printing to %@…",printerName]];
	
	AnotoNotesData *notesData = [[anotoView dataSets] objectAtIndex:0];
	AnotoDataSource *dataSource = (AnotoDataSource*)[notesData source];
	NSString *postscriptFile = [dataSource postscriptFile];
	
	NSTask *task = [[NSTask alloc] init];
	//[task setCurrentDirectoryPath:[postscriptFile stringByDeletingLastPathComponent]];
	[task setLaunchPath:@"/usr/bin/lpr"];
	[task setArguments:[NSArray arrayWithObjects:@"-P",queueName,postscriptFile,nil]];
	
	[task launch];
	[task waitUntilExit];
	[task release];
	
	
	NSPrinter *currentPrinter = [NSPrinter printerWithName:[printerList titleOfSelectedItem]];
	[[NSPrintInfo sharedPrintInfo] setPrinter:currentPrinter];
	
	//[NSApp endSheet:printPanel];
	
	printMonitor = [NSTimer scheduledTimerWithTimeInterval:1.0
													target:self
												  selector:@selector(checkPrintStatus:)
												  userInfo:nil
												   repeats:YES];
	
}

- (void)checkPrintStatus:(id)sender
{
    NSTask *queueTask = [[NSTask alloc] init];
    NSPipe *newPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [newPipe fileHandleForReading];
    NSData *inData = nil;
	
    // write handle is closed to this process
    [queueTask setStandardOutput:newPipe];
	[queueTask setLaunchPath:@"/usr/bin/lpq"];
	[queueTask setArguments:[NSArray arrayWithObjects:@"-P",printQueue,nil]];
    [queueTask launch];
	
    while ((inData = [readHandle availableData]) && [inData length]) {
		NSString *string = [[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding];
		//NSLog(@"Print status: %@",string);
		
		if([string length] > 0)
		{			
			if([string rangeOfString:@"no entries"].location != NSNotFound)
			{
				[printMonitor invalidate];
				printMonitor = nil;
				
				[NSApp endSheet:printPanel];
				[printProgressIndicator stopAnimation:self];
				[printProgressIndicator setHidden:YES];
				[printerList setHidden:NO];
				[printButton setEnabled:YES];
				[printLabel setStringValue:@"Printer:"];
			}
		}
        [string release];
    }
	
    [queueTask release];
}
	 
	 
- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	
}

- (IBAction)showDataSets:(id)sender
{
	if(notesDataSets)
	{
		[notesDataSets removeAllObjects];
	}
	else
	{
		notesDataSets = [[NSMutableArray alloc] init];
	}
	
	NSArray *allData = [[AnnotationDocument currentDocument] dataSets];
	
	for(TimeCodedData *data in allData)
	{
		if([data isKindOfClass:[AnotoNotesData class]])
		{
			[notesDataSets addObject:data];
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

- (IBAction)newSession:(id)sender {
}

- (void) colorClick: (id) sender {    // sender is the table view
	//editingCategory = [[[AppController currentDoc] categories] objectAtIndex:[sender clickedRow]];
	colorEditDataSet = [notesDataSets objectAtIndex:[dataSetsTable selectedRow]];
	NSColor *color = [(AnotoNotesData*)colorEditDataSet color];
	NSColorPanel* colorPanel = [NSColorPanel sharedColorPanel];
	[colorPanel setTarget: self];
	[colorPanel setColor: color];
	[colorPanel setContinuous:NO];
	[colorPanel setAction: @selector (colorChanged:)];
	[colorPanel makeKeyAndOrderFront: self];
}

- (void) colorChanged: (id) sender {    // sender is the NSColorPanel
	[(AnotoNotesData*)colorEditDataSet setColor:[sender color]];
	[dataSetsTable reloadData];
	[anotoView redrawAllTraces];
}

#pragma mark Table View Delegate Methods
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
	
	return [notesDataSets count];
}


//- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//	NSTextFieldCell *cell = [tableColumn dataCell];
//	if([[tableColumn identifier] isEqualToString: @"DataSet"])
//	{
//		AnotoNotesData *dataSet = [notesDataSets objectAtIndex:row];
//		[cell setBackgroundColor:[dataSet color]];	
//	}
//	else {
//		[cell setDrawsBackground:NO];
//	}
//	return cell;
//}


- (id) tableView:(NSTableView*) aTableView objectValueForTableColumn:(NSTableColumn*) tableColumn row:(NSInteger) rowIndex {
	NSString *identifier = [tableColumn identifier];
	NSParameterAssert(rowIndex >= 0 && rowIndex < [notesDataSets count]);
	AnotoNotesData *dataSet = [notesDataSets objectAtIndex:rowIndex];
	if([identifier isEqualToString:@"DataSet"])
	{
		NSString *sourceName = [[[dataSet source] name] stringByReplacingOccurrencesOfString:@"Digital Notes - " withString:@""];
		
		return [sourceName stringByAppendingFormat:@" - %@",[dataSet name]];
	}
	else if([identifier isEqualToString:@"Visible"])
	{
		return [NSNumber numberWithBool:[[anotoView dataSets] containsObject:dataSet]];
	}
	else if([identifier isEqualToString:@"Color"])
	{
		return [dataSet color];
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
	NSParameterAssert(rowIndex >= 0 && rowIndex < [notesDataSets count]);
	AnotoNotesData *dataSet = [notesDataSets objectAtIndex:rowIndex];
	if([identifier isEqualToString:@"Visible"])
	{
		if([anObject boolValue])
		{
			[anotoView addData:dataSet];
		}
		else
		{
			[anotoView removeData:dataSet];
		}
	}
	
}


@end
