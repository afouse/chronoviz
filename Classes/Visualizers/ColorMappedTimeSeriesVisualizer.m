//
//  ColorMappedTimeSeriesVisualizer.m
//  ChronoViz
//
//  Created by Adam Fouse on 7/20/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "ColorMappedTimeSeriesVisualizer.h"
#import "DPConstants.h"
#import "TimeSeriesData.h"
#import "TimeCodedDataPoint.h"
#import "DataSource.h"
#import "ColorMappedTimeSeriesConfigurationController.h"

@interface ColorMappedTimeSeriesVisualizer (Internal)

- (NSColor*)colorForValue:(CGFloat)value ofDataID:(NSString*)dataID;
- (void)updateImageForIndex:(NSUInteger)index;
- (CGImageRef)colorMapImageForSubset:(NSArray*)subset;
- (CGContextRef) createBitmapContext:(CGSize)size;

- (double)intervalModeForSubset:(NSArray*)subset withID:(NSString*)subsetID;

- (void)subset:(NSArray*)baseArray bySamplingInto:(NSMutableArray*)dataSubset;
- (void)subset:(NSArray*)baseArray byAveragingInto:(NSMutableArray*)dataSubset;
- (void)subset:(NSArray*)baseArray byMaxingInto:(NSMutableArray*)dataSubset;

@end

@implementation ColorMappedTimeSeriesVisualizer

-(id)initWithTimelineView:(TimelineView*)timelineView
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{
        
		NSArray *dataSets = [timeline dataSets];
		
        if([dataSets count])
        {            
            DataSource *dataSource = [(TimeSeriesData*)[[timeline dataSets] objectAtIndex:0] source];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reloadData)
                                                         name:DataSourceUpdatedNotification
                                                       object:dataSource];
		}
        loadedDataSets = [[NSMutableArray alloc] initWithCapacity:[dataSets count]];
		subsets = [[NSMutableArray alloc] initWithCapacity:[dataSets count]];
		subsetRanges = [[NSMutableArray alloc] initWithCapacity:[dataSets count]];
		graphLayers = [[NSMutableArray alloc] initWithCapacity:[dataSets count]];
		labelLayers = [[NSMutableArray alloc] initWithCapacity:[dataSets count]];
        subsetIntervalModes = [[NSMutableDictionary alloc] init];
		
		colorMaps = [[NSMutableDictionary alloc] init];
		
		NSGradient *colorMap = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:
													   [NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:0.5],
													   [NSColor colorWithDeviceRed:0 green:0.5 blue:0.5 alpha:0.8],
													   [NSColor colorWithDeviceRed:1.0 green:0 blue:0 alpha:1],
													   nil]];
		
		[self setUniformColorMap:colorMap];
		
		subsetResolutionRatio = 1.0;
		
		graphHeightMax = 30.0;
		graphHeightMin = 4.0;
		graphSpace = 15.0;
		
		graphHeight = graphHeightMax;
		
		configurationController = nil;
        
        subsetMethod = DPSubsetMethodMax;
		
	}
	return self;
}

- (void) dealloc
{
	for(CALayer* layer in graphLayers)
	{
		[layer removeFromSuperlayer];
	}

	for(CALayer* layer in labelLayers)
	{
		[layer removeFromSuperlayer];
	}
	
    for(TimeSeriesData *data in loadedDataSets)
    {
        [data removeObserver:self forKeyPath:@"name"];
    }
    
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[configurationController release];
    [loadedDataSets release];
	[subsets release];
	[subsetRanges release];
	[graphLayers release];
	[labelLayers release];
	[colorMaps release];
	[super dealloc];
}

-(void)reset
{
	createdGraph = NO;
	[super reset];
}

-(void)setup
{
	if(!createdGraph && ([[timeline dataSets] count] > 0))
	{
		[self createGraph];
		[timeline setLabel:@""];
	}
}

- (void)reloadData
{
	[subsets removeAllObjects];
	[self createGraph];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"name"])
    {
        for(CATextLayer *layer in labelLayers)
        {
            if([(NSString*)[layer valueForKey:@"DataSetID"] isEqualToString:[(TimeCodedData*)object uuid]])
            {
                [layer setString:[(TimeCodedData*)object name]];
            }
        }
	}
}

- (void)setSubsetMethod:(DPSubsetMethod)method
{
    subsetMethod = method;
}

- (NSDictionary*)colorMaps
{
	return colorMaps;
}

- (void)setColorMap:(NSGradient*)gradient forDataID:(NSString*)dataID
{	
	int index = 0;
	for(TimeSeriesData *data in [timeline dataSets])
	{
		if([[data uuid] isEqualToString:dataID])
		{
			[colorMaps setObject:gradient forKey:dataID];
			[self updateImageForIndex:index];
			return;
		}
		index++;
	}
	
}

- (void)setUniformColorMap:(NSGradient*)gradient
{
	[colorMaps setObject:gradient forKey:@"*"];
	
	int index;
	for(index = 0; index < [subsets count]; index++)
	{
		[self updateImageForIndex:index];
	}
	
}

- (CGImageRef)colorMapImageForSubset:(NSArray*)subset
{
	NSTimeInterval pointTime;
	NSTimeInterval rangeTime;
	NSTimeInterval rangeDuration;
	
    TimeSeriesData *data = [[timeline dataSets] objectAtIndex:[subsets indexOfObject:subset]];
	NSString *dataSetID = [data uuid];
	
	rangeTime = CMTimeGetSeconds([timeline range].time);
	rangeDuration = CMTimeGetSeconds([timeline range].duration);
	CGFloat graphWidth = [timeline bounds].size.width;
	float movieTimeToPixel = graphWidth/rangeDuration;
	
    CGContextRef bitmapContext = [self createBitmapContext:CGSizeMake(graphWidth, graphHeight)];

	//CGContextSetRGBFillColor (bitmapContext, 1, 1, 1, 0);
	//CGContextFillRect (bitmapContext, CGRectMake (0, 0, graphWidth, graphHeight ));
	
    NSTimeInterval maxTimeGap = [self intervalModeForSubset:subset withID:dataSetID] * 5.0;
    NSTimeInterval lastTime = rangeTime;
    
	CGFloat red;
	CGFloat green;
	CGFloat blue;
	CGFloat alpha;
	CGFloat previous = 0;
	CGFloat x;
	for(TimeCodedDataPoint *dataPoint in subset)
	{
		NSColor* color = [self colorForValue:[dataPoint value] ofDataID:dataSetID];
		
		[color getRed:&red
				green:&green
				 blue:&blue
				alpha:&alpha];
		
		pointTime = CMTimeGetSeconds([dataPoint time]);
		

		x = floor((pointTime - rangeTime) * movieTimeToPixel);
        
        if(((x - previous) > 1.1) && ((pointTime - lastTime) > maxTimeGap))
        {
            CGContextSetRGBFillColor(bitmapContext, 0, 0, 0, 0);
            
            CGFloat tempX = floor(((pointTime - maxTimeGap) - rangeTime) * movieTimeToPixel);
            CGContextFillRect (bitmapContext, CGRectMake (previous, 0, tempX - previous, graphHeight ));
            
            CGContextSetRGBFillColor (bitmapContext, red, green, blue, alpha);
            CGContextFillRect (bitmapContext, CGRectMake (tempX, 0, x - tempX, graphHeight ));
        }
        else
        {
            CGContextSetRGBFillColor (bitmapContext, red, green, blue, alpha);
            CGContextFillRect (bitmapContext, CGRectMake (previous, 0, x - previous, graphHeight ));
        }
        
		lastTime = pointTime;
		previous = x;
	}
	
	
    CGImageRef myImage = CGBitmapContextCreateImage (bitmapContext);
	
	char *bitmapData = CGBitmapContextGetData(bitmapContext); 
	CGContextRelease (bitmapContext);
	if (bitmapData) free(bitmapData);
	
	return myImage;
	
}

- (CGContextRef) createBitmapContext:(CGSize)size
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
	
    bitmapBytesPerRow   = (size.width * 4);// 1
    bitmapByteCount     = (bitmapBytesPerRow * size.height);
	
    colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);// 2
    bitmapData = malloc( bitmapByteCount );// 3
    if (bitmapData == NULL)
    {
        fprintf (stderr, "Memory not allocated!");
        return NULL;
    }
	
	memset(bitmapData,0,bitmapByteCount);
	
    context = CGBitmapContextCreate (bitmapData,// 4
									 size.width,
									 size.height,
									 8,      // bits per component
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGImageAlphaPremultipliedLast);
    if (context== NULL)
    {
        free (bitmapData);// 5
        fprintf (stderr, "Context not created!");
        return NULL;
    }
    CGColorSpaceRelease( colorSpace );// 6
	
    return context;// 7
}

- (NSColor*)colorForValue:(CGFloat)value ofDataID:(NSString*)dataID
{
	NSGradient *colorMap = nil;
	if([colorMaps count] == 1)
	{
		colorMap = [[colorMaps allValues] lastObject];
	}
	else
	{
		colorMap = [colorMaps objectForKey:dataID];
		if(!colorMap)
		{
			colorMap = [colorMaps objectForKey:@"*"];
		}
	}
	
	CGFloat location = (value - valueMin)/(valueMax - valueMin);
	return [[colorMap interpolatedColorAtLocation:location] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
}

-(void)createGraph
{	
	//NSTimeInterval movieTime;
	//NSTimeInterval pointTime;
	NSTimeInterval rangeTime;
	NSTimeInterval rangeDuration;
	
	CGFloat graphWidth = [timeline bounds].size.width;
	
	graphHeight = fmin(graphHeight,([timeline bounds].size.height/[[timeline dataSets] count]) - graphSpace);
	
	if([subsets count] != [[timeline dataSets] count])
	{
        for(TimeSeriesData *data in loadedDataSets)
        {
            [data removeObserver:self forKeyPath:@"name"];
        }
        [loadedDataSets removeAllObjects];
		[subsets removeAllObjects];
		[subsetRanges removeAllObjects];
        [subsetIntervalModes removeAllObjects];
		for(CALayer *graphLayer in graphLayers)
		{
			[graphLayer removeFromSuperlayer];
		}
        for(CALayer *labelLayer in labelLayers)
		{
			[labelLayer removeFromSuperlayer];
		}
		[graphLayers removeAllObjects];
		[labelLayers removeAllObjects];
		
		[[timeline visualizationLayer] setMasksToBounds:YES];
		for(TimeSeriesData *obj in [timeline dataSets])
		{
            [loadedDataSets addObject:obj];
            [obj addObserver:self forKeyPath:@"name" options:0 context:NULL];
			[subsets addObject:[NSMutableArray arrayWithCapacity:graphWidth]];
			[subsetRanges addObject:[NSValue valueWithQTTimeRange:[timeline range]]];
			
			CALayer *graphLayer = [CALayer layer];
			[graphLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
			CGRect graphFrame = NSRectToCGRect([timeline bounds]);
			graphFrame.size.height = graphHeight;
			[graphLayer setFrame:graphFrame];
			[graphLayer setShadowOpacity:0.5];
			[[timeline visualizationLayer] addSublayer:graphLayer];
			
			[graphLayers addObject:graphLayer];
			
			CATextLayer *labelLayer = [CATextLayer layer];
			labelLayer = [[CATextLayer layer] retain];
			labelLayer.font = @"Helvetica Bold";
			labelLayer.fontSize = 12.0;
			labelLayer.alignmentMode = kCAAlignmentLeft;
			//labelLayer.autoresizingMask = (kCALayerMaxYMargin | kCALayerMinXMargin);
			labelLayer.bounds = CGRectMake(0.0, 0.0, [timeline bounds].size.width - 2.0, graphSpace);
			labelLayer.anchorPoint = CGPointMake(0.0, 0.0);
			labelLayer.position = CGPointMake(0.0,0.0);
			CGColorRef darkgrey = CGColorCreateGenericGray(0.1, 1.0);
			labelLayer.foregroundColor = darkgrey;
			CGColorRelease(darkgrey);
			labelLayer.opacity = 1.0;
			labelLayer.string = [obj name];
            [labelLayer setValue:[obj uuid] forKey:@"DataSetID"];
			[[timeline visualizationLayer] addSublayer:labelLayer];
			[labelLayers addObject:labelLayer];
			
		}
	}
	
	valueMax = -CGFLOAT_MAX;
	valueMin = CGFLOAT_MAX;
	
	CGRect vizBounds = [timeline visualizationLayer].bounds;
	
	// Calculate the data range and calibrate subsets
	int index = 0;
	for(TimeSeriesData *data in [timeline dataSets])
	{	
		valueMin = fmin([data minValue],valueMin);
		valueMax = fmax([data maxValue],valueMax);
		
		rangeTime = CMTimeGetSeconds([timeline range].time);
		rangeDuration = CMTimeGetSeconds([timeline range].duration);
		
		NSMutableArray *dataSubset = [subsets objectAtIndex:index];
		CMTimeRange dataSubsetRange = [[subsetRanges objectAtIndex:index] QTTimeRangeValue];
		
		
		// Check to see if there are too few or too many points represented
		if(!dataSubset
           || ([dataSubset count] == 0)
		   || ([dataSubset count] > graphWidth/(subsetResolutionRatio - 0.1)) 
		   || (([dataSubset count] < graphWidth/(subsetResolutionRatio + 0.5)) && ([[data dataPoints] count] > graphWidth/(subsetResolutionRatio + 1)))
		   || (!QTEqualTimeRanges([timeline range], dataSubsetRange) && ![timeline resizing]) )
		{
			[dataSubset removeAllObjects];
			
            if(subsetMethod == DPSubsetMethodMax)
            {
			[self subset:[data dataPoints] byMaxingInto:dataSubset];
			}
            else if(subsetMethod == DPSubsetMethodAverage)
            {
                [self subset:[data dataPoints] byAveragingInto:dataSubset];
			}
            else
            {
                [self subset:[data dataPoints] bySamplingInto:dataSubset];
			}
                
			[subsetRanges replaceObjectAtIndex:index withObject:[NSValue valueWithQTTimeRange:[timeline range]]];			
			[subsetIntervalModes removeObjectForKey:[data uuid]];
            
			CALayer *graphLayer = [graphLayers objectAtIndex:index];
			CGImageRef graph = [self colorMapImageForSubset:dataSubset];
			graphLayer.contents = (id)graph;
			CGImageRelease(graph);
			
			CGFloat verticalOffset = (vizBounds.size.height - (([subsets count] * (graphHeight + graphSpace))) - graphSpace)/2.0;
			verticalOffset = fmax(0,verticalOffset);
			
			CGRect graphBounds = vizBounds;
			CGPoint graphPosition = CGPointMake(0,graphBounds.size.height - ((index + 1) * (graphHeight + graphSpace)) - verticalOffset);
			graphBounds.size.height = graphHeight;
			graphLayer.bounds = graphBounds;
			graphLayer.position = graphPosition;
			
			CALayer *labelLayer = [labelLayers objectAtIndex:index];
			
			CGRect labelBounds = vizBounds;
			CGPoint labelPosition = CGPointMake(5,graphPosition.y + graphHeight);
			labelBounds.size.height = 10.0;
			labelLayer.bounds = labelBounds;
			labelLayer.position = labelPosition;
			
		}
		
		index++;
	}

	
	createdGraph = YES;
}

- (void)updateImageForIndex:(NSUInteger)index
{
	CALayer *graphLayer = [graphLayers objectAtIndex:index];
	CGImageRef graph = [self colorMapImageForSubset:[subsets objectAtIndex:index]];
	graphLayer.contents = (id)graph;
	CGImageRelease(graph);
}

- (void)subset:(NSArray*)baseArray bySamplingInto:(NSMutableArray*)dataSubset
{
	NSTimeInterval movieTime;
	NSTimeInterval pointTime;
	NSTimeInterval rangeTime;
	NSTimeInterval rangeDuration;
	rangeTime = CMTimeGetSeconds([timeline range].time);
	rangeDuration = CMTimeGetSeconds([timeline range].duration);
	
	CGFloat graphWidth = [timeline bounds].size.width;
	
	float pixelToMovieTime = rangeDuration/graphWidth;
	float pixel = 0;
	movieTime = rangeTime + pixel*pixelToMovieTime;
	
	for(TimeCodedDataPoint *point in baseArray)
	{
		
		pointTime = CMTimeGetSeconds([point time]);
		if(pointTime >= movieTime)
		{
			
			[dataSubset addObject:point];
			
			pixel += subsetResolutionRatio;
			movieTime = rangeTime + pixel*pixelToMovieTime;
			if(pixel > graphWidth)
			{
				break;
			}
		}
	}
}

- (void)subset:(NSArray*)baseArray byAveragingInto:(NSMutableArray*)dataSubset
{
	NSTimeInterval movieTime;
	NSTimeInterval pointTime;
	NSTimeInterval rangeTime;
	NSTimeInterval rangeDuration;
	rangeTime = CMTimeGetSeconds([timeline range].time);
	rangeDuration = CMTimeGetSeconds([timeline range].duration);
	
	CGFloat graphWidth = [timeline bounds].size.width;
	
	float pixelToMovieTime = rangeDuration/graphWidth;
	float pixel = 0;
	movieTime = rangeTime + pixel*pixelToMovieTime;
	
	CGFloat sum = 0;
	int num = 0;
	
	for(TimeCodedDataPoint *point in baseArray)
	{
		sum += [point value];
		num++;
		
		pointTime = CMTimeGetSeconds([point time]);
		if(pointTime >= movieTime)
		{
			
			TimeCodedDataPoint *newPoint = [[TimeCodedDataPoint alloc] init];
			newPoint.time = [point time];
			newPoint.value = (sum/(CGFloat)num);
			
			[dataSubset addObject:newPoint];
			
			[newPoint release];
			sum = 0;
			num = 0;
			
			pixel += subsetResolutionRatio;
			movieTime = rangeTime + pixel*pixelToMovieTime;
			if(pixel > graphWidth)
			{
				break;
			}
		}
	}
}

- (void)subset:(NSArray*)baseArray byMaxingInto:(NSMutableArray*)dataSubset
{
	NSTimeInterval movieTime;
	NSTimeInterval pointTime;
	NSTimeInterval rangeTime;
	NSTimeInterval rangeDuration;
	rangeTime = CMTimeGetSeconds([timeline range].time);
	rangeDuration = CMTimeGetSeconds([timeline range].duration);
	
	CGFloat graphWidth = [timeline bounds].size.width;
	
	float pixelToMovieTime = rangeDuration/graphWidth;
	float pixel = 0;
	movieTime = rangeTime + pixel*pixelToMovieTime;
	
	TimeCodedDataPoint *min = [[TimeCodedDataPoint alloc] init];
	min.value = -DBL_MAX;
	
	TimeCodedDataPoint *max = min;
	
	for(TimeCodedDataPoint *point in baseArray)
	{
        pointTime = CMTimeGetSeconds([point time]);
        
        // Wait until we're close to the actual range
        if(pointTime < (rangeTime - (rangeDuration/20.0)))
        {
            continue;
        }
        
		if([point value] > [max value])
		{
			max = point;
		}
		
		
		if(pointTime >= movieTime)
		{
			[dataSubset addObject:max];
			
			max = min;
			
			pixel += subsetResolutionRatio;
			movieTime = rangeTime + pixel*pixelToMovieTime;
			if(pixel > graphWidth)
			{
				break;
			}
		}
	}
}

-(BOOL)updateMarkers
{
	if([timeline inLiveResize]) // && QTEqualTimeRanges([timeline range], [[subsetRanges objectAtIndex:0] QTTimeRangeValue]))
	{
		graphHeight = fmin(graphHeightMax,([timeline bounds].size.height/[[timeline dataSets] count]) - graphSpace);
		graphHeight = fmax(graphHeightMin,graphHeight);
		CGRect vizBounds = [timeline visualizationLayer].bounds;
		
		CGFloat verticalOffset = (vizBounds.size.height - (([subsets count] * (graphHeight + graphSpace))) - graphSpace)/2.0;
		verticalOffset = fmax(0,verticalOffset);
		
		int index = 0;
		for(CALayer *graphLayer in graphLayers)
		{
			CMTimeRange imageRange = [[subsetRanges objectAtIndex:index] QTTimeRangeValue];
			NSTimeInterval imageStart;
			NSTimeInterval imageDuration;
			imageDuration = CMTimeGetSeconds(imageRange.duration);
			imageStart = CMTimeGetSeconds(imageRange.time);
			
			CMTimeRange range = [timeline range];
			NSTimeInterval rangeDuration;
			NSTimeInterval rangeStart;
			rangeDuration = CMTimeGetSeconds(range.duration);
			rangeStart = CMTimeGetSeconds(range.time);
			
			float scale = imageDuration/rangeDuration;
			float movieTimeToPixel = [timeline bounds].size.width/rangeDuration;
			
			CGRect graphBounds = vizBounds;
			CGPoint graphPosition = CGPointMake((imageStart - rangeStart)*movieTimeToPixel
												,graphBounds.size.height - ((index + 1) * (graphHeight + graphSpace)) - verticalOffset);
			graphBounds.size.height = graphHeight;
			graphBounds.size.width = vizBounds.size.width * scale;
			graphLayer.bounds = graphBounds;
			graphLayer.position = graphPosition;
			
			CALayer *labelLayer = [labelLayers objectAtIndex:index];
			
			CGRect labelBounds = vizBounds;
			CGPoint labelPosition = CGPointMake(5,graphPosition.y + graphHeight);
			labelBounds.size.height = 10.0;
			labelLayer.bounds = labelBounds;
			labelLayer.position = labelPosition;
			
			index++;
		}
	
		return YES;
	}
	else
	{
		return NO;
	}
	
	//return NO;
}

- (void)configureVisualization:(id)sender
{
	ColorMappedTimeSeriesConfigurationController * controller = [[ColorMappedTimeSeriesConfigurationController alloc] initForVisualizer:self];
	[controller showWindow:self];
	[[controller window] makeKeyAndOrderFront:self];
	configurationController = controller;
}

- (double)intervalModeForSubset:(NSArray*)subset withID:(NSString*)subsetID
{
    NSNumber *intervalMode = [subsetIntervalModes objectForKey:subsetID];
    if(!intervalMode)
    {
        NSMutableDictionary* intervalFrequencyDict = [[NSMutableDictionary alloc] init];
        
        NSNumber *interval = nil;
        NSTimeInterval pointTimeDiff;
        CMTime lastTime = [(TimeCodedDataPoint*)[subset objectAtIndex:0] time];
        
        for(TimeCodedDataPoint* point in subset)
        {
            // Calculate the frequencies of point intervals
            pointTimeDiff = CMTimeGetSeconds(CMTimeSubtract([point time], lastTime));
            interval = [NSNumber numberWithLong:lround(pointTimeDiff * 100)];
            id num = [intervalFrequencyDict objectForKey:interval];
            if(num)
            {
                [intervalFrequencyDict setObject:[NSNumber numberWithInt:[num intValue]+1] forKey:interval];
            }
            else
            {
                [intervalFrequencyDict setObject:[NSNumber numberWithInt:1] forKey:interval];
            }
            lastTime = [point time];
        }
        
        // Find the mode of point intervals
        // This allows us to know recording frame rate while allowing for gaps in data
        int freq = 0;
        double intervalModeVal = 0;
        for(NSNumber *testInterval in [intervalFrequencyDict allKeys])
        {
            NSNumber *frequency = [intervalFrequencyDict objectForKey:testInterval];
            if([frequency intValue] > freq)
            {
                freq = [frequency intValue];
                intervalModeVal = [testInterval doubleValue]/100.0;
            }
        }
        
        //NSLog(@"Interval frequencies: %@",[intervalFrequencyDict description]);
        
        [intervalFrequencyDict release];
        
        intervalMode = [NSNumber numberWithDouble:intervalModeVal];
        
        [subsetIntervalModes setObject:intervalMode forKey:subsetID];
    }
    return [intervalMode doubleValue];
}

@end
