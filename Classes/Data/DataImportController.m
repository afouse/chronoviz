//
//  DataImportController.m
//  Annotation
//
//  Created by Adam Fouse on 8/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DataImportController.h"
#import "DataSource.h"
#import "AppController.h"
#import "DPViewManager.h"
#import "VideoProperties.h"
#import "Annotation.h"
#import "AnnotationDocument.h"
#import "AnnotationCategory.h"
#import "TimeSeriesData.h"
#import "AnnotationView.h"
#import "MultiTimelineView.h"
#import "GeographicTimeSeriesData.h"
#import "TimeCodedDataPoint.h"
#import "TimeCodedString.h"
#import "TimeCodedImageFiles.h"
#import "NSStringParsing.h"
#import "NSStringFileManagement.h"
#import "NSString+NDCarbonUtilities.h"
#import "DataSource.h"
#import "SenseCamDataSource.h"
#import "ActivityTrailsDataSource.h"
#import "XPlaneDataSource.h"
#import "AnotoDataSource.h"
#import "AnotoViewController.h"
#import "AnotoView.h"
#import "AnotoNotesData.h"
#import "TranscriptView.h"
#import "TranscriptViewController.h"
#import "TranscriptData.h"
#import "AnnotationSet.h"
#import "InqScribeDataSource.h"
#import "ElanDataSource.h"
#import "AnnotationVisualizer.h"
#import "AnnotationCategoryFilter.h"
#import "TimeSeriesVisualizer.h"
#import "DPImageSequenceDataSource.h"

// function for sorting data import table

int importSort( id obj1, id obj2, void *context ) {
	
	BOOL import1 = [(id)context containsObject:obj1];
	BOOL import2 = [(id)context containsObject:obj2];
	
	// Compare and return
	if(import1 && !import2)
		return NSOrderedAscending;
	else if(!import1 && import2)
		return NSOrderedDescending;
	else
		return NSOrderedSame;
}

@interface DataImportController (TimeCalculation)

- (NSTimeInterval)absoluteOffset;
- (NSDate*)startDate;

@end

@implementation DataImportController

- (id)init
{
	if(![super initWithWindowNibName:@"DataImport"])
		return nil;
	
	data = nil;
	cancelLoad = NO;
	lockedTypeCell = nil;
	
	return self;
}

- (void) dealloc
{
	[lockedTypeCell release];
	[headings release];
	[labels release];
	[types release];
	[variablesToImport release];
	[variablesToDisplay release];
    [variablesToDelete release];
	[possibleDataTypes release];
    [existingVariables release];
	[super dealloc];
}

- (IBAction)showWindow:(id)sender
{	
	if(!dataSource)
	{
		if([[[AppController currentDoc] dataSources] count] < 1)
		{
			[self setDataSource:nil];
		}
		else
		{
			[self setDataSource:[[[AppController currentDoc] dataSources] objectAtIndex:0]];
		}
		
	}
    
    [variablesToDelete release];
    variablesToDelete = [[NSMutableArray alloc] init];
	
	[super showWindow:sender];
}


- (void)setDataSource:(DataSource*)theDataSource;
{
	[self window];
	
	dataSource = theDataSource;
	[dataSource setDelegate:(NSObject<DataSourceDelegate>*) self];
	data = [dataSource dataArray];
	
	if(dataSource == nil)
		return;
	
	[[self window] setTitle:[dataSource name]];
	[dataSourceTypeField setStringValue:[@"Data Type: " stringByAppendingString:[[dataSource class] dataTypeName]]];
    NSTableColumn *displayColumn = [variablesTable tableColumnWithIdentifier:@"display"];
	if([dataSource imported])
    {
        [displayColumn setHidden:YES];
        [importButton setTitle:@"Save"];
    }
    else
    {
        [displayColumn setHidden:NO];
        [importButton setTitle:@"Import"];
    }
    
	if([dataSource predefinedTimeCode] && ![timeCodingView isHidden])
	{
		[timeCodingView setHidden:YES];
		[labelField setFrameOrigin:NSMakePoint([labelField frame].origin.x,[labelField frame].origin.y + [timeCodingView frame].size.height)];
        [selectAllButton setFrameOrigin:NSMakePoint([selectAllButton frame].origin.x,[selectAllButton frame].origin.y + [timeCodingView frame].size.height)];
        [selectNoneButton setFrameOrigin:NSMakePoint([selectNoneButton frame].origin.x,[selectNoneButton frame].origin.y + [timeCodingView frame].size.height)];
		NSRect frame = [variablesView frame];
		frame.size.height = [variablesView frame].size.height + [timeCodingView frame].size.height;
		//frame.origin.y = [variablesView frame].origin.y + [timeCodingView frame].size.height;
		[variablesView setFrame:frame];
		
		
	}
	else if(![dataSource predefinedTimeCode])
	{
		if([timeCodingView isHidden])
		{
			[timeCodingView setHidden:NO];
			[labelField setFrameOrigin:NSMakePoint([labelField frame].origin.x,[labelField frame].origin.y - [timeCodingView frame].size.height)];
			NSRect frame = [variablesView frame];
			frame.size.height = [variablesView frame].size.height - [timeCodingView frame].size.height;
			[variablesView setFrame:frame];		
		}
		
		if([dataSource timeCoded])
		{
			if([dataSource absoluteTime])
			{
				[timeCodingButtons selectCellAtRow:1 column:0];
			}
			else 
			{
				[timeCodingButtons selectCellAtRow:2 column:0];
			}
				
		}
		else
		{
			[timeCodingButtons selectCellAtRow:0 column:0];	
		}
		[self changeTimeCoding:self];
	}

	double offset = (double)[dataSource range].time.timeValue/(double)[dataSource range].time.timeScale;
	[timeOffsetField setDoubleValue:offset];
	
	[timeColumnButton removeAllItems];
	NSArray *columns = [NSArray arrayWithArray:[dataView tableColumns]];
	for(NSTableColumn *column in columns)
	{
		[dataView removeTableColumn:column];
	}
	
	// Set up data table
	NSArray *headingsTemp = [data objectAtIndex:0];
	[headings release];
	headings = [[NSMutableArray alloc] initWithCapacity:[headingsTemp count]];
	int i = 0;
	for(NSString *heading in headingsTemp)
	{
//		int duplicate = 1;
//		NSString *headingTitle = heading;
//		while([columnButton itemWithTitle:heading])
//		{
//			heading = [headingTitle stringByAppendingFormat:@"(%i)",duplicate];
//			duplicate++;
//		}
		[headings addObject:heading];
		[timeColumnButton addItemWithTitle:heading];
		NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:[NSNumber numberWithInt:i]];
		[[column headerCell] setStringValue:heading];
		[dataView addTableColumn:column];
		[column release];
		i++;
	}
	
	[timeColumnButton setAutoenablesItems:NO];
	
	[dataView reloadData];
	
	// Set up variables table
	NSPopUpButtonCell *tableButton = [[variablesTable tableColumnWithIdentifier:@"type"] dataCell];
	[tableButton removeAllItems];
	
	[possibleDataTypes release];
	possibleDataTypes = [[dataSource possibleDataTypes] retain];
	[tableButton addItemsWithTitles:possibleDataTypes];
	
	[labels release];
	[types release];
	[variablesToImport release];
	[variablesToDisplay release];
    [existingVariables release];
	labels = [[NSMutableDictionary alloc] init];
	types = [[NSMutableDictionary alloc] init];
	variablesToImport = [[NSMutableArray alloc] init];
	variablesToDisplay = [[NSMutableArray alloc] init];
    existingVariables = [[NSMutableArray alloc] init];
	
	NSArray *views = [[AppController currentApp] annotationViews];
	NSMutableArray *displayedData = [NSMutableArray array];
	for(id<AnnotationView> view in views)
	{
		[displayedData addObjectsFromArray:[view dataSets]];
	}
	
	// Load the defaults or current state
	if([[dataSource dataSets] count] > 0)
	{
		for(TimeCodedData *dataSet in [dataSource dataSets])
		{
			BOOL displayed = [displayedData containsObject:dataSet];
			if([dataSet isMemberOfClass:[TimeSeriesData class]])
			{
				[variablesToImport addObject:[dataSet variableName]];
				[labels setObject:[dataSet name] forKey:[dataSet variableName]];
				[types setObject:DataTypeTimeSeries forKey:[dataSet variableName]];
				if(displayed)
				{
					[variablesToDisplay addObject:[dataSet variableName]];
				}
			}
			else if([dataSet isMemberOfClass:[GeographicTimeSeriesData class]])
			{
				NSString *latVariable = [(GeographicTimeSeriesData*)dataSet latVariableName];
				NSString *lonVariable = [(GeographicTimeSeriesData*)dataSet lonVariableName];
				[variablesToImport addObject:latVariable];
				[variablesToImport addObject:lonVariable];
				[labels setObject:[dataSet name] forKey:latVariable];
				[labels setObject:[dataSet name] forKey:lonVariable];
				[types setObject:DataTypeGeographicLat forKey:latVariable];
				[types setObject:DataTypeGeographicLon forKey:lonVariable];
				if(displayed)
				{
					[variablesToDisplay addObject:latVariable];
					[variablesToDisplay addObject:lonVariable];	
				}
			}
			else
			{
				
			}
		}
        
        [existingVariables addObjectsFromArray:variablesToImport];
        
	}
	else
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSArray *defaultsArray = [defaults arrayForKey:[@"AFDataSourceDefaults" stringByAppendingString:[[dataSource class] defaultsIdentifier]]];
		
		if(defaultsArray)
		{
			for(NSDictionary* entry in defaultsArray)
			{
				NSString *variable = [entry objectForKey:@"Variable"];
				
				if([headings containsObject:variable])
				{
					[variablesToImport addObject:variable];
					
					id label = [entry objectForKey:@"Label"];
					if(label != [NSNull null])
					{
						[labels setObject:label forKey:variable];
					}
					
					id type = [entry objectForKey:@"Type"];
					if((type != [NSNull null]) && ![dataSource lockedDataType:variable])
					{
						[types setObject:type forKey:variable];
					}
					
					NSNumber *display = [entry objectForKey:@"Display"];
					if([display boolValue])
					{
						[variablesToDisplay addObject:variable];
					}	
				}
			}
			
			NSDictionary *timeCodingDict = [defaults dictionaryForKey:[@"AFDataSourceTimeCodingDefaults" stringByAppendingString:[[dataSource class] defaultsIdentifier]]];
			if(timeCodingDict)
			{
				NSString *timeColumnName = [timeCodingDict objectForKey:@"TimeColumnName"];
				if([headings containsObject:timeColumnName])
				{
					[timeCodingButtons selectCellAtRow:[[timeCodingDict objectForKey:@"TimeCoding"] intValue] column:0];
					[self changeTimeCoding:self];
					[timeColumnButton selectItemWithTitle:timeColumnName];
					[dataSource setTimeColumn:[timeColumnButton indexOfSelectedItem]];	
				}
			}
		}
		else
		{
			NSArray *defaultVariablesToImport = [dataSource defaultVariablesToImport];
			for(NSString* variable in defaultVariablesToImport)
			{
				if([headings containsObject:variable])
				{
					[variablesToImport addObject:variable];
					[variablesToDisplay addObject:variable];
				}
			}
			
		}
		[timeColumnButton selectItemAtIndex:[dataSource timeColumn]];
	}
	
	[headings sortUsingFunction:importSort context:variablesToImport];
	
	for(NSString *variable in variablesToImport)
	{
		if([headings containsObject:variable])
		{
			[headings removeObject:variable];
			[headings insertObject:variable atIndex:0];
		}
	}
	
	[variablesTable reloadData];
	
	[timeColumnButton selectItemAtIndex:[dataSource timeColumn]];
	NSTextFieldCell* columnCell = [[[dataView tableColumns] objectAtIndex:[dataSource timeColumn]] dataCell];
	[columnCell setTextColor:[NSColor grayColor]];
	[[[dataView tableColumns] objectAtIndex:[dataSource timeColumn]] setDataCell:columnCell];
	//[[timeColumnButton itemAtIndex:1] setEnabled:NO];
	
//	[columnButton selectItemAtIndex:fmin(1,[headings count] - 1)];
//	[labelField setStringValue:[columnButton titleOfSelectedItem]];
//	[dataView selectColumnIndexes:[NSIndexSet indexSetWithIndex:[columnButton indexOfSelectedItem]] 
//			  byExtendingSelection:NO];
//	[[columnButton itemAtIndex:0] setEnabled:NO];
	
	//[dataString release];
}

- (void) timeCodeAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertFirstButtonReturn) {
		
		NSArray *dataSets = [[dataSource dataSets] copy];
		
		for(TimeCodedData *dataSet in dataSets)
		{
			[dataSource removeDataSet:dataSet];
			[[[AppController currentApp] viewManager] removeData:dataSet];
		}
		
		[dataSets release];
		[dataSource reset];
		//[variablesToImport removeAllObjects];
		//[variablesToDisplay removeAllObjects];
		
		[variablesTable reloadData];
		
		[self changeTimeCoding:self];
    }
	else
	{
		if([dataSource timeCoded])
		{
			if([dataSource absoluteTime])
			{
				[timeCodingButtons selectCellAtRow:1 column:0];
			}
			else
			{
				[timeCodingButtons selectCellAtRow:2 column:0];
			}
		}
		else
		{
			[timeCodingButtons selectCellAtRow:0 column:0];
		}
		
	}
}

- (IBAction)changeTimeCoding:(id)sender
{	
	NSInteger selected = [timeCodingButtons selectedRow];
	NSInteger currentMode = -1;
	
	if(![dataSource timeCoded])
	{
		currentMode = 0;
	}
	else
	{
		if([dataSource absoluteTime])
		{
			currentMode = 1;
		}
		else
		{
			currentMode = 2;
		}
	}
	
	if(![dataSource predefinedTimeCode] 
	   && (currentMode != selected)
	   && ([[dataSource dataSets] count] > 0))
	{
		NSWindow *dataWindow = [self window];
		
		NSAlert *confirm = [[NSAlert alloc] init];
		[confirm setMessageText:@"Changing the time coding will delete any existing data sets you have imported from this data source."];
		[confirm setInformativeText:@"Continue with changing the time coding?"];
		[confirm addButtonWithTitle:@"Change time coding"];
		[confirm addButtonWithTitle:@"Cancel"];
		
		[confirm beginSheetModalForWindow:dataWindow
							modalDelegate:self 
						   didEndSelector:@selector(timeCodeAlertDidEnd:returnCode:contextInfo:) 
							  contextInfo:NULL];
		return;
	}
	
	
	if(selected == 0)
	{
		[timeOffsetField setEnabled:NO];
		[timeColumnButton setEnabled:NO];
		[dataSource setTimeCoded:NO];
		[dataSource setAbsoluteTime:NO];
	}
	else if(selected == 1)
	{
		[timeOffsetField setEnabled:NO];
		[timeColumnButton setEnabled:YES];	
		[dataSource setTimeCoded:YES];
		[dataSource setAbsoluteTime:YES];
	}
	else if(selected == 2)
	{
		[timeOffsetField setEnabled:YES];
		[timeColumnButton setEnabled:YES];	
		[dataSource setTimeCoded:YES];
		[dataSource setAbsoluteTime:NO];
	}
}

- (IBAction)selectTimeColumn:(id)sender
{
	NSTextFieldCell* columnCell = [[[dataView tableColumns] objectAtIndex:[dataSource timeColumn]] dataCell];
	[columnCell setTextColor:[NSColor blackColor]];
	
	[dataSource setTimeColumn:[timeColumnButton indexOfSelectedItem]];
	
	columnCell = [[[dataView tableColumns] objectAtIndex:[dataSource timeColumn]] dataCell];
	[columnCell setTextColor:[NSColor grayColor]];
	
	[dataView reloadData];
}

- (IBAction)selectAllDataColumns:(id)sender {
    
    [variablesToImport removeAllObjects];
    [variablesToDisplay removeAllObjects];
    for(NSString *heading in headings)
    {
        [variablesToImport addObject:heading];
        [variablesToDisplay addObject:heading];
    }
    
    [variablesTable reloadData];
    
}

- (IBAction)selectNoDataColumns:(id)sender {
    [variablesToImport removeAllObjects];
    [variablesToDisplay removeAllObjects];
    [variablesTable reloadData];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[dataSource setDelegate:nil];
	//[data release];
}

- (NSDate*)startDate
{
	int dateColumn = 0;
	for(NSString* title in [[dataSource dataArray] objectAtIndex:0])
	{
		if([title caseInsensitiveCompare:@"date"] == NSOrderedSame)
		{
			NSLog(@"date column: %i",dateColumn);
			break;
		}
		dateColumn++;
	}
	
	NSString *startDate = [[[dataSource dataArray] objectAtIndex:1] objectAtIndex:dateColumn];
	NSString *timeString = [[[dataSource dataArray] objectAtIndex:1] objectAtIndex:[dataSource timeColumn]];
	
	NSRange component;
	component.length = 2;
	component.location = 0;
	int year = 2000 + [[startDate substringWithRange:component] intValue];
	component.location = 2;
	int month = [[startDate substringWithRange:component] intValue];
	component.location = 4;
	int day = [[startDate substringWithRange:component] intValue];
	component.location = 0;
	int hour = [[timeString substringWithRange:component] intValue];
	component.location = 2;
	int minute = [[timeString substringWithRange:component] intValue];
	component.location = 4;
	int second = [[timeString substringWithRange:component] intValue];
	
	
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
	NSDateComponents *dateComponents = [gregorian components:unitFlags fromDate:[NSDate date]];
	
	[dateComponents setYear:year];
	[dateComponents setMonth:month];
	[dateComponents setDay:day];
	[dateComponents setHour:hour];
	[dateComponents setMinute:minute];
	[dateComponents setSecond:second];
	
	return [gregorian dateFromComponents:dateComponents];
}

- (NSTimeInterval)absoluteOffset
{	
	NSDate *movieStart = [[[AnnotationDocument currentDocument] videoProperties] startDate];
	
	NSDate *startDate = [dataSource startDate];
	if(!startDate)
	{
		startDate = [self startDate];
	}
	
	return [startDate timeIntervalSinceDate:movieStart];
}

- (IBAction)import:(id)sender
{	
	NSMutableArray *importTypes = [NSMutableArray arrayWithCapacity:[variablesToImport count]];
	NSMutableArray *newVariables = [NSMutableArray arrayWithCapacity:[variablesToImport count]];
	
    for(NSString *variable in variablesToDelete)
    {
        if(![variablesToImport containsObject:variable])
        {
            for(TimeCodedData *dataSet in [dataSource dataSets])
            {
                if([variable isEqualToString:[dataSet variableName]])
                {
                    [dataSource removeDataSet:dataSet];
                    [[[AppController currentApp] viewManager] removeData:dataSet];
                }
            }
        }
    }
    [variablesToDelete release];
    variablesToDelete = nil;
    
	for(NSString *variable in variablesToImport)
	{
		BOOL found = NO;
		// If this dataSet has already been imported, don't import it again
		for(TimeCodedData *dataSet in [dataSource dataSets])
		{
			if([variable isEqualToString:[dataSet variableName]])
			{
				found = YES;
				break;
			}
		}
		
		if(!found)
		{		
			[newVariables addObject:variable];
			
			NSString *type = [types objectForKey:variable];
			if(!type)
			{
				type = [dataSource defaultDataType:variable];
				//type = [possibleDataTypes objectAtIndex:0];
			}
			[importTypes addObject:type];
			
		}
	}
	
	[self importVariables:newVariables asTypes:importTypes withLabels:labels];
	
	NSTimeInterval currentOffset;
	QTGetTimeInterval([dataSource range].time, &currentOffset);
	if(fabs([timeOffsetField floatValue] - currentOffset) > .0001)
	{
		QTTimeRange range = [dataSource range];
		range.time = QTMakeTimeWithTimeInterval([timeOffsetField floatValue]);
		[dataSource setRange:range];
	}
}

- (void)importVariables:(NSArray*)variables asTypes:(NSArray*)variableTypes withLabels:(NSDictionary*)variableLabels
{
	AnnotationDocument *doc = [AppController currentDoc];
	
	NSArray *dataSets = [dataSource importVariables:variables asTypes:variableTypes];
	
	BOOL setMovie = NO;
	
	NSTimeInterval oldTI;
	NSTimeInterval newTI;
	
	QTGetTimeInterval([[[AppController currentDoc] movie] duration], &oldTI);
	QTGetTimeInterval([dataSource range].duration, &newTI);
	
	if([[doc videoProperties] localVideo] && ((newTI - oldTI) > 1))
	{
		NSLog(@"Set duration: Old Time: %f, New Time: %f",oldTI,newTI);
		setMovie = YES;
	}
	
	//BOOL absoluteSource = [dataSource respondsToSelector:@selector(startDate)];
	
	NSDate* startDate = [dataSource startDate];
	
	if(([timeCodingButtons selectedRow] == 1) || (startDate && [dataSource predefinedTimeCode]))
	{
		NSLog(@"Absolute time!");
		if(setMovie && ![[AppController currentApp] absoluteTime])
		{
			[[AppController currentApp] setAbsoluteTime:YES];
			if(startDate)
			{
				[[[AnnotationDocument currentDocument] videoProperties] setStartDate:startDate];
			}
			else
			{
				startDate = [self startDate];
				[[[AnnotationDocument currentDocument] videoProperties] setStartDate:startDate];	
			}
		}
		else
		{
			NSTimeInterval offset = [self absoluteOffset];
			
			// If none of the data will show up in the data set, don't use the absolute time for alignment
			if(abs(offset) > oldTI)
			{
				offset = 0;
			}
			
			QTTimeRange range = [dataSource range];
			range.time.timeValue = offset * range.duration.timeScale;
			range.time.timeScale = range.duration.timeScale;
			[dataSource setRange:range];	
		}
	}
	
	if(setMovie)
	{
		[doc setDuration:[dataSource range].duration];
	}
	
	
	NSArray *views = [[AppController currentApp] annotationViews];
	NSMutableArray *displayedData = [NSMutableArray array];
	for(id<AnnotationView> view in views)
	{
		[displayedData addObjectsFromArray:[view dataSets]];
	}
	
	NSMutableArray *timelines = [NSMutableArray array];
	
	NSMutableArray *dataSetsToDisplay = [NSMutableArray array];
	
	for(id obj in dataSets)
	{
		if([obj isKindOfClass:[TimeCodedData class]])
		{
			TimeCodedData *dataSet = (TimeCodedData*)obj;
			NSString *variable = [dataSet variableName];
			NSString *label = [variableLabels objectForKey:variable];
			if(!label)
			{
				label = variable;
			}
			[dataSet setName:label];
			BOOL display = [variablesToDisplay containsObject:variable];
		
			if(display)
			{
				[dataSetsToDisplay addObject:dataSet];
			}
		}
	}
	
	NSArray *dataSetsRemainingToDisplay = [[[AppController currentApp] viewManager] showDataSets:dataSetsToDisplay ifRepeats:NO];
	
	for(TimeCodedData *dataSet in dataSetsRemainingToDisplay)
	{			
		if([dataSet isMemberOfClass:[GeographicTimeSeriesData class]])
		{
			if(![displayedData containsObject:dataSet])
			{
				[[[AppController currentApp] viewManager] showData:dataSet];
			}
		}
		else if([dataSet isMemberOfClass:[TimeSeriesData class]])
		{
			if(![displayedData containsObject:dataSet])
			{
				TimelineView *timeline = [[TimelineView alloc] initWithFrame:[[[AppController currentApp] timelineView] frame]];
				[timeline setMovie:[[AppController currentApp] movie]];
				[timeline setData:(TimeSeriesData*)dataSet];
				
				TimeSeriesVisualizer *viz = [[TimeSeriesVisualizer alloc] initWithTimelineView:timeline];
				[timeline setSegmentVisualizer:viz];
				[timeline addAnnotations:[doc annotations]];
				
				[timelines addObject:timeline];
				
				[viz release];
				[timeline release];
			}
		}
		else if([dataSet isKindOfClass:[TimeCodedImageFiles class]])
		{
            NSLog(@"Error: Data Import Controller trying to create Image Files Viewer.");
//			if(![displayedData containsObject:dataSet])
//			{
//				if([[[AnnotationDocument currentDocument] videoProperties] localVideo]
//                   && ([[AppController currentApp] mainView] == [[AppController currentApp] ])
//				{
//					[[AppController currentApp] showImageSequence:(TimeCodedImageFiles*)dataSet inMainWindow:YES];
//				}
//				else
//				{
//					[[AppController currentApp] showImageSequence:(TimeCodedImageFiles*)dataSet inMainWindow:NO];
//				}
//				
//			}
		}
		else if([dataSet isKindOfClass:[AnnotationSet class]])
		{
			AnnotationCategory *category = [doc categoryForName:[dataSource name]];
			if(!category)
			{
				category = [doc createCategoryWithName:[dataSource name]];
				[category autoColor];
			}
			
			if([(AnnotationSet*)dataSet useNameAsCategory])
			{
				category = [category valueForName:[dataSet name]];
				[category autoColor];
			}
			
			//[category setColor:[NSColor colorWithCalibratedRed:0.213 green:0.280 blue:0.536 alpha:1.000]];
			for(Annotation *annotation in [(AnnotationSet*)dataSet annotations])
			{
				[annotation addCategory:category];
			}
			[(AnnotationSet*)dataSet setCategory:category];
			
			AnnotationVisualizer *viz = nil;
			if([[[AnnotationDocument currentDocument] annotations] count] > 0)
			{
				TimelineView *timeline = [[[AppController currentApp] timelineView] addNewAnnotationTimeline:self];
				AnnotationCategoryFilter *dataFilter = [AnnotationCategoryFilter filterForCategory:category];
				[timeline setAnnotationFilter:dataFilter];
				viz = (AnnotationVisualizer*)[timeline segmentVisualizer];
				
				AnnotationFilter *otherFilter = [[[[AppController currentApp] timelineView] baseTimeline] annotationFilter];
				if(!otherFilter)
					otherFilter = [[[AnnotationCategoryFilter alloc] init] autorelease];
				
				if([otherFilter isKindOfClass:[AnnotationCategoryFilter class]])
				{
					[(AnnotationCategoryFilter*)otherFilter hideCategory:category];
				}

				[[[[AppController currentApp] timelineView] baseTimeline] setAnnotationFilter:otherFilter];
			}
			else
			{
				for(TimelineView *existing in [[[AppController currentApp] timelineView] timelines])
				{
					SegmentVisualizer *segViz = [existing segmentVisualizer];
					if([segViz isKindOfClass:[AnnotationVisualizer class]])
					{
						viz = (AnnotationVisualizer*)segViz;
						break;
					}
				}
			}
			
			if([viz lineUpCategories])
				[viz toggleAlignCategories];
			
			[doc addAnnotations:[(AnnotationSet*)dataSet annotations]];
		}
		else if ([dataSet isKindOfClass:[AnotoNotesData class]])
		{
			[[[AppController currentApp] viewManager] showData:dataSet];
			
		}
		else if ([dataSet isKindOfClass:[TranscriptData class]])
		{
			
			TranscriptViewController *transcriptView = [[TranscriptViewController alloc] init];
			[transcriptView showWindow:self];
			[[transcriptView window] makeKeyAndOrderFront:self];
			[[transcriptView transcriptView] setData:(TranscriptData*)dataSet];
			
			[[AppController currentApp] addDataWindow:transcriptView];
			[[AppController currentApp] addAnnotationView:[transcriptView transcriptView]];
			[transcriptView release];
		}
	}
	
	if([timelines count] > 0)
	{
		[[[AppController currentApp] timelineView] addTimelines:timelines];
	}
	
	[doc saveData];
	
	[dataSource setImported:YES];
	
	[[AppController currentApp] updateViewMenu];
	
	[[self window] performClose:self];
}

- (IBAction)cancel:(id)sender
{
	[[self window] performClose:self];
}

- (IBAction)cancelLoad:(id)sender
{
	cancelLoad = YES;
	[loadingWindow close];
}

- (IBAction)saveDefaults:(id)sender
{
	NSMutableArray *defaultsArray = [[NSMutableArray alloc] initWithCapacity:[variablesToImport count]];
	
	for(NSString* variable in variablesToImport)
	{
		id label = [labels objectForKey:variable];
		if(!label)
		{
			label = variable;
		}
		
		id type = [types objectForKey:variable];
		if(!type)
		{
			type = [possibleDataTypes objectAtIndex:0];
		}
		
		NSDictionary* entry = [NSDictionary dictionaryWithObjectsAndKeys:
							   variable,@"Variable",
							   [NSNumber numberWithBool:[variablesToDisplay containsObject:variable]],@"Display",
							   label,@"Label",
							   type,@"Type",
							   nil];
		[defaultsArray addObject:entry];
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:defaultsArray forKey:[@"AFDataSourceDefaults" stringByAppendingString:[[dataSource class] defaultsIdentifier]]];
	
	if(![timeCodingView isHidden])
	{
		NSDictionary* timeCoding = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithInt:[timeCodingButtons selectedRow]],@"TimeCoding",
									[timeColumnButton titleOfSelectedItem],@"TimeColumnName",
									nil];
									
		[defaults setObject:timeCoding forKey:[@"AFDataSourceTimeCodingDefaults" stringByAppendingString:[[dataSource class] defaultsIdentifier]]];
	}
}

#pragma mark Data Source Delegate Methods

-(void)dataSourceLoadStart
{
	cancelLoad = NO;
}

-(void)dataSourceLoadStatus:(CGFloat)percentage
{
	if(![loadingWindow isVisible] && !cancelLoad)
	{
		[loadingWindow makeKeyAndOrderFront:self];
		[loadingWindow setLevel:NSStatusWindowLevel];
		[loadingBar setUsesThreadedAnimation:YES];
		[loadingBar setNeedsDisplay:YES];
	}
	
	[loadingBar setDoubleValue:5 + 95.0 * percentage];
}

-(void)dataSourceLoadFinished
{
	[loadingWindow close];
	[loadingBar setDoubleValue:0];
}

-(BOOL)dataSourceCancelLoad
{
	return cancelLoad;
}

#pragma mark Table View Delegate Methods
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
	if(tableView == dataView)
	{
		return [data count] - 1;
	}
	else
	{
		return [headings count];
	}
	
}

- (id) tableView:(NSTableView*) tableView objectValueForTableColumn:(NSTableColumn*) tableColumn row:(NSInteger) rowIndex {
	if(tableView == dataView)
	{
		int column = [[tableColumn identifier] intValue];
		NSArray *row = [data objectAtIndex:(rowIndex + 1)];
		if([row count] > column)
			return [row objectAtIndex:column];
		else
			return @"";
	}
	else
	{
		NSString *columnName = [tableColumn identifier];
		if([columnName isEqualToString:@"variable"])
		{
			return [headings objectAtIndex:rowIndex];
		}
		else if([columnName isEqualToString:@"import"])
		{
			return [NSNumber numberWithBool:[variablesToImport containsObject:[headings objectAtIndex:rowIndex]]];
		}
		else if([columnName isEqualToString:@"display"])
		{
			return [NSNumber numberWithBool:[variablesToDisplay containsObject:[headings objectAtIndex:rowIndex]]];
		}
		else if([columnName isEqualToString:@"label"])
		{
			NSString *variable = [headings objectAtIndex:rowIndex];
			NSString *label = [labels objectForKey:variable];
			if(!label)
			{
				return variable;
			}
			else
			{
				return label;
			}
		}
		else if([columnName isEqualToString:@"type"])
		{
			NSString *variable = [headings objectAtIndex:rowIndex];
			
			if([dataSource lockedDataType:[headings objectAtIndex:rowIndex]])
			{
				return [dataSource defaultDataType:variable];
			}
            else if([existingVariables containsObject:[headings objectAtIndex:rowIndex]])
            {
                return [types objectForKey:variable];
            }
			
			id type = [types objectForKey:variable];
			if(!type)
			{
				type = [dataSource defaultDataType:variable];
			}
			if(!type)
			{
				if([[dataSource possibleDataTypes] containsObject:DataTypeGeographicLat]
				   && ([variable rangeOfString:@"latitude" options:NSCaseInsensitiveSearch].location != NSNotFound))
				{
					
					[types setObject:DataTypeGeographicLat forKey:variable];
					return [NSNumber numberWithInt:[possibleDataTypes indexOfObject:DataTypeGeographicLat]];
				}
				else if([[dataSource possibleDataTypes] containsObject:DataTypeGeographicLon]
									&& ([variable rangeOfString:@"longitude" options:NSCaseInsensitiveSearch].location != NSNotFound))
				{
					
					[types setObject:DataTypeGeographicLon forKey:variable];
					return [NSNumber numberWithInt:[possibleDataTypes indexOfObject:DataTypeGeographicLon]];
				}
				else
				{
					return [NSNumber numberWithInt:0];
				}

			}
			else
			{
				return [NSNumber numberWithInt:[possibleDataTypes indexOfObject:type]];
			}
		}
		else
		{
			return [NSNumber numberWithBool:NO];
		}
	}
}

- (void)tableView:(NSTableView*)tv setObjectValue:(id)val forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
    if([[aTableColumn identifier] isEqualToString:@"import"])
    {
        NSString *selectedvariable = [headings objectAtIndex:rowIndex];
        
		if([val boolValue])
		{
			[variablesToImport addObject:selectedvariable];
            [variablesToDelete removeObject:selectedvariable];
		}
		else
		{
            NSArray *linked = [dataSource.linkedVariables objectForKey:selectedvariable];
            if(!linked)
            {
                linked = [NSArray arrayWithObject:selectedvariable];
            }
                
            for(NSString *variable in linked)
            {
                [variablesToDelete addObject:variable];
                [variablesToImport removeObject:variable];
                if([variablesToDisplay containsObject:variable])
                    [variablesToDisplay removeObject:variable];
            }
			[tv reloadData];
		}
    }
	else if([[aTableColumn identifier] isEqualToString:@"display"])
    {
		if([val boolValue])
		{
			[variablesToDisplay addObject:[headings objectAtIndex:rowIndex]];
			if(![variablesToImport containsObject:[headings objectAtIndex:rowIndex]])
				[variablesToImport addObject:[headings objectAtIndex:rowIndex]];
			[tv reloadData];
		}
		else
		{
			[variablesToDisplay removeObject:[headings objectAtIndex:rowIndex]];
		}
    }
	else if([[aTableColumn identifier] isEqualToString:@"label"])
    {
		[labels setObject:val forKey:[headings objectAtIndex:rowIndex]];
    }
	else if([[aTableColumn identifier] isEqualToString:@"type"])
    {
		[types setObject:[[dataSource possibleDataTypes] objectAtIndex:[val intValue]] forKey:[headings objectAtIndex:rowIndex]];
    }
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([@"type" isEqualToString:[aTableColumn identifier]] && 
        ([dataSource lockedDataType:[headings objectAtIndex:rowIndex]] || 
         [existingVariables containsObject:[headings objectAtIndex:rowIndex]]))
	{
		if(!lockedTypeCell)
		{
			lockedTypeCell = [[NSTextFieldCell alloc] init];
			[lockedTypeCell setTextColor:[NSColor grayColor]];
		}
		return lockedTypeCell;
	}
	else
	{
		return [aTableColumn dataCell];
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if(tableView == dataView)
	{
		return NO;
	}
	else
	{
		if([@"variable" isEqualToString:[aTableColumn identifier]])
		{
			return NO;
		}
		else if ([@"type" isEqualToString:[aTableColumn identifier]] && 
                 ([dataSource lockedDataType:[headings objectAtIndex:rowIndex]] || 
                  [existingVariables containsObject:[headings objectAtIndex:rowIndex]]))
		{
			return NO;
		}
		else
		{
			return YES;
		}
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)rowIndex
{
	if(tableView == dataView)
		return NO;
	else
		return YES;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn
{
	if(tableView == dataView)
	{
		return ([dataSource timeColumn] != [tableView columnWithIdentifier:[aTableColumn identifier]]);
	}
	else {
		return NO;
	}

}

@end
