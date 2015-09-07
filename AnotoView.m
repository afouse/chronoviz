//
//  AnotoView.m
//  DataPrism
//
//  Created by Adam Fouse on 2/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AnotoView.h"
#import "AnotoDataSource.h"
#import "AnotoTrace.h"
#import "AnotoNotesData.h"
#import "TimeCodedPenPoint.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "Annotation.h"
#import "TiledPDFDelegate.h"
#import "NSStringFileManagement.h"
#import <QuartzCore/CoreAnimation.h>
#import <CoreFoundation/CoreFoundation.h>

NSString * const AFAnotoTraceKey = @"trace";
NSString * const AFAnotoTracePathKey = @"tracePath";
NSString * const AFAnotoOffsetKey = @"pageOffset";

@implementation AnotoView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        traceLayers = [[NSMutableArray alloc] init];
		pages = [[NSMutableDictionary alloc] init];
		pageOffsets = [[NSMutableDictionary alloc] init];
		pageScaleCorrections = [[NSMutableDictionary alloc] init];
		
		scaleConversionFactor = 2.81;
		scaleValue = 1.0;
		scaleFactor = scaleConversionFactor * scaleValue;
		
		currentTime = QTIndefiniteTime;
		
		currentPage = nil;
		pageOrder = nil;
    }
    return self;
}

- (void)awakeFromNib
{
	[self setWantsLayer:YES];
	[[self layer] setBackgroundColor:CGColorCreateGenericGray(1.0, 1.0)];
	[[self layer] setTransform:CATransform3DMakeScale(1.0f, -1.0f, 1.0f)];
	[[self layer] setFrame:NSRectToCGRect([self frame])];
	[[self layer] setNeedsDisplay];
	
	clickLayer = [[CALayer layer] retain];
	clickLayer.frame = CGRectMake(0, 0, 50, 50);
	clickLayer.cornerRadius = 25;
	clickLayer.backgroundColor = CGColorCreateGenericGray(0.5, 0.5);
	
	currentPage = nil;
	pageOrder = nil;
	
	CGFloat zDistance = 2000.0;
	CATransform3D sublayerTransform = CATransform3DIdentity;
	//sublayerTransform = CATransform3DTranslate(sublayerTransform, -[layer bounds].size.width/2, 0, 0);
	sublayerTransform.m34 = 1.0 / -zDistance;  
	//sublayerTransform = CATransform3DTranslate(sublayerTransform, [layer bounds].size.width/2, 0, 0);
	[self layer].sublayerTransform = sublayerTransform;
	
}

- (void) dealloc
{
	[clickLayer release];
	[pageOrder release];
	[pages release];
	[pageOffsets release];
	[pageScaleCorrections release];
	[traceLayers release];
	[data release];
	[super dealloc];
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
}

- (CGRect)updatePathForTraceLayer:(CALayer*)traceLayer
{
	AnotoTrace *trace = [traceLayer valueForKey:AFAnotoTraceKey];
	
	CGFloat offsetX = 0; //-55;
	CGFloat offsetY = 0; //-40;
	NSValue *offset = [pageOffsets valueForKey:[trace page]];
	if(offset)
	{
		offsetX = [offset pointValue].x * scaleFactor;
		offsetY = [offset pointValue].y * scaleFactor;
	}
	
	CGFloat minX = [trace minX] * scaleFactor;
	CGFloat minY = [trace minY] * scaleFactor;
	
	CGRect traceFrame = CGRectMake(minX + offsetX, 
								   minY + offsetY, 
								   ([trace maxX] - [trace minX]) * scaleFactor + 2, 
								   ([trace maxY] - [trace minY]) * scaleFactor + 2);
	minX--;
	minY--;
	
	[traceLayer setFrame:traceFrame];
	
	[traceLayer setDelegate:self];
	
	CGMutablePathRef tracePath = CGPathCreateMutable();
	
	TimeCodedPenPoint* start = [[trace dataPoints] objectAtIndex:0];
	CGPathMoveToPoint(tracePath, NULL, ([start x] * scaleFactor) - minX, ([start y] * scaleFactor) - minY);
	
	for(TimeCodedPenPoint* point in [trace dataPoints])
	{
		CGPathAddLineToPoint(tracePath, NULL, ([point x] * scaleFactor) - minX, ([point y] * scaleFactor) - minY);
	}
	
	[traceLayer setValue:(id)tracePath forKey:AFAnotoTracePathKey];
	
	CGPathRelease(tracePath);
	
	return traceFrame;
}

-(void)setData:(AnotoNotesData*)dataSource
{
	[data release];
	data = [dataSource retain];
	
	[[self window] setTitle:[[data source] name]];
	
	NSArray *traces = [data traces];
	
	NSDictionary *backgrounds = [(AnotoDataSource*)[dataSource source] backgrounds];
	[pageOffsets addEntriesFromDictionary:[(AnotoDataSource*)[dataSource source] backgroundOffsets]];
	[pageScaleCorrections addEntriesFromDictionary:[(AnotoDataSource*)[dataSource source] backgroundScaleCorrection]];
	
	
	CGRect maxBounds = CGRectZero;
	
	for(AnotoTrace *trace in traces)
	{
		CALayer *layer = [CALayer layer];
		[layer setHidden:YES];
		[layer setValue:trace forKey:AFAnotoTraceKey];
		
		CGRect traceFrame = [self updatePathForTraceLayer:layer];
		
		[traceLayers addObject:layer];
		
		NSString *pageNum = [trace page];
		
		CALayer *page = [pages objectForKey:pageNum];
		
		
		if(page == nil)
		{
			NSString* background = [backgrounds objectForKey:pageNum];
			
			if(!background || ![background fileExists] || ([[background pathExtension] caseInsensitiveCompare:@"pdf"] != NSOrderedSame))
			{
				page = [CALayer layer];
				[page setAnchorPoint:CGPointMake(0,0)];
				[page setBounds:CGRectMake(0,0,CGRectGetMaxX(traceFrame),CGRectGetMaxY(traceFrame))];
				
				//[page setFrame:[self layer].frame];
				[page setValue:[NSNumber numberWithBool:NO] forKey:@"hasBackground"];
			}
			else
			{
				
				CATiledLayer *tiledLayer = [CATiledLayer layer];
				TiledPDFDelegate *delegate = [[TiledPDFDelegate alloc] initWithFile:background];
				tiledLayer.delegate = delegate;
				
				// get tiledLayer size
				CGRect pageRect = CGPDFPageGetBoxRect([delegate page], kCGPDFCropBox);
				int w = pageRect.size.width;
				int h = pageRect.size.height;
				
				maxBounds = CGRectUnion(maxBounds,pageRect);
				
				// get level count
				int levels = 1;
				while (w > 1 && h > 1) {
					levels++;
					w = w >> 1;
					h = h >> 1;
				}
				
				// set the levels of detail
				tiledLayer.levelsOfDetail = levels;
				// set the bias for how many 'zoom in' levels there are
				tiledLayer.levelsOfDetailBias = 5;
				// setup the size and position of the tiled layer
				
				tiledLayer.bounds = CGRectMake(0.0f, 0.0f,
											   CGRectGetWidth(pageRect), 
											   CGRectGetHeight(pageRect));
				//CGFloat x = CGRectGetWidth(tiledLayer.bounds) * tiledLayer.anchorPoint.x;
				//CGFloat y = CGRectGetHeight(tiledLayer.bounds) * tiledLayer.anchorPoint.y;
				tiledLayer.anchorPoint = CGPointMake(0.0, 0.0);
				tiledLayer.position = CGPointZero;
				//tiledLayer.transform = CATransform3DMakeScale(zoom, zoom, 1.0f);
				//[tiledLayer setTransform:CATransform3DMakeScale(1.0f, -1.0f, 1.0f)];
				
				page = tiledLayer;
				
				[page setValue:[NSNumber numberWithBool:YES] forKey:@"hasBackground"];
				
				[tiledLayer setNeedsDisplay];
			}
			
			[page setBackgroundColor:CGColorCreateGenericGray(1.0, 1.0)];
			[page setHidden:YES];
			[page setValue:[NSNumber numberWithFloat:scaleFactor] forKey:@"scaleFactor"];
			[pages setObject:page forKey:pageNum];
			
		}
		
		maxBounds = CGRectUnion(maxBounds,traceFrame);
		[page addSublayer:layer];
		[layer setNeedsDisplay];
		
	}
	
	for(CALayer* page in [pages allValues])
	{
		NSArray *layers = page.sublayers;
		AnotoTrace *startTrace = [[layers objectAtIndex:0] valueForKey:AFAnotoTraceKey];
		AnotoTrace *endTrace = [[layers lastObject] valueForKey:AFAnotoTraceKey];
		NSTimeInterval startTime;
		NSTimeInterval endTime;
		QTGetTimeInterval([startTrace range].time, &startTime);
		QTGetTimeInterval(QTTimeRangeEnd([endTrace range]), &endTime);
		
		[page setValue:[NSNumber numberWithFloat:startTime] forKey:@"startTimeInterval"];
		[page setValue:[NSNumber numberWithFloat:endTime] forKey:@"endTimeInterval"];
		[page setValue:[startTrace page] forKey:@"pageNumber"];
		
		[page setBounds:maxBounds];
		[page setNeedsDisplay];
		//NSLog(@"%@,Start: %f, End: %f, Traces: %i",[startTrace name],startTime,endTime,[layers count]);
	}
	
	[pageOrder release];
	NSSortDescriptor *startTimeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startTimeInterval" ascending:YES];
	pageOrder = [[pages allValues] mutableCopy];
	[pageOrder sortUsingDescriptors:[NSArray arrayWithObject:startTimeDescriptor]];				 
	[startTimeDescriptor release];
	
	CALayer *previous = nil;
	for(CALayer* page in pageOrder)
	{
		if(previous)
			[[self layer] insertSublayer:page below:previous];
		else
			[[self layer] addSublayer:page];
		
		NSArray *layers = page.sublayers;
		AnotoTrace *startTrace = [[layers objectAtIndex:0] valueForKey:AFAnotoTraceKey];
		AnotoTrace *endTrace = [[layers lastObject] valueForKey:AFAnotoTraceKey];
		NSTimeInterval startTime;
		NSTimeInterval endTime;
		QTGetTimeInterval([startTrace range].time, &startTime);
		QTGetTimeInterval(QTTimeRangeEnd([endTrace range]), &endTime);
		
		NSLog(@"%@,Start: %f, End: %f, Traces: %i",[startTrace name],startTime,endTime,[layers count]);
		
		previous = page;
	}
	
	[clickLayer removeFromSuperlayer];
	[clickLayer setHidden:YES];
	[[self layer] addSublayer:clickLayer];
	
	[self update];
	
}

-(QTTime)timeForNotePoint:(NSPoint)point onPage:(NSString*)pageId
{	
	NSLog(@"Time for note point: %f %f",point.x,point.y);
	if(![currentPage isEqualToString:pageId])
	{
		[self showPage:pageId];
	}
	return [self timeForViewPoint:NSMakePoint(point.x * scaleFactor, point.y * scaleFactor) onPage:pageId];
}

-(QTTime)timeForViewPoint:(NSPoint)point onPage:(NSString*)pageId
{
	NSLog(@"Time for point: %f %f",point.x,point.y);
	CALayer *page = [pages objectForKey:pageId];
	
	if(page)
	{
		CGPoint pagepoint = [page convertPoint:NSPointToCGPoint(point) fromLayer:[self layer]];
		
		CALayer *result = [page hitTest:pagepoint];
		
		AnotoTrace* trace = [result valueForKey:AFAnotoTraceKey];
		
		// Test a range around the point so that the taps don't need to be perfect
		if(!trace)
		{
			int xoff,yoff;
			// Received taps seem to be offset slightly to the right
			for(xoff = -3; xoff < 0; xoff++)
			{
				for(yoff = -1; yoff < 2; yoff++)
				{
					result = [page hitTest:CGPointMake(pagepoint.x + xoff,pagepoint.y + yoff)];
					trace = [result valueForKey:AFAnotoTraceKey];
					if(trace) break;
				}
				if(trace) break;
			}
		}
		
		NSLog(@"Trace box: %f %f %f %f",[trace minX],[trace minY],[trace maxX],[trace maxY]);
		
		
		
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];
		
		[clickLayer setHidden:NO];
		[clickLayer setPosition:pagepoint];
		[clickLayer setNeedsDisplay];
		[CATransaction commit];
		[CATransaction flush];
		[CATransaction begin];
		[CATransaction setValue:[NSNumber numberWithFloat:2.0f]
						 forKey:kCATransactionAnimationDuration];
		
		[clickLayer setHidden:YES];
		
		[CATransaction commit];
		

		if(trace)
		{
			return QTTimeIncrement(QTTimeRangeEnd([trace range]),[data range].time);
		}
	}

	return QTIndefiniteTime;
}

- (IBAction)nextPage:(id)sender
{
	BOOL next = NO;
	for(CALayer *page in pageOrder)
	{
		if(next)
		{
			[self showPage:[page valueForKey:@"pageNumber"]];
			return;
		}
		else if([currentPage isEqualToString:[page valueForKey:@"pageNumber"]])
		{
			next = YES;
		}
	}
}

- (IBAction)previousPage:(id)sender
{
	CALayer *previous = nil;
	for(CALayer *page in pageOrder)
	{
		if(previous && [currentPage isEqualToString:[page valueForKey:@"pageNumber"]])
		{
			[self showPage:[previous valueForKey:@"pageNumber"]];
			return;
		}
		previous = page;
	}
}

- (IBAction)zoomIn:(id)sender
{
	[self setZoom:(scaleValue * 2.0)];
}

- (IBAction)zoomOut:(id)sender
{
	[self setZoom:(scaleValue * 0.5)];
}

- (void)setZoom:(CGFloat)zoomLevel
{
	float change = zoomLevel / scaleValue;
	scaleValue = zoomLevel;
	scaleFactor = scaleConversionFactor * scaleValue;
	[CATransaction begin];
	for(CALayer* page in pageOrder)
	{
		CGRect bounds = [page bounds];
		bounds.size.width = bounds.size.width *change;
		bounds.size.height = bounds.size.height * change;
		[page setBounds:bounds];
		//[page setTransform:CATransform3DMakeScale(scaleValue, scaleValue, 1.0f)];
		
		if([currentPage isEqualToString:[page valueForKey:@"pageNumber"]])
		{
			for(CALayer *trace in page.sublayers)
			{
				[self updatePathForTraceLayer:trace];
				[trace setNeedsDisplay];
			}
			[page setValue:[NSNumber numberWithFloat:scaleFactor] forKey:@"scaleFactor"];
		}
		
	}
	[self showPage:currentPage];
	[CATransaction commit];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	QTTime time = [self timeForViewPoint:pt onPage:currentPage];
	
	if(!QTTimeIsIndefinite(time))
		[[AppController currentApp] moveToTime:time fromSender:self];
}

-(void)showPage:(NSString*)pageId
{
	NSLog(@"Show Page: %@",pageId);
	
	CALayer *newPage = [pages objectForKey:pageId];
	
	
	if(!newPage)
	{
		if(currentPage == nil)
		{
			newPage = [[pages objectEnumerator] nextObject];
		}
		else
		{
			newPage = [pages objectForKey:currentPage];
		}			
		
		[newPage setHidden:NO];
		[newPage setOpacity:1.0];
	}
	
	
	if(newPage)
	{
		currentPage = [newPage valueForKey:@"pageNumber"];
		
		NSLog(@"Current page: %@",currentPage);
		
		BOOL hasBackground = [[newPage valueForKey:@"hasBackground"] boolValue];
		
		if(hasBackground)
		{
			[self setFrameSize:NSSizeFromCGSize([newPage bounds].size)];
		}
		else
		{
			NSRect windowSize = [[[self window] contentView] bounds];
			if(!CGRectContainsRect(NSRectToCGRect(windowSize),[newPage bounds]))
			{
				CGRect newBounds = CGRectUnion([self layer].bounds, [newPage bounds]);
				[self setFrameSize:NSSizeFromCGSize(newBounds.size)];
				//NSLog(@"New Frame Size: %f, %f, %f, %f",newBounds.origin.x,newBounds.origin.y,newBounds.size.width,newBounds.size.height);
				
			}
			else
			{
				windowSize.size.width = windowSize.size.width - 1;
				windowSize.size.height = windowSize.size.height - 1;
				[self setFrameSize:windowSize.size];			
			}
		}
		
		for(CALayer* page in [pages allValues])
		{
			if(page != newPage)
			{
				//if([currentPage compare:[page valueForKey:@"pageNumber"]] == NSOrderedDescending)
				if([[newPage valueForKey:@"startTimeInterval"] floatValue] > [[page valueForKey:@"startTimeInterval"] floatValue])
				{
					[page setValue:[NSNumber numberWithFloat:-1.55] forKeyPath:@"transform.rotation.y"];
				}
				else
				{
					[page setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.rotation.y"];
				}
				
				[CATransaction begin]; // inner transaction
				[CATransaction setValue:[NSNumber numberWithFloat:1.0f]
								 forKey:kCATransactionAnimationDuration];
				
				//[page setHidden:YES];
				
				//[page setOpacity:0.0];
				
				[CATransaction commit];
			}
			else
			{
				[page setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.rotation.y"];
				[page setOpacity:1.0];
				[page setHidden:NO];
			}
		}
		
		BOOL redrawAll = NO;
		if(fabsf([[newPage valueForKey:@"scaleFactor"] floatValue] - scaleFactor) > .001)
		{
			[newPage setValue:[NSNumber numberWithFloat:scaleFactor] forKey:@"scaleFactor"];
			redrawAll = YES;
		}
		
		for(CALayer *layer in newPage.sublayers)
		{
			if(redrawAll)
			{
				[self updatePathForTraceLayer:layer];
				[layer setNeedsDisplay];
			}
			
			AnotoTrace *trace = [layer valueForKey:AFAnotoTraceKey];
			QTTime end = QTTimeIncrement(QTTimeRangeEnd([trace range]),[data range].time);
			if(QTTimeCompare(currentTime, end) == NSOrderedDescending)
			{
				if([layer isHidden] || (layer.opacity < 1.0))
				{
					[layer setHidden:NO];
					[layer setOpacity:1.0];
				}
				if([[layer valueForKey:@"needsFullRedraw"] boolValue])
				{
					[layer setNeedsDisplay];
				}	
			}
			else
			{
				if(QTTimeCompare(currentTime,QTTimeIncrement([trace range].time,[data range].time)) == NSOrderedDescending)
				{
					[layer setHidden:NO];
					[layer setOpacity:1.0];
					[layer setNeedsDisplay];
				}
				else //if(![layer isHidden])
				{
					[layer setHidden:NO];
					[layer setOpacity:0.3];
				}
			}
		}
		
	}
	
}

- (NSArray*)pages
{
	return [pages allKeys];
}

- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext
{
	AnotoTrace* trace = [theLayer valueForKey:AFAnotoTraceKey];
	QTTime startTime = [data range].time;
	
	if(trace)
	{
		
		QTTime end = QTTimeIncrement(QTTimeRangeEnd([trace range]),startTime);
		if((QTTimeCompare(currentTime,QTTimeIncrement([trace range].time,startTime)) == NSOrderedDescending)
		   && (QTTimeCompare(currentTime,end) == NSOrderedAscending))
		{
			CGContextBeginPath(theContext);
			CGContextAddPath(theContext, (CGMutablePathRef)[theLayer valueForKey:AFAnotoTracePathKey] );
			CGContextSetRGBStrokeColor(theContext, 0.2f, 0.2f, 0.2f, 0.3f);
			CGContextSetLineWidth(theContext, scaleValue);
			CGContextStrokePath(theContext);
			
			CGFloat minX = [trace minX] * scaleFactor;
			CGFloat minY = [trace minY] * scaleFactor;
			
			minX--;
			minY--;
			
			CGContextBeginPath(theContext);
			TimeCodedPenPoint* start = [[trace dataPoints] objectAtIndex:0];
			CGContextMoveToPoint(theContext, ([start x] * scaleFactor) - minX, ([start y] * scaleFactor) - minY);
			
			for(TimeCodedPenPoint* point in [trace dataPoints])
			{
				if(QTTimeCompare(currentTime,QTTimeIncrement([point time],startTime)) == NSOrderedAscending)
				{
					CALayer *pageLayer = [pages objectForKey:[trace page]];
					[clickLayer setHidden:NO];
					[clickLayer setPosition:[pageLayer convertPoint:CGPointMake(([point x] * scaleFactor) - minX, ([point y] * scaleFactor) - minY) fromLayer:theLayer]];
					[clickLayer setNeedsDisplay];
					
					break;
				}
				CGContextAddLineToPoint(theContext, ([point x] * scaleFactor) - minX, ([point y] * scaleFactor) - minY);
			}
			
			CGContextSetRGBStrokeColor(theContext, 0.2f, 0.2f, 0.2f, 1.0f);
			CGContextSetLineWidth(theContext, scaleValue);
			CGContextStrokePath(theContext);
			
			[theLayer setValue:[NSNumber numberWithBool:YES] forKey:@"needsFullRedraw"];
		}
		else
		{
			CGContextBeginPath(theContext);
			//CGContextSaveGState(theContext);
			//CGContextScaleCTM(theContext, scaleValue, scaleValue);
			CGContextAddPath(theContext, (CGMutablePathRef)[theLayer valueForKey:AFAnotoTracePathKey] );
			CGContextSetRGBStrokeColor(theContext, 0.2f, 0.2f, 0.2f, 1.0f);		
			CGContextSetLineWidth(theContext, scaleValue);
			CGContextStrokePath(theContext);
			//CGContextRestoreGState(theContext);
			[theLayer setValue:[NSNumber numberWithBool:NO] forKey:@"needsFullRedraw"];
		}
	}
}

-(IBAction)alignToPlayhead:(id)sender
{
	NSEvent *event = [sender representedObject];
	
	NSPoint pt = [self convertPoint:[event locationInWindow] fromView:nil];
	
	for(CALayer* page in [pages allValues])
	{
		if(![page isHidden] && [page.sublayers count] > 0)
		{
			CALayer *result = [page hitTest:[page convertPoint:NSPointToCGPoint(pt) fromLayer:[self layer]]];
			
			AnotoTrace* trace = [result valueForKey:AFAnotoTraceKey];
			if(trace)
			{			
				QTTime clickedTime = [trace startTime];
				QTTime playheadTime = [[[AppController currentApp] movie] currentTime];
				
				QTTime diff = QTTimeDecrement(playheadTime, clickedTime);
				QTTimeRange dataRange = [data range];
				dataRange.time = diff;
				[[data source] setRange:dataRange];
				
			}
		}
	}
}

+ (NSMenu *)defaultMenu {
    NSMenu *theMenu = [[[NSMenu alloc] initWithTitle:@"Contextual Menu"] autorelease];
	[theMenu setAutoenablesItems:NO];

    return theMenu;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenu *theMenu = [[self class] defaultMenu];
	
	NSMenuItem* item = [theMenu addItemWithTitle:@"Align To Playhead" action:@selector(alignToPlayhead:) keyEquivalent:@""];
	[item setRepresentedObject:theEvent];
	
	return theMenu;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

-(void)keyDown:(NSEvent *)theEvent
{
	NSLog(@"Anoto key down");
	[[[AppController currentApp] window] sendEvent:theEvent];
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
	if(QTTimeCompare(currentTime, [[[AppController currentDoc] movie] currentTime]) != NSOrderedSame)
	{
		currentTime = [[[AppController currentDoc] movie] currentTime];
		NSTimeInterval currentTimeInterval;
		QTGetTimeInterval(currentTime, &currentTimeInterval);
		
		NSTimeInterval startTimeInterval;
		QTGetTimeInterval([data range].time,&startTimeInterval);
		
		[CATransaction begin];
		
		CALayer* thePage = nil;
		NSTimeInterval thePageDuration = 0;
		
		for(CALayer* page in [pages allValues])
		{
			if([page.sublayers count] > 0)
			{
//				AnotoTrace *startTrace = [[page.sublayers objectAtIndex:0] valueForKey:AFAnotoTraceKey];
//				QTTime start = [startTrace range].time;
//				AnotoTrace *endTrace = [[page.sublayers lastObject] valueForKey:AFAnotoTraceKey];
//				QTTime end = QTTimeRangeEnd([endTrace range]);
//				if((QTTimeCompare(currentTime, start) == NSOrderedDescending) && (QTTimeCompare(currentTime, end) == NSOrderedAscending))
				NSTimeInterval startTime = [[page valueForKey:@"startTimeInterval"] floatValue] + startTimeInterval;
				NSTimeInterval endTime = [[page valueForKey:@"endTimeInterval"] floatValue] + startTimeInterval;
				if((startTime <= currentTimeInterval) && (currentTimeInterval < endTime))
				{
					if(!thePage || (thePage && ((endTime - startTime) < thePageDuration)))
					{
						thePage = page;
						thePageDuration = endTime - startTime;
					}
				}
			}
		}

		if(thePage)
		{
			if(currentPage != [thePage valueForKey:@"pageNumber"])
			{
				currentPage = [thePage valueForKey:@"pageNumber"];
				NSLog(@"Switch page: %@",currentPage);
				//[page setOpacity:1.0];
				//[page setHidden:NO];
				NSRect windowSize = [[[self window] contentView] bounds];
				
				//NSLog(@"Window contentView: %f, %f, %f, %f",windowSize.origin.x,windowSize.origin.y,windowSize.size.width,windowSize.size.height);
				
				if(!CGRectContainsRect(NSRectToCGRect(windowSize),[thePage bounds]))
				{
					CGRect newBounds = CGRectUnion([self layer].bounds, [thePage bounds]);
					[self setFrameSize:NSSizeFromCGSize(newBounds.size)];
					//NSLog(@"New Frame Size: %f, %f, %f, %f",newBounds.origin.x,newBounds.origin.y,newBounds.size.width,newBounds.size.height);
					
				}
				else
				{
					windowSize.size.width = windowSize.size.width - 1;
					windowSize.size.height = windowSize.size.height - 1;
					[self setFrameSize:windowSize.size];
					//NSLog(@"New Frame Size 2: %f, %f, %f, %f",windowSize.origin.x,windowSize.origin.y,windowSize.size.width,windowSize.size.height);
					
				}
			}
		}
		else
		{
			if(currentPage == nil)
			{
				thePage = [[pages objectEnumerator] nextObject];
			}
			else
			{
				thePage = [pages objectForKey:currentPage];
			}			

			[thePage setHidden:NO];
			[thePage setOpacity:1.0];
			//currentPage = 0;
		}
		
		for(CALayer* page in [pages allValues])
		{
			if(page != thePage)
			{
				
				if([currentPage compare:[page valueForKey:@"pageNumber"]] == NSOrderedDescending)
				{
					[page setValue:[NSNumber numberWithFloat:-1.55] forKeyPath:@"transform.rotation.y"];
				}
				else
				{
					[page setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.rotation.y"];
				}
				
				[CATransaction begin]; // inner transaction
				[CATransaction setValue:[NSNumber numberWithFloat:1.0f]
								 forKey:kCATransactionAnimationDuration];
				
				//[page setHidden:YES];
				
				[page setOpacity:0.0];
				
				[CATransaction commit];
			}
			else
			{
				[page setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.rotation.y"];
				[thePage setOpacity:1.0];
				[thePage setHidden:NO];
			}
		}
		
		for(CALayer *layer in thePage.sublayers)
		{
			AnotoTrace *trace = [layer valueForKey:AFAnotoTraceKey];
			QTTime end = QTTimeIncrement(QTTimeRangeEnd([trace range]),[data range].time);
			if(QTTimeCompare(currentTime, end) == NSOrderedDescending)
			{
				if([layer isHidden] || (layer.opacity < 1.0))
				{
					[layer setHidden:NO];
					[layer setOpacity:1.0];
				}
				if([[layer valueForKey:@"needsFullRedraw"] boolValue])
				{
					[layer setNeedsDisplay];
				}	
			}
			else
			{
				if(QTTimeCompare(currentTime,QTTimeIncrement([trace range].time,[data range].time)) == NSOrderedDescending)
				{
					[layer setHidden:NO];
					[layer setOpacity:1.0];
					[layer setNeedsDisplay];
				}
				else //if(![layer isHidden])
				{
					[layer setHidden:NO];
					[layer setOpacity:0.3];
				}
			}
		}
		//[[self layer] setNeedsDisplay];
		
		[CATransaction commit];
		
	}
}

-(NSData*)currentState:(NSDictionary*)stateFlags
{
	NSString *dataSetName = [data name];
	NSString *dataSetSourceName = [[data source] name];
	
	return [NSKeyedArchiver archivedDataWithRootObject:[NSDictionary dictionaryWithObjectsAndKeys:
														dataSetName,@"DataSetName",
														dataSetSourceName,@"DataSetSourceName",
														currentPage,@"CurrentPage",
														[NSNumber numberWithFloat:scaleValue],@"ScaleValue",
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
	NSString* dataSetSourceName = [stateDict objectForKey:@"DataSetSourceName"];
	
	if([dataSetName length] > 0)
	{
		for(NSObject* dataSet in [[AnnotationDocument currentDocument] dataSets])
		{
			if([dataSet isKindOfClass:[AnotoNotesData class]] && [[(AnotoNotesData*)dataSet name] isEqualToString:dataSetName])
			{
				NSLog(@"Anoto source name: %@",[[(AnotoNotesData*)dataSet source] name]);
				NSLog(@"Expected source name: %@",dataSetSourceName);
				
				if([[[(AnotoNotesData*)dataSet source] name] isEqualToString:dataSetSourceName])
				{
					[(AnotoDataSource*)[(AnotoNotesData*)dataSet source] setCreateAnnotations:NO];
					[self setData:(AnotoNotesData*)dataSet];
					break;
				}
			}
		}
	}
	
	NSString *page = [stateDict objectForKey:@"CurrentPage"];
	if(page)
	{
		[self showPage:page];
	}
	
	NSNumber *zoomLevel = [stateDict objectForKey:@"ScaleValue"];
	if(zoomLevel)
	{
		[self setZoom:[zoomLevel floatValue]];
	}
	
	return YES;
}

@end
