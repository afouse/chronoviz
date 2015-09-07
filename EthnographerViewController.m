//
//  EthnographerViewController.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/24/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "EthnographerViewController.h"
#import "EthnographerPlugin.h"
#import "EthnographerPrinter.h"
#import "Annotation.h"
#import "AnnotationCategory.h"
#import "AnnotationCategoryFilter.h"
#import "AnnotationVisualizer.h"
#import "EthnographerNotesView.h"
#import "AnotoNotesData.h"
#import "EthnographerDataSource.h"
#import "AnotoTrace.h"
#import "AnnotationDocument.h"
#import "AppController.h"
#import "TimelineView.h"
#import "DPMaskedSelectionView.h"
#import "ColorTaggedTextCell.h"
#import "ColorCell.h"
#import "DPDataSelectionPanel.h"

@interface EthnographerViewController (Private)

- (void)checkPrintStatus:(id)sender;
- (void)showCurrentSession:(AnotoNotesData*)session;

@end

@implementation EthnographerViewController

@synthesize currentSession;

- (id)init
{
	if(![super initWithWindowNibName:@"AnotoWindow"])
		return nil;
	
	selectionTimeline = nil;
	selectionCategory = nil;
	
	return self;
}

- (void) dealloc
{
    [dataSelectionPanel release];
    
    [anotoView removeObserver:self forKeyPath:@"title"];
    [[EthnographerPlugin defaultPlugin] removeObserver:self forKeyPath:@"annotationDataSource"];
    [self.currentSession removeObserver:self forKeyPath:@"color"];
    self.currentSession = nil;
    
	[selectionCategory release];
	[notesDataSets release];
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
    
    [anotoView addObserver:self
                forKeyPath:@"title"
                   options:0
                   context:NULL];
    
    [[EthnographerPlugin defaultPlugin] addObserver:self
                                         forKeyPath:@"annotationDataSource"
                                            options:0
                                            context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"title"]) {
        
		NSString *newTitle = anotoView.title;
        if(newTitle)
        {
            [[self window] setTitle:newTitle];
        }
	}
    else if ([keyPath isEqual:@"annotationDataSource"]) {
        EthnographerDataSource *source = [object annotationDataSource];
        for(AnotoNotesData *data in [anotoView dataSets])
        {
            if((EthnographerDataSource*)data.source == source)
            {
                [self showCurrentSession:[source currentSession]];
            }
        }
	}
    else if ([keyPath isEqual:@"color"])
    {
        [anotoView redrawAllTraces];
    }
}

- (id<AnnotationView>)annotationView
{
    return [self anotoView];
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
	EthnographerDataSource *source = (EthnographerDataSource*)[[[anotoView dataSets] objectAtIndex:0] source];
	
	NSTimeInterval start = 0;
	NSTimeInterval end = 0;
	NSMutableArray *currentAnnotationTraces = [NSMutableArray array];
	
	for(AnotoTrace *trace in selectedTraces)
	{		
		QTGetTimeInterval([trace startTime], &start);
		if((((start - end) > 2) || ((start - end) < -1))
		   && ([currentAnnotationTraces count] > 0))
		{
			Annotation *annotation = [source createAnnotationFromTraces:currentAnnotationTraces saveImage:NO scale:3.0];
			[annotation setIsDuration:NO];
			[annotation setCategory:selectionCategory];
			[annotations addObject:annotation];
			[currentAnnotationTraces removeAllObjects];
		}
		
		[currentAnnotationTraces addObject:trace];
		QTGetTimeInterval([trace endTime],&end);
	}
	
	if([currentAnnotationTraces count] > 0)
	{
		Annotation *annotation = [source createAnnotationFromTraces:currentAnnotationTraces saveImage:NO scale:3.0];
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
				
				[[AppController currentApp] addAnnotationView:selectionTimeline];
				[selectionTimeline reset];
				[selectionTimeline setAnnotationFilter:[[AnnotationCategoryFilter alloc] initForCategories:[NSArray arrayWithObject:selectionCategory]]];
				
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
				
				[[NSNotificationCenter defaultCenter] removeObserver:self];
				
			}
			
		}
	}
}

- (IBAction)showPrintPanel:(id)sender;
{
	AnotoNotesData *notesData = [[anotoView dataSets] objectAtIndex:0];
	EthnographerDataSource *dataSource = (EthnographerDataSource*)[notesData source];
	
	if(!dataSource.backgroundTemplate)
	{
		NSAlert *nofileAlert = [[[NSAlert alloc] init] autorelease];
		[nofileAlert setMessageText:@"A template needs to be associated with these notes before printing."];
		[nofileAlert addButtonWithTitle:@"OK"];
		
		[nofileAlert beginSheetModalForWindow:[self window]
								modalDelegate:self
							   didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
								  contextInfo:nil];
		
		return;
	}
	
	[[[EthnographerPlugin defaultPlugin] printer] printAnoto:dataSource
												  fromWindow:[self window]];
	
}


- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	
}

- (void)showCurrentSession:(AnotoNotesData *)session
{
    if(session != nil)
    {
        if(self.currentSession)
        {
            [self.currentSession removeObserver:self forKeyPath:@"color"];
        }
        self.currentSession = session;
        [self.currentSession addObserver:self
                              forKeyPath:@"color"
                                 options:0
                                 context:NULL];
        
        if([sessionControlView window] != [self window])
        {
            NSSize sessionViewSize = [sessionControlView bounds].size;
            CGFloat viewHeight = sessionViewSize.height;
            
            NSRect visible = [anotoView visibleRect];
            
            NSRect scrollFrame = [notesScrollView frame];
            scrollFrame.size.height = scrollFrame.size.height - viewHeight;
            [notesScrollView setFrame:scrollFrame];
            
            visible.size.height = visible.size.height - viewHeight;
            
            [anotoView scrollRectToVisible:visible];
            
            NSRect viewFrame = scrollFrame;
            viewFrame.size.height = viewHeight;
            viewFrame.origin.y = scrollFrame.origin.y + scrollFrame.size.height;
            
            [sessionControlView setFrame:viewFrame];
            [[[self window] contentView] addSubview:sessionControlView];
        }
        
    }
}

- (IBAction)newSession:(id)sender {
    [self showCurrentSession:[(EthnographerDataSource*)[self.currentSession source] newSession]];
    [[EthnographerPlugin defaultPlugin] resetTrajectories];
}

#pragma mark Data Sets

- (IBAction)showDataSets:(id)sender
{
    if(!dataSelectionPanel)
    {
        dataSelectionPanel = [[DPDataSelectionPanel alloc] initForView:anotoView];
        [dataSelectionPanel setDataClass:[AnotoNotesData class]];
        [dataSelectionPanel setAllowGroupColorChange:NO];
        [dataSelectionPanel setAllowItemRename:YES];
        [dataSelectionPanel setAllowGroupRename:NO];
        [dataSelectionPanel setChangeCategoryNames:YES];
    }
    
    [dataSelectionPanel showDataSets:self];
    
//	if(notesDataSets)
//	{
//		[notesDataSets removeAllObjects];
//	}
//	else
//	{
//		notesDataSets = [[NSMutableArray alloc] init];
//	}
//	
//	NSArray *allData = [[AnnotationDocument currentDocument] dataSets];
//	
//	for(TimeCodedData *data in allData)
//	{
//		if([data isKindOfClass:[AnotoNotesData class]])
//		{
//			[notesDataSets addObject:data];
//		}
//	}
//	
//	[dataSetsTable reloadData];
//	
//	[NSApp beginSheet: dataSetsPanel
//	   modalForWindow: [self window]
//		modalDelegate: self
//	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
//		  contextInfo: nil];
}

- (IBAction)closeDataSets:(id)sender
{
	[NSApp endSheet:dataSetsPanel];
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
