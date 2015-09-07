//
//  TranscriptView.m
//  DataPrism
//
//  Created by Adam Fouse on 5/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TranscriptView.h"
#import "TranscriptData.h"
#import "TimeCodedSourcedString.h"
#import "DataSource.h"
#import "AppController.h"
#import "AnnotationDocument.h"

@interface TranscriptWebView : WebView

@end

@implementation TranscriptWebView

- (void)performFindPanelAction:(id)sender
{
	[[[self window] windowController] performFindPanelAction:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    if (([item action] == @selector(performFindPanelAction:))
        || ([item action] == @selector(makeTextLarger:))
        || ([item action] == @selector(makeTextSmaller:)))
	{
		return YES;
	}
	else
	{
		return NO; //[super validateMenuItem:item];
	}
}

- (BOOL) maintainsInactiveSelection
{
	return YES;
}


@end



@interface TranscriptView (TableConstruction)

- (NSString*)timeRowHTML:(QTTime)time;
- (NSString*)transcriptArrayToHTML:(NSArray*)array;

@end

@implementation TranscriptView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
//		NSRect tableFrame = frame;
//		tableFrame.origin.x = 0;
//		tableFrame.origin.y = 0;
//        tableView = [[NSTableView alloc] initWithFrame:tableFrame];
//		[tableView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
//		[tableView setHeaderView:nil];
//		[tableView setAllowsColumnResizing:NO];
//		[tableView setAllowsColumnReordering:NO];
//		[tableView setAllowsColumnSelection:NO];
//		[tableView setAllowsEmptySelection:YES];
//		
//		NSTableColumn *speakerColumn = [[NSTableColumn alloc] initWithIdentifier:@"Speaker"];
//		[speakerColumn setWidth:50];
//		[tableView addTableColumn:speakerColumn];
//		 
//		 
//		[self addSubview:tableView];
//		
		htmlPath = nil;
		scrollPosition = nil;
		currentTime = QTZeroTime;
		
		webView = [[TranscriptWebView alloc] initWithFrame:NSMakeRect(0,0,[self frame].size.width,[self frame].size.height) frameName:nil groupName:nil];
		[webView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
		[webView setFrameLoadDelegate:self];
		[webView setUIDelegate:self];
		[self addSubview:webView];
		
    }
    return self;
}

- (void) dealloc
{
	[data release];
	[html release];
	[htmlPath release];
	[super dealloc];
}


-(void)setData:(TranscriptData*)source
{
	[source retain];
	[data release];
	data = source;
	
	[self reloadData];
}

-(void)handleTimeClick:(NSTimeInterval)time
{
	currentTime = QTMakeTimeScaled(QTMakeTimeWithTimeInterval(time),[[AppController currentApp] currentTime].timeScale);
	
	[[AppController currentApp] moveToTime:currentTime fromSender:self];
}


-(IBAction)alignToPlayhead:(id)sender
{
	QTTime playheadTime = [[[AppController currentApp] movie] currentTime];
	QTTime lineTime = QTTimeDecrement(QTMakeTimeWithTimeInterval(clickedTime),[[data source] range].time);
	
	QTTime diff = QTTimeDecrement(playheadTime, lineTime);
	QTTimeRange dataRange = [data range];
	dataRange.time = diff;
	[[data source] setRange:dataRange];
	
	[self reloadData];
				
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
    if (selector == @selector(handleTimeClick:)) {
        return NO;
    }
    return YES;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)property {

    return YES;
}

- (NSString*)timeRowHTML:(QTTime)time
{
	NSTimeInterval timeInterval;
	QTGetTimeInterval(time, &timeInterval);
	
	int hours = timeInterval/(60 * 60);
	int minutes = (timeInterval - (hours * 60 * 60))/60;
	int seconds = floor((timeInterval - (hours * 60 * 60) - (minutes * 60)));
	int frames = roundf(((timeInterval - floor(timeInterval)) * [data frameRate]) + 1.0);
	
	return [NSString stringWithFormat:@"<tr><td><a name=\"%1.2f\" class=\"time\" href=\"transcript.html\" onclick=\"DoTimeClick(%f);return false;\">[%02i:%02i:%02i.%02i]</a></td></tr>",timeInterval,timeInterval,hours,minutes,seconds,frames];
}

- (NSString*)transcriptArrayToHTML:(NSArray*)array
{
	NSMutableString *result = [NSMutableString stringWithString:@"<table>"];
	
	int maxSegments = 1;
	int segmentsToMatch = 0;
	int matchedSegments = 0;
	
	for(NSArray* row in array)
	{
		maxSegments = fmax(maxSegments, [row count]);
	}
	
	int rowOffset[40];
	NSString *source = nil;
	int rowIndex = 0;
	for(NSArray* row in array)
	{
		rowOffset[rowIndex] = 0;
		[result appendString:@"<tr><td class=\"speaker\">"];
		
		if(![[[row objectAtIndex:0] source] isEqualToString:source])
		{
			[result appendFormat:@"%@:",[[row objectAtIndex:0] source]];
			source = [[row objectAtIndex:0] source];
		}
		
		[result appendString:@"</td>"];
		
		
		int segmentIndex = 0;
		for(TimeCodedSourcedString *segment in row)
		{
			BOOL matched = NO;
			int matchRow;
			int matchSegmentIndex;
			for(matchRow = 0; matchRow < rowIndex; matchRow++)
			{
				matchSegmentIndex = rowOffset[matchRow];
				for(TimeCodedSourcedString *matchSegment in [array objectAtIndex:matchRow])
				{
					if(QTTimeCompare([segment time],[matchSegment time]) == NSOrderedSame)
					{
						if(![[segment source] isEqualToString:[matchSegment source]])
						{
							matched = YES;
							break;
						}
					}
					matchSegmentIndex++;
				}
				if(matched)
				{
					break;
				}
			}
			
			if(matched)
			{
				int segmentNum = 0;
				while(segmentNum < matchSegmentIndex)
				{
					[result appendString:@"<td></td>"];
					segmentNum++;
				}
				rowOffset[rowIndex] = segmentNum;
				[result appendString:@"<td>["];
				matchedSegments++;
				if(matchedSegments == segmentsToMatch)
				{
					segmentsToMatch = 0;
					matchedSegments = 0;
				}
			}
			else if(([row count] == 1) && (segmentsToMatch == 0))
			{
				[result appendFormat:@"<td colspan=\"%i\">",maxSegments];
			}
			else if([row count] == maxSegments)
			{
				[result appendString:@"<td>"];
				if(segmentIndex == 0)
				{
					segmentsToMatch = maxSegments - 1;
				}
				else
				{
					[result appendString:@"["];
				}
				
			}
			else {
				[result appendString:@"<td>"];
				//[result appendString:@"["];
				
//				int segmentNum = 0;
//				while(segmentNum <= matchedSegments)
//				{
//					[result appendString:@"<td></td>"];
//					segmentNum++;
//				}
//				[result appendString:@"<td>["];
//				matchedSegments++;
//				if(matchedSegments == segmentsToMatch)
//				{
//					segmentsToMatch = 0;
//					matchedSegments = 0;
//				}
			}
			
			NSTimeInterval timeInterval;
			QTGetTimeInterval(QTTimeIncrement([segment time],[[data source] range].time), &timeInterval);
			[result appendFormat:@"<a name=\"%@\" title=\"%f\" class=\"speech\" href=\"transcript.html\" onclick=\"DoTimeClick(%f);return false;\">",
			 [NSString stringWithFormat:@"%@-%1.2f",[segment source],timeInterval],
			 timeInterval,
			 timeInterval];
			[result appendString:[[segment string] stringByReplacingOccurrencesOfString:@" " withString:@"&nbsp;"]];
			[result appendString:@"</a></td>"];
			segmentIndex++;
		}
		
		[result appendString:@"</tr>"];
		rowIndex++; 
	}
	
	[result appendString:@"</table>"];
	return result;
}

-(void)reloadData
{
	NSMutableString *table = [[NSMutableString alloc] initWithString:@"<table>"];
	
	NSMutableArray *alignment = [NSMutableArray array];
	
	QTTime lastRowTime;
	
	for(TimeCodedSourcedString *string in [data timeCodedStrings])
	{
		//NSLog(@"Transcript view string: %@",[string string]);
		if(![string interpolated] && (QTTimeCompare([string time], lastRowTime) != NSOrderedSame))
		{
			if([alignment count] > 0)
			{
				[table appendString:@"<tr><td>"];
				[table appendString:[self transcriptArrayToHTML:alignment]];
				[alignment removeAllObjects];
				[table appendString:@"</td></tr>"];
			}
			[table appendString:[self timeRowHTML:QTTimeIncrement([string time],[[data source] range].time)]];
			lastRowTime = [string time];
		}
		
		if([[string source] length] > 0)
		{
			NSArray *lines = [[string string] componentsSeparatedByString:@"\n"];
			if(([lines count] == 1)
			   && [[(TimeCodedSourcedString*)[[alignment lastObject] lastObject] source] isEqualToString:[string source]])
			{
				[[alignment lastObject] addObject:string];
			}
			else
			{
				for(NSString *line in lines)
				{
					TimeCodedSourcedString *segment = [[TimeCodedSourcedString alloc] init];
					segment.source = string.source;
					segment.time = string.time;
					segment.string = line;
					[alignment addObject:[NSMutableArray arrayWithObject:segment]];	
					[segment release];
				}
			}
		}
		
	}
	
	if([alignment count] > 0)
	{
		[table appendString:@"<tr><td>"];
		[table appendString:[self transcriptArrayToHTML:alignment]];
		[alignment removeAllObjects];
		[table appendString:@"</td></tr>"];
	}
	
	
	[table appendString:@"</table>"];

	NSBundle* myBundle = [NSBundle mainBundle];
	NSString* template = [myBundle pathForResource:@"transcript" ofType:@"html"];
	
	//NSLog(filename);
	NSError *error;
	[html release];
	html = nil;
	html = [[NSMutableString alloc] initWithContentsOfFile:template encoding:NSUTF8StringEncoding error:&error];
	
	if(!html)
	{
		NSLog(@"%@",[error localizedDescription]);
		return;
	}
	
	[html replaceOccurrencesOfString:@"<!-- Transcript -->" 
						  withString:table 
							 options:NSLiteralSearch 
							   range:NSMakeRange(0, [html length])];
	
	[html writeToFile:@"/transcripttest.html" atomically:YES encoding:NSUTF8StringEncoding error:&error];

	[[webView mainFrame] loadHTMLString:html baseURL:[NSURL URLWithString:@"http://www.google.com/"]];
	
	[table release];
	
}

-(NSString*)anchorForString:(TimeCodedSourcedString*)theString;
{
	NSTimeInterval timeInterval;
	QTGetTimeInterval(QTTimeIncrement([theString time],[[data source] range].time), &timeInterval);
	return [NSString stringWithFormat:@"%1.2f",timeInterval];
}

- (void)performFindPanelAction:(id)sender
{
	if([self window])
	{
		[[[self window] windowController] performFindPanelAction:self];
	}
}

- (IBAction)updateSearchTerm:(id)sender
{
	NSString *searchValue = [sender stringValue];
	[self searchForTerm:searchValue];
	[[self window] makeFirstResponder:sender];
	
}

- (void)searchForTerm:(NSString*)searchTerm
{
	[webView searchFor:searchTerm direction:YES caseSensitive:NO wrap:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
}

#pragma mark WebView Delegate Methods

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
    [windowObject setValue:self forKey:@"transcriptView"];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	if (scrollPosition) {
		NSScrollView *scrollView = [[[[webView mainFrame] frameView] documentView] enclosingScrollView];	
		[[scrollView documentView] scrollPoint:NSPointFromString(scrollPosition)];
		[scrollPosition release];
		scrollPosition = nil;
	}
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray*)defaultMenuItems
{
	//NSLog(@"WebElementLinkLabelKey %@",[element valueForKey:WebElementLinkLabelKey]);
	//NSLog(@"WebElementLinkTitleKey %@",[element valueForKey:WebElementLinkTitleKey]);
	
	NSString *title = [element valueForKey:WebElementLinkTitleKey];
	
	NSMenuItem *biggerItem = [[[NSMenuItem alloc] initWithTitle:@"Make Text Larger"
														 action:@selector(makeTextLarger:)
												 keyEquivalent:@""] autorelease];
	[biggerItem setTarget:sender];
	NSMenuItem *smallerItem = [[[NSMenuItem alloc] initWithTitle:@"Make Text Smaller"
														 action:@selector(makeTextSmaller:)
												  keyEquivalent:@""] autorelease];
	[smallerItem setTarget:sender];
	
	
	if(title)
	{
		clickedTime = [title floatValue];
		
		NSMenuItem *alignItem = [[[NSMenuItem alloc] initWithTitle:@"Align to Playhead"
															action:@selector(alignToPlayhead:)
													 keyEquivalent:@""] autorelease];
		return [NSArray arrayWithObjects:alignItem,[NSMenuItem separatorItem],biggerItem,smallerItem,nil];	
	}
	else
	{
		return [NSArray arrayWithObjects:biggerItem,smallerItem,nil];
	}
}

#pragma mark AnnotationView Methods

-(void)addAnnotation:(Annotation*)annotation
{
	//[annotations addObject:annotation];
	//[tableView reloadData];
}

-(void)addAnnotations:(NSArray*)array
{
	//[annotations addObjectsFromArray:array];
	//[tableView reloadData];
}

-(void)removeAnnotation:(Annotation*)annotation
{
	//[annotations removeObject:annotation];
	//[tableView reloadData];
}

-(void)updateAnnotation:(Annotation*)annotation
{
	//[tableView reloadData];
}

-(void)setAnnotationFilter:(AnnotationFilter*)filter
{
	//	annotationFilter = [filter retain];
	//	filterAnnotations = YES;
	//	[self redrawAllSegments];
}

-(AnnotationFilter*)annotationFilter
{
	return nil;
}

-(NSArray*)dataSets
{
	return [NSArray arrayWithObject:data];
}


-(void)update
{
	QTTime appTime = [[AppController currentApp] currentTime];
	
	if(QTTimeCompare(appTime,currentTime) != NSOrderedSame)
	{
		currentTime = appTime;
		
		TimeCodedSourcedString *previous = nil;
		for(TimeCodedSourcedString *string in [data timeCodedStrings])
		{
			if(![string interpolated])
			{
				if(QTTimeCompare(appTime, QTTimeIncrement([string time],[[data source] range].time)) != NSOrderedDescending)
				{
					[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.location.hash='#%@'",[self anchorForString:previous]]];
					return;
				}
				if([[string source] length] > 0)
				{
					previous = string;
				}
			}
		}
	}
}

-(NSData*)currentState:(NSDictionary*)stateFlags
{	
	NSString *dataSetName;
	if(data)
	{
		dataSetName = [data name];
	}
	else
	{
		dataSetName = @"";
	}
	
	NSString *currentScrollPosition = @"";
	NSScrollView *scrollView = [[[[webView mainFrame] frameView] documentView] enclosingScrollView];
	if(scrollView)
	{
		currentScrollPosition = NSStringFromPoint([[scrollView contentView] bounds].origin);
	}
	
	
	return [NSKeyedArchiver archivedDataWithRootObject:[NSDictionary dictionaryWithObjectsAndKeys:
														dataSetName,@"DataSetName",
														currentScrollPosition,@"CurrentScrollPosition",
														nil]];
}

-(BOOL)setState:(NSData*)stateData
{
	NSDictionary *stateDict;
	@try {
		stateDict = [NSKeyedUnarchiver unarchiveObjectWithData:stateData];
	}
	@catch (NSException *e) {
		NSLog(@"Invalid archive, %@", [e description]);
		return NO;
	}
	
	NSString* dataSetName = [stateDict objectForKey:@"DataSetName"];
	if([dataSetName length] > 0)
	{
		for(NSObject* dataSet in [[AnnotationDocument currentDocument] dataSets])
		{
			if([dataSet isKindOfClass:[TranscriptData class]] && [[(TranscriptData*)dataSet name] isEqualToString:dataSetName])
			{
				[self setData:(TranscriptData*)dataSet];
				break;
			}
		}
	}
	
	scrollPosition = [[stateDict objectForKey:@"CurrentScrollPosition"] retain];
	if([scrollPosition length] > 0) 
	{
		if(![webView isLoading])
		{
			NSScrollView *scrollView = [[[[webView mainFrame] frameView] documentView] enclosingScrollView];	
			[[scrollView documentView] scrollPoint:NSPointFromString(scrollPosition)];
			[scrollPosition release];
			scrollPosition = nil;
		}
	}
	else
	{
		[scrollPosition release];
		scrollPosition = nil;
	}
	

	
	return YES;
}

@end
