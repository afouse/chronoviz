//
//  EthnographerNotesView.m
//  ChronoViz
//
//  Created by Adam Fouse on 3/16/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "EthnographerNotesView.h"

#import "EthnographerDataSource.h"
#import "EthnographerTemplate.h"
#import "AnotoTrace.h"
#import "AnotoNotesData.h"
#import "TimeCodedPenPoint.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "Annotation.h"
#import "TiledPDFDelegate.h"
#import "NSStringFileManagement.h"
#import "NSColorCGColor.h"
#import "NSColorUniqueColors.h"
#import "DPMaskedSelectionView.h"
#import "DPConstants.h"
#import <QuartzCore/CoreAnimation.h>
#import <CoreFoundation/CoreFoundation.h>


NSString * const DPEthnographerTraceKey = @"trace";
NSString * const DPEthnographerTracePathKey = @"tracePath";
NSString * const DPAnotoSessionDataKey = @"sessionData";

int ethnographerPagesSort( id obj1, id obj2, void *context ) {
	
	NSString *page1 = [(CALayer*)obj1 valueForKey:@"pageNumber"];
	NSString *page2 = [(CALayer*)obj2 valueForKey:@"pageNumber"];
	
	return [page1 compare:page2 options:NSNumericSearch];
}

int ethnographerLayersSort( id obj1, id obj2, void *context ) {
	
	AnotoTrace *trace1 = [(CALayer*)obj1 valueForKey:DPEthnographerTraceKey];
	AnotoTrace *trace2 = [(CALayer*)obj2 valueForKey:DPEthnographerTraceKey];
	
	return QTTimeCompare([trace1 range].time, [trace2 range].time);
}

@interface EthnographerNotesView (Internal)

- (CALayer*)createPage:(NSString*)pageNumber;
//- (CGRect)createLayerForTrace:(AnotoTrace*)trace;
- (CGRect)updatePathForTraceLayer:(CALayer*)traceLayer;
- (void)updatePageTimes:(id)sender;
- (void)updateSelection:(id)sender;
- (void)updateTitle;
- (NSUInteger)rotationValueFromLevel:(NSUInteger)rotationLevel;
- (NSUInteger)rotationLevelFromValue:(NSUInteger)rotationValue;

@end

@implementation EthnographerNotesView

@synthesize showPen,title,scaleConversionFactor;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		pages = [[NSMutableDictionary alloc] init];
		pageOffsets = [[NSMutableDictionary alloc] init];
		pageScaleCorrections = [[NSMutableDictionary alloc] init];
		
		// True conversion of mm to points should be 2.8346. (1 mm * (.03937 in/mm) * (72 pt/in))
		// 2.81 seemed to compensate for some early alignment issues...
		scaleConversionFactor = 2.8346;
		scaleValue = 1.0;
		scaleFactor = scaleConversionFactor * scaleValue;
		
		currentTime = QTIndefiniteTime;
		
		currentPage = nil;
		pageOrder = nil;
		
		backgroundPDF = NULL;
		backgroundTemplate = nil;
		
		tail = NO;
		tailTime = 0;
		
		notesData = [[NSMutableArray alloc] init];
		sessionLayers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setLayer:[CALayer layer]];
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
	selectionMode = NO;
	selectedTraces = nil;
	
	CGFloat zDistance = 2000.0;
	CATransform3D sublayerTransform = CATransform3DIdentity;
	//sublayerTransform = CATransform3DTranslate(sublayerTransform, -[layer bounds].size.width/2, 0, 0);
	sublayerTransform.m34 = 1.0 / -zDistance;  
	//sublayerTransform = CATransform3DTranslate(sublayerTransform, [layer bounds].size.width/2, 0, 0);
	[self layer].sublayerTransform = sublayerTransform;
	
}

- (void) dealloc
{
	for(CALayer *layer in [self layer].sublayers)
	{
		[layer removeFromSuperlayer];
	}
	
    for(AnotoNotesData *data in notesData)
    {
        [data removeObserver:self forKeyPath:@"color"];
    }
    
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	CGPDFDocumentRelease(backgroundPDF);
	[backgroundTemplate release];
	[notesData release];
	[sessionLayers release];
	[clickLayer release];
	[pageOrder release];
	[pages release];
	[pageOffsets release];
	[pageScaleCorrections release];
	[selectedTraces release];
    
    self.title = nil;
    
	[super dealloc];
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)setFrameSize:(NSSize)newSize
{    
	[super setFrameSize:newSize];
	if(selectionView)
	{
		[selectionView setFrameSize:newSize];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"color"])
    {
        [self redrawAllTraces];
    }
}

- (CALayer*)createPage:(NSString*)pageNumber
{
	CALayer *page = nil;
    
    NSUInteger rotationValue = [(EthnographerDataSource*)[[notesData lastObject] source] rotationForPage:pageNumber];
    NSUInteger rotation = [self rotationLevelFromValue:rotationValue];
    
	if(!backgroundTemplate || ![backgroundTemplate.background fileExists] || ([[backgroundTemplate.background pathExtension] caseInsensitiveCompare:@"pdf"] != NSOrderedSame))
	{
		page = [CALayer layer];
		[page setAnchorPoint:CGPointMake(0,0)];
		[page setBounds:CGRectMake(0,0,100,100)];
		
		//[page setFrame:[self layer].frame];
		[page setValue:[NSNumber numberWithBool:NO] forKey:@"hasBackground"];
	}
	else
	{
		
		if(backgroundPDF == NULL)
		{
			NSURL *docURL = [NSURL fileURLWithPath:backgroundTemplate.background];
			backgroundPDF = CGPDFDocumentCreateWithURL((CFURLRef)docURL);
		}
        
		NSUInteger templatePage = [backgroundTemplate pdfPageForLivescribePage:pageNumber];
        
		CATiledLayer *tiledLayer = [CATiledLayer layer];
		TiledPDFDelegate *delegate = [[TiledPDFDelegate alloc] initWithDocument:backgroundPDF forPage:templatePage];
		tiledLayer.delegate = delegate;
		
		// get tiledLayer size
		CGRect pageRect = CGPDFPageGetBoxRect([delegate page], kCGPDFCropBox);
		int w = pageRect.size.width;
		int h = pageRect.size.height;
		
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
		
		tiledLayer.tileSize = CGSizeMake(256, 256);
		

		tiledLayer.bounds = CGRectMake(0.0f, 0.0f,
									   CGRectGetWidth(pageRect), 
									   CGRectGetHeight(pageRect));

		tiledLayer.anchorPoint = CGPointMake(0.0, 0.0);
		tiledLayer.position = CGPointZero;
		
		page = tiledLayer;
		
		[page setValue:[NSNumber numberWithBool:YES] forKey:@"hasBackground"];
		
		[tiledLayer setNeedsDisplay];
	}
	
	[page setBackgroundColor:CGColorCreateGenericGray(1.0, 1.0)];
	[page setHidden:YES];
	[page setValue:[NSNumber numberWithFloat:scaleFactor] forKey:@"scaleFactor"];
	[page setValue:pageNumber forKey:@"pageNumber"];
	[pages setObject:page forKey:pageNumber];
    
    if(rotation != 0)
    {
        [self setRotation:rotation forPage:pageNumber];
    }
     
	return page;
}

- (CGRect)updatePathForTraceLayer:(CALayer*)traceLayer
{
	AnotoTrace *trace = [traceLayer valueForKey:DPEthnographerTraceKey];
	
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
	
	[traceLayer setValue:(id)tracePath forKey:DPEthnographerTracePathKey];
	
	CGPathRelease(tracePath);
	
	return traceFrame;
}

- (void)updatePageTimes:(id)sender
{
	for(CALayer* page in [pages allValues])
	{
		NSArray *sessions = page.sublayers;
		
		NSTimeInterval minStartTime = DBL_MAX;
		NSTimeInterval maxEndTime = -DBL_MAX;
		for(CALayer *session in sessions)
		{
			AnotoNotesData *data = [session valueForKey:DPAnotoSessionDataKey];
			NSTimeInterval dataStartTime;
			QTGetTimeInterval([data range].time,&dataStartTime);
			
			NSArray *layers = [session.sublayers mutableCopy];
			[layers sortedArrayUsingFunction:ethnographerLayersSort context:NULL];
			AnotoTrace *startTrace = [[layers objectAtIndex:0] valueForKey:DPEthnographerTraceKey];
			AnotoTrace *endTrace = [[layers lastObject] valueForKey:DPEthnographerTraceKey];
			NSTimeInterval startTime;
			NSTimeInterval endTime;
			QTGetTimeInterval([startTrace range].time, &startTime);
			QTGetTimeInterval(QTTimeRangeEnd([endTrace range]), &endTime);
			startTime += dataStartTime;
			endTime += dataStartTime;
			minStartTime = fmin(minStartTime, startTime);
			maxEndTime = fmax(maxEndTime,endTime);
		}
		
		[page setValue:[NSNumber numberWithFloat:minStartTime] forKey:@"startTimeInterval"];
		[page setValue:[NSNumber numberWithFloat:maxEndTime] forKey:@"endTimeInterval"];
	}
}

- (void)updateTitle
{
    NSString *theTitle = nil;
    
    if([notesData count] == 1)
	{
        NSString *sourceName = [[(AnotoNotesData*)[notesData lastObject] source] name];
        NSString *sessionName = [(AnotoNotesData*)[notesData lastObject] name];
        theTitle = [NSString stringWithFormat:@"%@: %@",sourceName,sessionName];
		//theTitle = [[(AnotoNotesData*)[notesData lastObject] source] name];	
		
	}
	else
	{
        DataSource *source = [(AnotoNotesData*)[notesData lastObject] source];
        for(AnotoNotesData *data in notesData)
        {
            if([data source] != source)
            {
                theTitle = @"Multiple Note Sessions";
                break;
            }
        }
        
        if(!theTitle)
        {
            NSString *sourceName = [[(AnotoNotesData*)[notesData lastObject] source] name];
            theTitle = [NSString stringWithFormat:@"%@: Multiple Sessions",sourceName];
        }
	}
    
    if([pageOrder count] > 1)
    {
        CALayer *page = [pages objectForKey:currentPage];
        theTitle = [theTitle stringByAppendingFormat:@" (Page %i of %i)",([pageOrder indexOfObject:page] + 1),[pageOrder count]];
    }
    
    self.title = theTitle;
}

-(void)setData:(AnotoNotesData*)source
{
	[self addData:source];
}

-(void)addData:(TimeCodedData*)data
{
	if([notesData containsObject:data] || ![data isKindOfClass:[AnotoNotesData class]])
	{
		return;
	}
	
	EthnographerTemplate *dataTemplate = [(EthnographerDataSource*)[data source] backgroundTemplate];
	if(backgroundTemplate != nil)
	{
		if(dataTemplate != backgroundTemplate)
		{
			return;
		}
	}
	else 
	{
		backgroundTemplate = [dataTemplate retain];        
	}

	[notesData addObject:data];
	
    [self updateTitle];
	
	NSArray *traces = [(AnotoNotesData*)data traces];
	
	CGRect maxBounds = CGRectZero;
	for(CALayer* page in [pages allValues])
	{
		maxBounds = CGRectUnion(maxBounds,page.bounds);
	}
	
	for(NSString *pageNum in [(EthnographerDataSource*)[data source] pages])
	{
		CALayer *page = [pages objectForKey:pageNum];
		
		// Create the page if needed, including background
		if(page == nil)
		{
			page = [self createPage:pageNum];
			
			maxBounds = CGRectUnion(maxBounds,page.bounds);
		}
	}
	
	NSMutableArray *traceLayers = [NSMutableArray array];
	[sessionLayers setObject:traceLayers forKey:[data uuid]];
	
	// Create layers for new traces
	for(AnotoTrace *trace in traces)
	{
		CALayer *layer = [CALayer layer];
		[layer setHidden:YES];
		[layer setValue:trace forKey:DPEthnographerTraceKey];
		
		CGRect traceFrame = [self updatePathForTraceLayer:layer];
		
		[traceLayers addObject:layer];
		
		NSString *pageNum = [trace page];
		
		CALayer *page = [pages objectForKey:pageNum];
		
		// Create the page if needed, including background
		if(page == nil)
		{
			
			page = [self createPage:pageNum];
			
			maxBounds = CGRectUnion(maxBounds,page.bounds);
			
		}
		
		// Update the bounds, in case it extends past the background
		maxBounds = CGRectUnion(maxBounds,traceFrame);
		
		CALayer *sessionLayer = [page valueForKey:[data uuid]];
		if(!sessionLayer)
		{
			sessionLayer = [CALayer layer];
			sessionLayer.anchorPoint = CGPointMake(0, 0);
			sessionLayer.bounds = page.bounds;
			sessionLayer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
			[page addSublayer:sessionLayer];
			[sessionLayer setValue:data forKey:DPAnotoSessionDataKey];
			[page setValue:sessionLayer forKey:[data uuid]];
			[sessionLayer setNeedsDisplay];
		}
		[sessionLayer addSublayer:layer];
		[layer setNeedsDisplay];
		
	}
	
	// Calculate the time range of each page
	[self updatePageTimes:self];
	
	// Sort the pages by start time
//	[pageOrder release];
//	NSSortDescriptor *startTimeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startTimeInterval" ascending:YES];
//	pageOrder = [[pages allValues] mutableCopy];
//	[pageOrder sortUsingDescriptors:[NSArray arrayWithObject:startTimeDescriptor]];				 
//	[startTimeDescriptor release];
	
	// Sort the pages by pageNumber
	[pageOrder release];
	pageOrder = [[pages allValues] mutableCopy];
	[pageOrder sortUsingFunction:ethnographerPagesSort context:NULL];				 
	
	// Add the page layers
	CALayer *previous = nil;
	for(CALayer* page in pageOrder)
	{
		[page removeFromSuperlayer];
		
		if(![page isKindOfClass:[CATiledLayer class]])
		{
			[page setBounds:maxBounds];
		}
		
		if(previous)
			[[self layer] insertSublayer:page below:previous];
		else
			[[self layer] addSublayer:page];
		
		//NSLog(@"Page bounds: %f %f",page.bounds.size.width,page.bounds.size.height);
		
		//[page setNeedsDisplay];
		
		previous = page;
	}
	
	[clickLayer removeFromSuperlayer];
	[clickLayer setHidden:YES];
	[[self layer] addSublayer:clickLayer];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updatePageTimes:)
												 name:DPDataSetRangeChangeNotification
											   object:[data source]];
	
	if([notesData count] > 1)
	{
		[self showPage:currentPage];
	}
	else
	{
		[self update];	
	}
	
	if(currentPage == nil)
	{
		[self showPage:[[pageOrder objectAtIndex:0] valueForKey:@"pageNumber"]];
	}
    
    [data addObserver:self
           forKeyPath:@"color"
              options:0
              context:NULL];
	
}

-(void)removeData:(TimeCodedData*)source
{
	if([notesData containsObject:source])
	{
        [source removeObserver:self forKeyPath:@"color"];
        
		NSArray *traces = [sessionLayers objectForKey:[source uuid]];
		for(CALayer *layer in traces)
		{
			[layer removeFromSuperlayer];
		}
		
		for(CALayer *page in pageOrder)
		{
			CALayer *sessionLayer = [page valueForKey:[source uuid]];
			[sessionLayer removeFromSuperlayer];
			[page setValue:nil forKey:[source uuid]];
		}
		
		[sessionLayers removeObjectForKey:[source uuid]];
		[notesData removeObject:source];
		
	}
    
    if([notesData count] == 0)
    {
        [backgroundTemplate release];
        backgroundTemplate = nil;
        
        for(CALayer *page in [pages allValues])
        {
            [page removeFromSuperlayer];
        }
        [pages removeAllObjects];
    }
	
    [self updateTitle];
}

-(void)updateData:(AnotoNotesData*)source
{	
	if([notesData containsObject:source])
	{
		NSMutableArray *traceLayers = [sessionLayers objectForKey:[source uuid]];
		NSMutableArray *oldTraces = [NSMutableArray arrayWithCapacity:[traceLayers count]];
		for(CALayer *layer in traceLayers)
		{
			[oldTraces addObject:[layer valueForKey:DPEthnographerTraceKey]];
		}
		
		for(AnotoTrace *trace in [source traces])
		{
			if(![oldTraces containsObject:trace])
			{
				CALayer *layer = [CALayer layer];
				[layer setHidden:YES];
				[layer setValue:trace forKey:DPEthnographerTraceKey];
				
				[self updatePathForTraceLayer:layer];
				
				[traceLayers addObject:layer];
				
				NSString *pageNum = [trace page];
				
				CALayer *page = [pages objectForKey:pageNum];
				
				// Create the page if needed, including background
				if(page == nil)
				{
					

				}
				
				CALayer *sessionLayer = [page valueForKey:[source uuid]];
				if(!sessionLayer)
				{
					sessionLayer = [CALayer layer];
					sessionLayer.anchorPoint = CGPointMake(0, 0);
					sessionLayer.bounds = page.bounds;
					sessionLayer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
					[page addSublayer:sessionLayer];
					[sessionLayer setValue:source forKey:DPAnotoSessionDataKey];
					[page setValue:sessionLayer forKey:[source uuid]];
					[sessionLayer setNeedsDisplay];
				}
				[sessionLayer addSublayer:layer];
				[layer setNeedsDisplay];
				
				// Calculate the time range of each page
				[self updatePageTimes:self];
				[layer setHidden:NO];
				[layer setOpacity:1.0];
				
//				// Sort the pages by start time
//				[pageOrder release];
//				NSSortDescriptor *startTimeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startTimeInterval" ascending:YES];
//				pageOrder = [[pages allValues] mutableCopy];
//				[pageOrder sortUsingDescriptors:[NSArray arrayWithObject:startTimeDescriptor]];				 
//				[startTimeDescriptor release];
				
			}
		}
		//[self showPage:currentPage];
	}
}

-(void)redrawAllTraces
{
	CALayer *current = [pages objectForKey:currentPage];
	for(CALayer *session in current.sublayers)
	{
		for(CALayer *layer in session.sublayers)
		{
			[self updatePathForTraceLayer:layer];
			[layer setNeedsDisplay];
		}
	}
}

-(QTTime)timeForNotePoint:(NSPoint)point onPage:(NSString*)pageId
{	
	//NSLog(@"Time for note point: %f %f",point.x,point.y);
	if(![currentPage isEqualToString:pageId])
	{
		[self showPage:pageId];
	}
	
	CGPoint notepoint = CGPointMake(point.x * scaleFactor, point.y * scaleFactor);
	
	NSPoint viewpoint = NSPointFromCGPoint([[self layer] convertPoint:notepoint fromLayer:[pages objectForKey:currentPage]]);
	
	[self scrollRectToVisible:NSMakeRect(viewpoint.x, viewpoint.y, 10, 10)];
	
	return [self timeForViewPoint:viewpoint onPage:pageId];
	
	//return [self timeForViewPoint:NSMakePoint(point.x * scaleFactor, point.y * scaleFactor) onPage:pageId];
}

-(QTTime)timeForViewPoint:(NSPoint)point onPage:(NSString*)pageId
{
	//NSLog(@"Time for point: %f %f",point.x,point.y);
	CALayer *page = [pages objectForKey:pageId];
	
	if(page)
	{
		CALayer *result = [self traceLayerForViewPoint:point onPage:pageId];
		
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];
		
		[clickLayer setHidden:NO];
		[clickLayer setPosition:NSPointToCGPoint(point)];
		[clickLayer setNeedsDisplay];
		[CATransaction commit];
		[CATransaction flush];
		[CATransaction begin];
		[CATransaction setValue:[NSNumber numberWithFloat:2.0f]
						 forKey:kCATransactionAnimationDuration];
		
		[clickLayer setHidden:YES];
		
		[CATransaction commit];
		
		
		if(result)
		{
            AnotoTrace *trace = [result valueForKey:DPEthnographerTraceKey];
			CALayer *sessionLayer = [result superlayer];
			AnotoNotesData *data = [sessionLayer valueForKey:DPAnotoSessionDataKey];
			QTTime traceRangeEnd = QTTimeRangeEnd([trace range]);
			traceRangeEnd.timeValue = traceRangeEnd.timeValue + fmax(1,traceRangeEnd.timeScale/300);
			return QTTimeIncrement(traceRangeEnd,[data range].time);
		}
	}
	
	return QTIndefiniteTime;
}

-(CALayer*)traceLayerForViewPoint:(NSPoint)point onPage:(NSString*)pageId
{
    CALayer *page = [pages objectForKey:pageId];
    
    if(page)
    {
    
        CGPoint pagepoint = [page convertPoint:NSPointToCGPoint(point) fromLayer:[self layer]];
        
        //CGPoint pagepoint = NSPointToCGPoint(point);
        
        CALayer *result = nil;
        AnotoTrace *trace = nil;
        for(CALayer *session in page.sublayers)
        {
            
            //CALayer *result = [page hitTest:pagepoint];
            result = [session hitTest:pagepoint];
            
            trace = [result valueForKey:DPEthnographerTraceKey];
            
            // Test a range around the point so that the taps don't need to be perfect
            if(!trace)
            {
                int xoff,yoff;
                // Received taps seem to be offset slightly to the right
                for(xoff = -3; xoff < 0; xoff++)
                {
                    for(yoff = -1; yoff < 2; yoff++)
                    {
                        result = [session hitTest:CGPointMake(pagepoint.x + xoff,pagepoint.y + yoff)];
                        trace = [result valueForKey:DPEthnographerTraceKey];
                        if(trace) break;
                    }
                    if(trace) break;
                }
            }
            
            //NSLog(@"Trace box: %f %f %f %f",[trace minX],[trace minY],[trace maxX],[trace maxY]);
            
            if(trace) break;
        }
        
        if(!trace)
        {
            result = nil;
        }
        
        return result;
    }
    
    return nil;
    
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

- (IBAction)rotateCW:(id)sender
{	
	int rotationLevel = 0;
	CALayer *pageLayer = [pages objectForKey:currentPage];
	NSNumber *currentRotation = [pageLayer valueForKey:@"pageRotation"];
	if(currentRotation)
	{
		rotationLevel = [currentRotation intValue];
	}
	
	rotationLevel++;
	
	if(rotationLevel > 3)
	{
		rotationLevel = 0;
	}
	
    NSUInteger rotationValue = [self rotationValueFromLevel:rotationLevel];
    
    [(EthnographerDataSource*)[[notesData lastObject] source] setRotation:rotationValue forPage:currentPage];
    
	[self setRotation:rotationLevel];

}

- (IBAction)rotateCCW:(id)sender
{
	int rotationLevel = 0;
	CALayer *pageLayer = [pages objectForKey:currentPage];
    NSNumber *currentRotation = [pageLayer valueForKey:@"pageRotation"];
	if(currentRotation)
	{
		rotationLevel = [currentRotation intValue];
	}
	
	rotationLevel--;
	
	if(rotationLevel < 0)
	{
		rotationLevel = 3;
	}
	
    NSUInteger rotationValue = [self rotationValueFromLevel:rotationLevel];
    
    [(EthnographerDataSource*)[[notesData lastObject] source] setRotation:rotationValue forPage:currentPage];
    
	[self setRotation:rotationLevel];
    
}

-(void)setRotation:(int)rotationLevel
{
	[self setRotation:rotationLevel forPage:currentPage];
	CALayer *pageLayer = [pages objectForKey:currentPage];
	[self setFrameSize:NSSizeFromCGSize([pageLayer frame].size)];
}

-(void)setRotation:(int)rotationLevel forPage:(NSString*)pageNumber
{
	CALayer *pageLayer = [pages objectForKey:pageNumber];
	
	BOOL noswap = ((rotationLevel == 0) || (rotationLevel == 2));
	
	float rotation = (float)rotationLevel * M_PI_2;
	
	CGFloat diffx = pageLayer.bounds.size.width/2.0;
	CGFloat diffy = pageLayer.bounds.size.height/2.0;
	
	//NSLog(@"diffx %f diffy %f",diffx,diffy);
	
	CATransform3D move = CATransform3DMakeTranslation(-diffx, -diffy, 0);
	CATransform3D rotate = CATransform3DMakeRotation(rotation, 0, 0, 1);
	CATransform3D moveback = CATransform3DMakeTranslation(diffy, diffx, 0);
	if(noswap)
	{
		moveback = CATransform3DMakeTranslation(diffx, diffy, 0);
	}
	
    [CATransaction begin];
	[pageLayer setTransform:CATransform3DConcat(CATransform3DConcat(move, rotate), moveback)];
	[pageLayer setValue:[NSNumber numberWithInt:rotationLevel] forKey:@"pageRotation"];
	[CATransaction commit];
}

-(int)currentRotation
{
    CALayer *currentLayer = [pages objectForKey:currentPage];
    return [[currentLayer valueForKey:@"pageRotation"] intValue];
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
		//[page setTransform:CATransform3DIdentity];
		
		//NSLog(@"Zoom set bounds: %f %f",bounds.size.width,bounds.size.height);
		
		[page setBounds:bounds];
		NSNumber *rotation = [page valueForKey:@"pageRotation"];
		int rotationLevel = (rotation == nil) ? 0 : [rotation intValue];
		NSString *pageNumber = [page valueForKey:@"pageNumber"];
        
		if([currentPage isEqualToString:pageNumber])
		{
            [self setRotation:rotationLevel];
			for(CALayer *session in page.sublayers)
			{
				for(CALayer *trace in session.sublayers)
				{
					[self updatePathForTraceLayer:trace];
					[trace setNeedsDisplay];
				}
			}
			[page setValue:[NSNumber numberWithFloat:scaleFactor] forKey:@"scaleFactor"];
		}
        else
        {
            [self setRotation:rotationLevel forPage:pageNumber];
        }
		
	}
	[self showPage:currentPage];
	[CATransaction commit];
}

- (IBAction)toggleSelectionMode:(id)sender
{
	if(selectionView)
	{
		[selectionView removeFromSuperview];
		selectionView = nil;
	}
	else
	{	
		selectionView = [[DPMaskedSelectionView alloc] initWithFrame:[self frame]];
		//[selectionView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable | NSViewMinXMargin | NSViewMinYMargin)];
		[selectionView setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
		[[self superview] addSubview:selectionView];
		[selectionView release];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateSelection:)
													 name:DPMaskedSelectionChangedNotification
												   object:selectionView];
		
	}
}

- (NSArray*)selectedTraces
{
	return [[selectedTraces copy] autorelease];
}

- (void)updateSelection:(id)sender
{
	if(selectionView)
	{
		CALayer *page = [pages objectForKey:currentPage];
		CGRect selection = [page convertRect:[selectionView maskedRect] fromLayer:[selectionView layer]];
		
		if(!selectedTraces)
		{
			selectedTraces = [[NSMutableArray alloc] init];
		}
		else
		{
			[selectedTraces removeAllObjects];
		}
		
		CGColorRef selectedColor = CGColorCreateGenericRGB(1.0, 1.0, 0, 1.0);
		
		for(CALayer *session in page.sublayers)
		{
			for(CALayer *layer in session.sublayers)
			{
				if(CGRectIntersectsRect(selection, layer.frame))
				{
					[selectedTraces addObject:[layer valueForKey:DPEthnographerTraceKey]];
					if(tail)
					{
						layer.hidden = NO;	
						layer.opacity = 1.0;
					}
					else
					{
						layer.shadowColor = selectedColor;
						layer.shadowOpacity = 0.9;
						layer.shadowRadius = 1.0;
						layer.shadowOffset = CGSizeMake(0, 0);
					}
				}
				else
				{
					if(tail)
					{
						layer.hidden = YES;
					}
					layer.shadowOpacity = 0;
				}
			}
		}
		
		CGColorRelease(selectedColor);
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DPMaskedSelectionChangedNotification
															object:self];
	}
}

- (NSTimeInterval)tailTime
{
	return tailTime;
}

- (void)setTailTime:(NSTimeInterval)theTailTime
{
	BOOL change;
	if(theTailTime > .001)
	{
		tailTime = theTailTime;
		change = !tail;
		tail = YES;
		showPen = NO;
	}
	else
	{
		tailTime = 0;
		change = tail;
		tail = NO;
		showPen = YES;
	}
	
	if(change)
	{
		[self showPage:currentPage];
	}
	
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
	//NSLog(@"Show Page: %@",pageId);
	
	CALayer *newPage = [pages objectForKey:pageId];
	
	
	
	if(!newPage)
	{
		if(currentPage == nil)
		{
            newPage = [pageOrder objectAtIndex:0];
			//newPage = [[pages objectEnumerator] nextObject];
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
		[CATransaction begin];
		
		if(currentPage != [newPage valueForKey:@"pageNumber"])
		{
			currentPage = [newPage valueForKey:@"pageNumber"];
			
            [self updateTitle];
            
			//NSLog(@"Current page: %@",currentPage);
			
			BOOL hasBackground = [[newPage valueForKey:@"hasBackground"] boolValue];
			
			if(hasBackground)
			{
                CGSize framesize = [newPage bounds].size;

                int rotationLevel = [[newPage valueForKey:@"pageRotation"] intValue];
                if((rotationLevel == 1) || (rotationLevel == 3))
                {
                    CGFloat tempheight = framesize.height;
                    framesize.height = framesize.width;
                    framesize.width = tempheight;
                }
                
				[self setFrameSize:NSSizeFromCGSize(framesize)];

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
		}
		
        BOOL after = NO;
		//for(CALayer* page in [pages allValues])
        for(CALayer* page in pageOrder)
		{
			if(page != newPage)
			{
                                
                NSNumber *currentRotation = [page valueForKey:@"pageRotation"];
                NSInteger rotationLevel = 0;
                if(currentRotation)
                {
                    rotationLevel = [currentRotation intValue];
                }

                if(rotationLevel == 0)
                {
                    if([pageOrder indexOfObject:newPage] > [pageOrder indexOfObject:page])
                    {
                        [page setValue:[NSNumber numberWithFloat:-1.55] forKeyPath:@"transform.rotation.y"];
                    }
                    else
                    {
                        [page setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.rotation.y"];
                    }
                    [page setHidden:after];
                }
                else
                {
                    [page setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.rotation.y"];
                    [page setHidden:YES];
                }
                
                
				//if([currentPage compare:[page valueForKey:@"pageNumber"]] == NSOrderedDescending)
				//if([[newPage valueForKey:@"startTimeInterval"] floatValue] > [[page valueForKey:@"startTimeInterval"] floatValue])
                
                
//                if([pageOrder indexOfObject:newPage] > [pageOrder indexOfObject:page])
//				{
//					[page setValue:[NSNumber numberWithFloat:-1.55] forKeyPath:rotationKeyPath];
//				}
//				else
//				{
//					[page setValue:[NSNumber numberWithFloat:0] forKeyPath:rotationKeyPath];
//				}
				
				//[CATransaction begin]; // inner transaction
				//[CATransaction setValue:[NSNumber numberWithFloat:1.0f]
				//				 forKey:kCATransactionAnimationDuration];
				
				//[page setHidden:YES];
				
				//[page setOpacity:0.0];
				
				//[CATransaction commit];
                
                //[page setHidden:after];
			}
			else
			{
				[page setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.rotation.y"];
				[page setOpacity:1.0];
				[page setHidden:NO];
                after = YES;
			}
		}
		
		BOOL redrawAll = NO;
		if(fabsf([[newPage valueForKey:@"scaleFactor"] floatValue] - scaleFactor) > .001)
		{
			[newPage setValue:[NSNumber numberWithFloat:scaleFactor] forKey:@"scaleFactor"];
			redrawAll = YES;
		}
		
		
		//tail = YES;
		//tailTime = 1.0;
		NSTimeInterval timeDiff;
		
		for(CALayer *session in newPage.sublayers)
		{
			AnotoNotesData *data = [session valueForKey:DPAnotoSessionDataKey];
			
			for(CALayer *layer in session.sublayers)
			{
				
				if(redrawAll)
				{
					[self updatePathForTraceLayer:layer];
					[layer setNeedsDisplay];
				}
				
				AnotoTrace *trace = [layer valueForKey:DPEthnographerTraceKey];
				QTTime end = QTTimeIncrement(QTTimeRangeEnd([trace range]),[data range].time);
				
				
//				if([trace range].time.timeValue > 0)
//				{
//					NSLog(@"trace start %qi",[trace range].time.timeValue);
//					NSLog(@"trace end %qi",end.timeValue);
//				}
			
				
				if(QTTimeCompare(currentTime, end) != NSOrderedAscending)
				{
					
					
					if(tail)
					{
						QTGetTimeInterval(QTTimeDecrement(currentTime, end),&timeDiff);
						if(timeDiff > tailTime)
						{
							[layer setHidden:YES];
						}
						else
						{
							[layer setHidden:NO];
							[layer setOpacity:1.0];
						}
					}
					else if([layer isHidden] || (layer.opacity < 1.0))
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
					else if(tail)
					{
						[layer setHidden:YES];
					}
					else
					{
						[layer setHidden:NO];
						[layer setOpacity:0.3];
					}
				}
			}
		}
		
		[CATransaction commit];
		
	}
	
}

- (NSArray*)pages
{
	return [pages allKeys];
}

- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext
{
	AnotoTrace* trace = [theLayer valueForKey:DPEthnographerTraceKey];
	
//	if(selectionView && [selectedTraces containsObject:trace])
//	{
//		CGContextBeginPath(theContext);
//		//CGContextSaveGState(theContext);
//		//CGContextScaleCTM(theContext, scaleValue, scaleValue);
//		CGContextAddPath(theContext, (CGMutablePathRef)[theLayer valueForKey:DPEthnographerTracePathKey] );
//		CGContextSetStrokeColorWithColor(theContext, [[data color] cgColor]);
//		//CGContextSetRGBStrokeColor(theContext, 0.2f, 0.2f, 0.2f, 1.0f);		
//		CGContextSetLineWidth(theContext, scaleValue);
//		CGContextStrokePath(theContext);
//	}
	
	if(trace)
	{
		AnotoNotesData *data = [theLayer.superlayer valueForKey:DPAnotoSessionDataKey];
		QTTime startTime = [data range].time;
		
		QTTime end = QTTimeIncrement(QTTimeRangeEnd([trace range]),startTime);
		if((QTTimeCompare(currentTime,QTTimeIncrement([trace range].time,startTime)) == NSOrderedDescending)
		   && (QTTimeCompare(currentTime,end) == NSOrderedAscending))
		{
			CGContextBeginPath(theContext);
			CGContextAddPath(theContext, (CGMutablePathRef)[theLayer valueForKey:DPEthnographerTracePathKey] );
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
					if(showPen)
					{
						[clickLayer setHidden:NO];
						[clickLayer setPosition:[[self layer] convertPoint:CGPointMake(([point x] * scaleFactor) - minX, ([point y] * scaleFactor) - minY) fromLayer:theLayer]];
						[clickLayer setNeedsDisplay];	
					}
					
					break;
				}
				CGContextAddLineToPoint(theContext, ([point x] * scaleFactor) - minX, ([point y] * scaleFactor) - minY);
			}
			
			CGContextSetStrokeColorWithColor(theContext, [[data color] createCGColor]);
			//CGContextSetRGBStrokeColor(theContext, 0.2f, 0.2f, 0.2f, 1.0f);
			CGContextSetLineWidth(theContext, scaleValue);
			CGContextStrokePath(theContext);
			
			[theLayer setValue:[NSNumber numberWithBool:YES] forKey:@"needsFullRedraw"];
		}
		else
		{
			CGContextBeginPath(theContext);
			//CGContextSaveGState(theContext);
			//CGContextScaleCTM(theContext, scaleValue, scaleValue);
			CGContextAddPath(theContext, (CGMutablePathRef)[theLayer valueForKey:DPEthnographerTracePathKey] );
			CGContextSetStrokeColorWithColor(theContext, [[data color] createCGColor]);
			//CGContextSetRGBStrokeColor(theContext, 0.2f, 0.2f, 0.2f, 1.0f);		
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
	
	CALayer *traceLayer = [self traceLayerForViewPoint:pt onPage:currentPage];
    
    if(traceLayer)
    {
        AnotoTrace* trace = [traceLayer valueForKey:DPEthnographerTraceKey];
        QTTime clickedTime = [trace startTime];
        QTTime playheadTime = [[[AppController currentApp] movie] currentTime];
        QTTime diff = QTTimeDecrement(playheadTime, clickedTime);
        
        BOOL allSessions = NO;
        if(allSessions)
        {
            for(AnotoNotesData *data in notesData)
            {
                QTTimeRange dataRange = [data range];
                if(QTTimeCompare(dataRange.time,diff) != NSOrderedSame)
                {
                    dataRange.time = diff;
                    [[data source] setRange:dataRange];		
                }
            }
        }
        else
        {
            AnotoNotesData *data = [traceLayer.superlayer valueForKey:DPAnotoSessionDataKey];
            
            QTTimeRange dataRange = [data range];
            dataRange.time = diff;
            [[data source] setRange:dataRange];	
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
	//NSLog(@"Anoto key down");
	[[[AppController currentApp] window] sendEvent:theEvent];
}

- (NSUInteger)rotationValueFromLevel:(NSUInteger)rotationLevel
{
    NSUInteger rotationValue = 0;
    if(rotationLevel == DPRotation90)
    {
        rotationValue = 90;
    }
    else if(rotationLevel == DPRotation180)
    {
        rotationValue = 180;
    }
    else if(rotationLevel == DPRotation270)
    {
        rotationValue = 270;
    }
    return rotationValue;
}

- (NSUInteger)rotationLevelFromValue:(NSUInteger)rotationValue
{
    NSUInteger rotation = DPRotation0;
    if(rotationValue == 90)
    {
        rotation = DPRotation90;
    }
    else if (rotationValue == 180)
    {
        rotation = DPRotation180;
    }
    else if (rotationValue == 270)
    {
        rotation = DPRotation270;
    }
    return rotation;
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
	return [[notesData copy] autorelease];
}


-(void)update
{
	if(QTTimeCompare(currentTime, [[[AppController currentDoc] movie] currentTime]) != NSOrderedSame)
	{
        currentTime = [[[AppController currentDoc] movie] currentTime];
        
        if([notesData count] > 1)
        {
            [self showPage:currentPage];
        }
        else
        {
            NSTimeInterval currentTimeInterval;
            QTGetTimeInterval(currentTime, &currentTimeInterval);
            
            //[CATransaction begin];
            
            CALayer* thePage = nil;
            NSTimeInterval thePageDuration = 0;
            
            for(CALayer* page in [pages allValues])
            {
                if([page.sublayers count] > 0)
                {
                    NSTimeInterval startTime = [[page valueForKey:@"startTimeInterval"] floatValue];
                    NSTimeInterval endTime = [[page valueForKey:@"endTimeInterval"] floatValue];
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
                [self showPage:[thePage valueForKey:@"pageNumber"]];
            }
            else
            {
                [self showPage:currentPage];
            }
        }
		
		
	}
}

-(NSData*)currentState:(NSDictionary*)stateFlags
{	
	NSMutableArray *dataSetUUIDs = [NSMutableArray arrayWithCapacity:[notesData count]];
	for(AnotoNotesData *data in notesData)
	{
		[dataSetUUIDs addObject:[data uuid]];
	}
	
//	NSMutableDictionary *rotations = [NSMutableDictionary dictionary];
//	for(CALayer *page in pageOrder)
//	{
//		NSNumber *rotation = [page valueForKey:@"pageRotation"];
//		if(rotation)
//		{
//			[rotations setObject:rotation forKey:[page valueForKey:@"pageNumber"]];
//		}
//	}
	
	return [NSKeyedArchiver archivedDataWithRootObject:[NSDictionary dictionaryWithObjectsAndKeys:
														dataSetUUIDs,@"DataSetUUIDs",
														currentPage,@"CurrentPage",
														[NSNumber numberWithFloat:scaleValue],@"ScaleValue",
														//rotations,@"PageRotations",
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
	
	
	// This case supports the standard EthnographerNotesView state record
	NSArray* dataSetUUIDs = [stateDict objectForKey:@"DataSetUUIDs"];
	
	if(dataSetUUIDs)
	{
		for(NSObject* dataSet in [[AnnotationDocument currentDocument] dataSets])
		{
			if([dataSet isKindOfClass:[AnotoNotesData class]])
			{
				AnotoNotesData *notes = (AnotoNotesData*)dataSet;
				if([dataSetUUIDs containsObject:[notes uuid]])
				{
					//[(EthnographerDataSource*)[notes source] setCreateAnnotations:NO];
					[self addData:(AnotoNotesData*)dataSet];
				}
			}
		}
	}	
	
	NSDictionary *rotations = [stateDict objectForKey:@"PageRotations"];
	if(rotations)
	{
		for(NSString *pageNum in [rotations allKeys])
		{
			int rotationLevel = [[rotations objectForKey:pageNum] intValue];
            
            NSUInteger rotationValue = [self rotationValueFromLevel:rotationLevel];
            
            [(EthnographerDataSource*)[[notesData lastObject] source] setRotation:rotationValue forPage:currentPage];
            
			[self setRotation:rotationLevel forPage:pageNum];
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
		[CATransaction flush];
		[self setZoom:[zoomLevel floatValue]];
	}
	
	return YES;
}

@end

