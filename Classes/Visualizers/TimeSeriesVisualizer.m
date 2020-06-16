//
//  TimeSeriesVisualizer.m
//  Annotation
//
//  Created by Adam Fouse on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TimeSeriesVisualizer.h"
#import "TimeCodedDataPoint.h"
#import "TimeSeriesData.h"
#import "DataSource.h"
#import "NSStringTimeCodes.h"

@implementation TimeSeriesVisualizer

-(id)initWithTimelineView:(TimelineView*)timelineView
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{
		if([[timeline dataSets] count] > 0)
		{
			DataSource *dataSource = [(TimeSeriesData*)[[timeline dataSets] objectAtIndex:0] source];
			
			[timeline setLabel:[[[timeline dataSets] objectAtIndex:0] name]];
			
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(reloadData)
														 name:DataSourceUpdatedNotification
													   object:dataSource];	
		}
		
		createdGraph = NO;
		graphLayer = nil;
		linesLayer = nil;
		graph = nil;
		lines = nil;
		subset = nil;
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[graphLayer removeFromSuperlayer];
	[linesLayer removeFromSuperlayer];
	[graphLayer release];
	[linesLayer release];
	[graph release];
	[lines release];
	[subset release];
	[super dealloc];
}

- (CALayer*)graphLayer
{
	return graphLayer;
}

- (CALayer*)linesLayer
{
	return linesLayer;
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
	}
}

- (void)reloadData
{
	[subset release];
	subset = nil;
	[self createGraph];
}

-(TimelineMarker *)addKeyframe:(SegmentBoundary*)keyframe
{
	[self setup];
	return nil;
}

-(void)createLines
{
//	TimeSeriesData *data = [timeline data];
//	float dataRange = [data maxValue] - [data minValue];
//	float valueToPixel = [timeline bounds].size.height/dataRange;
	
	float dataRange = subsetMax - subsetMin;
	float valueToPixel = [timeline bounds].size.height/dataRange;
	
	[lines release];
	lines = [[NSBezierPath alloc] init];
	
	int minLines = [timeline bounds].size.height/20.0;
	float maxScale = dataRange/minLines;
	float multiple = pow(10,floor(log10(dataRange) + 0.5) - 1);
	while(multiple > maxScale)
	{
		multiple = multiple/2;
	}
	float diff = fmod(maxScale,multiple);
	lineScale = maxScale - diff;
	numLines = ceil(dataRange/lineScale);
	
	if(numLines == 0)
	{
		NSLog(@"Numline is 0");
	}
	
	if(subsetMin * subsetMax < 0)
	{
		firstLine = 0;
		while(((firstLine - subsetMin) * valueToPixel) > 0)
		{
			firstLine -= lineScale;
		}
		firstLine += lineScale;
	}
	else
	{
		firstLine = subsetMin  + (lineScale - fmod(subsetMin,lineScale));
	}
	
	
	int i;
	float lineValue = firstLine;
	for(i = 0; i < numLines; i++)
	{
		//		[lines moveToPoint:NSMakePoint(0, offset + i*lineHeight)];
		//		[lines lineToPoint:NSMakePoint([timeline bounds].size.width, offset + i*lineHeight)];
		[lines moveToPoint:NSMakePoint(0, (lineValue - subsetMin) * valueToPixel)];
		[lines lineToPoint:NSMakePoint([timeline bounds].size.width, (lineValue - subsetMin) * valueToPixel)];
		lineValue += lineScale;
	}
	
	[linesLayer removeFromSuperlayer];
	[linesLayer release];
	linesLayer = [[CALayer layer] retain];
	[linesLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
	[linesLayer setFrame:NSRectToCGRect([timeline bounds])];
	[linesLayer setDelegate:self];
	[[timeline visualizationLayer] insertSublayer:linesLayer below:graphLayer];
	[linesLayer setNeedsDisplay];	
}

-(void)createGraph
{	
	NSTimeInterval movieTime;
	NSTimeInterval pointTime;
	NSTimeInterval rangeTime;
	NSTimeInterval rangeDuration;
	
	TimeSeriesData *data = [[timeline dataSets] objectAtIndex:0];
    
    if(![data color])
        [data setColor:[NSColor greenColor]];
	
	QTGetTimeInterval([timeline range].start, &rangeTime);
	QTGetTimeInterval([timeline range].duration, &rangeDuration);
	CGFloat graphWidth = [timeline bounds].size.width;
	float movieTimeToPixel = graphWidth/rangeDuration;
	float dataRange;

       
    
	// Check to see if there are too few or too many points represented
	if(!subset
	   || ([subset count] > graphWidth/1.9) 
	   || (([subset count] < graphWidth/2.5) && ([[data dataPoints] count] > graphWidth/3))
	   || (!QTEqualTimeRanges([timeline range], subsetRange) && ![timeline resizing]) )
	{
		[subset release];
		subset = [[NSMutableArray alloc] initWithCapacity:graphWidth/2];
		subsetMax = -CGFLOAT_MAX;
		subsetMin = CGFLOAT_MAX;
		//float pixelToMovieTime = (float)range.duration.timeValue/graphWidth;
		float pixelToMovieTime = rangeDuration/graphWidth;
		float pixel = 0;
		movieTime = rangeTime + pixel*pixelToMovieTime;
		for(TimeCodedDataPoint *point in [data dataPoints])
		{
			QTGetTimeInterval([point time], &pointTime);
			if(pointTime >= movieTime)
			{
				subsetMax = fmax(subsetMax, [point value]);
				subsetMin = fmin(subsetMin, [point value]);
				[subset addObject:point];
				pixel += 2;
				movieTime = rangeTime + pixel*pixelToMovieTime;
				if(pixel > graphWidth)
				{
					break;
				}
			}
		}
        
		//NSLog(@"Created Subset: %i/%i",[subset count],[[data dataPoints] count]);
		subsetRange = [timeline range];
		//NSLog(@"Max/Min: %f/%f",subsetMax,subsetMin);
		dataRange = subsetMax - subsetMin; //[data maxValue] - [data minValue];
		subsetMax = subsetMax + (dataRange * 0.05);
		subsetMin = subsetMin - (dataRange * 0.05);
	}
	
	dataRange = subsetMax - subsetMin;
	float valueToPixel = [timeline bounds].size.height/dataRange;
	//NSLog(@"Max/Min: %f/%f",subsetMax,subsetMin);
	
	[graph release];
	[graphLayer removeFromSuperlayer];
	[graphLayer release];
	
	if([subset count] == 0)
	{
		graph = nil;
		//graphLayer = nil;
        
        graphLayer = [[CALayer layer] retain];
		[graphLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
		CGRect graphFrame = NSRectToCGRect([timeline bounds]);
		graphFrame.size.width = graphWidth;
		[graphLayer setFrame:graphFrame];
		[graphLayer setDelegate:self];
		//[graphLayer setShadowOpacity:0.5];
		[[timeline visualizationLayer] addSublayer:graphLayer];
		[graphLayer setNeedsDisplay];
	}
	else
	{
		graph = [[NSBezierPath alloc] init];
		
		[graph setLineWidth:3.0];
		[graph setLineJoinStyle:NSRoundLineJoinStyle];
		TimeCodedDataPoint *first = [subset objectAtIndex:0];
		QTGetTimeInterval([first time], &pointTime);
		[graph moveToPoint:NSMakePoint((pointTime - rangeTime) * movieTimeToPixel, 
									   ([first value] - subsetMin) * valueToPixel)];

		for(TimeCodedDataPoint *point in subset)
		{
			QTGetTimeInterval([point time], &pointTime);
			[graph lineToPoint:NSMakePoint((pointTime - rangeTime) * movieTimeToPixel, 
										   ([point value] - subsetMin) * valueToPixel)];
		}
		
//        NSTimeInterval maxTimeGap = [self intervalModeForSubset:subset withID:dataSetID] * 5.0;
//        NSTimeInterval lastTime = rangeTime;
//        CGFloat previous = 0;
//        CGFloat x;
//        for(TimeCodedDataPoint *dataPoint in subset)
//        {
//            
//            QTGetTimeInterval([dataPoint time], &pointTime);
//            
//            x = floor((pointTime - rangeTime) * movieTimeToPixel);
//            
//            if(((x - previous) > 1.1) && ((pointTime - lastTime) > maxTimeGap))
//            {
//                QTGetTimeInterval([dataPoint time], &pointTime);
//                [graph moveToPoint:NSMakePoint((pointTime - rangeTime) * movieTimeToPixel, 
//                                               ([dataPoint value] - subsetMin) * valueToPixel)];
//            }
//            else
//            {
//                QTGetTimeInterval([dataPoint time], &pointTime);
//                [graph lineToPoint:NSMakePoint((pointTime - rangeTime) * movieTimeToPixel, 
//                                               ([dataPoint value] - subsetMin) * valueToPixel)];
//            }
//            
//            lastTime = pointTime;
//            previous = x;
//        }
        

		graphLayer = [[CALayer layer] retain];
		[graphLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
		CGRect graphFrame = NSRectToCGRect([timeline bounds]);
		graphFrame.size.width = graphWidth;
		[graphLayer setFrame:graphFrame];
		[graphLayer setDelegate:self];
		[graphLayer setShadowOpacity:0.5];
		[[timeline visualizationLayer] addSublayer:graphLayer];
		[graphLayer setNeedsDisplay];
		
		[self createLines];
	}
	
	createdGraph = YES;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	CGRect boundingBox = CGContextGetClipBoundingBox(ctx);
	
	BOOL numbers = NO;
	
	if(boundingBox.origin.x == 0)
	{
		numbers = YES;
	}
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	NSGraphicsContext *nsGraphicsContext;
	nsGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx
																   flipped:NO];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:nsGraphicsContext];
	
	if(layer == linesLayer)
	{
        NSColor *linesColor = [NSColor whiteColor];
        
        if([timeline whiteBackground])
        {
            linesColor = [NSColor grayColor];
        }

        [linesColor set];
        
		
		
		NSMutableParagraphStyle *axisstyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[axisstyle setAlignment:NSRightTextAlignment];
		NSArray *axiskeys = [NSArray arrayWithObjects:NSFontAttributeName,NSParagraphStyleAttributeName,NSForegroundColorAttributeName,nil];
		NSArray *axisobjects = [NSArray arrayWithObjects:[NSFont fontWithName:@"Helvetica" size:12.0],axisstyle,linesColor,nil];
		NSDictionary *axisAttr = [NSDictionary dictionaryWithObjects:axisobjects
															 forKeys:axiskeys];
		
		if(numbers)
		{

			float valueToPixel = [timeline bounds].size.height/(subsetMax - subsetMin);
			NSString *label;
			
			int i;
			numbersWidth = 0;
			float height = 0;
			float lineValue = firstLine;
			
			// Go through labels to determine size for alignment
			for(i = 0; i < numLines; i++)
			{
				if(lineScale > 1)
				{
					label = [NSString stringWithFormat:@"%i",(int)lineValue];
				}
				else
				{
					label = [NSString stringWithFormat:@"%.2f",lineValue];
				}
				NSSize labelSize = [label sizeWithAttributes:axisAttr];
				if(labelSize.width > numbersWidth)
				{
					numbersWidth = labelSize.width;
					height = labelSize.height;
				}
				lineValue += lineScale;
			}
			
			// Draw labels
			lineValue = firstLine;
			for(i = 0; i < numLines; i++)
			{
				if(lineScale > 1)
				{
					label = [NSString stringWithFormat:@"%i",(int)lineValue];
				}
				else
				{
					label = [NSString stringWithFormat:@"%.2f",lineValue];
				}
				
				[label drawInRect:NSMakeRect(5,((lineValue - subsetMin) * valueToPixel) - height/2.0,numbersWidth,height) withAttributes:axisAttr];
				lineValue += lineScale;
			}
		}
		
		NSAffineTransform* xform = [NSAffineTransform transform];
		[xform translateXBy:(numbersWidth + 10) yBy:0.0];
		[xform concat];
		
		[lines setLineWidth:1.0];
		[lines stroke];
		
		[xform translateXBy:-2*(numbersWidth + 10) yBy:0.0];
		[xform concat];
		
//		if(label)
//		{
//			// Draw name
//			NSFont *helvBold = [[NSFontManager sharedFontManager] convertWeight:YES ofFont:[NSFont fontWithName:@"Helvetica Bold" size:16.0]];
//			axisobjects = [NSArray arrayWithObjects:helvBold,axisstyle,[NSColor darkGrayColor],nil];
//			axisAttr = [NSDictionary dictionaryWithObjects:axisobjects forKeys:axiskeys];
//			[[data name] drawInRect:NSMakeRect(0,0,[timeline bounds].size.width,20) withAttributes:axisAttr];
//		}
		
	}
	else
	{
        NSColor *graphColor = [[[timeline dataSets] objectAtIndex:0] color];
        if([timeline whiteBackground])
        {
            [graphLayer setShadowOpacity:0];
            graphColor = [NSColor blackColor];
        }
        else
        {
            [graphLayer setShadowOpacity:0.5];
        }
        
        if(graph && NSIntersectsRect([graph bounds], [timeline bounds]))
        {
            [graphColor set];
            //[[NSColor greenColor] set];
            [graph setLineWidth:2.0];
            [graph stroke];
        }
        else
        {
            TimeSeriesData *data = [[timeline dataSets] objectAtIndex:0];
            NSArray *dataPoints = [data dataPoints];
            
            TimeCodedDataPoint *firstPoint = [dataPoints objectAtIndex:0];
            //TimeCodedDataPoint *lastPoint = [dataPoints lastObject];
            if(QTTimeCompare([firstPoint time], QTTimeRangeEnd([timeline range])) == NSOrderedDescending)
            {
                CATextLayer *outsideRangeLayer = [CATextLayer layer];
                [outsideRangeLayer setFrame:[graphLayer bounds]];
                [outsideRangeLayer setFontSize:16.0];
                [outsideRangeLayer setAlignmentMode:kCAAlignmentRight];
                [outsideRangeLayer setString:[NSString stringWithFormat:@"Data starts\nat %@",[NSString stringWithQTTime:[firstPoint time]]]];
                
                [graphLayer addSublayer:outsideRangeLayer];
            }
        }
	}
	
	[NSGraphicsContext restoreGraphicsState];
	
	[CATransaction commit];
}

-(BOOL)updateMarkers
{
    if([timeline whiteBackground])
    {
        return NO;
    }
	else if([timeline inLiveResize] && QTEqualTimeRanges([timeline range], subsetRange))
	{
		CGRect graphBounds = NSRectToCGRect([timeline bounds]);
		//graphBounds.size.width = graphBounds.size.width * [timeline zoomFactor];
		graphLayer.bounds =  graphBounds;
		[self createLines];
		return YES;
	}
	else
	{
		return NO;
	}
	
	//return NO;
}

-(void)drawMarker:(TimelineMarker*)marker
{
//	if(([[[marker layer] sublayers] count] == 0) && [marker image])
//	{
//		[marker layer].borderColor = CGColorCreateGenericRGB(0.2, 0.3, 0.4, 1.0);
//		[marker layer].borderWidth = 2.0;
//		//		[marker layer].anchorPoint = CGPointMake(0.0,0.0);
//		//		CGPoint position = [marker layer].position;
//		//		[marker layer].position = 
//		CALayer *layer = [CALayer layer];
//		layer.bounds = [marker layer].bounds;
//		layer.anchorPoint = CGPointMake(0.0, 0.0);
//		layer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
//		[[marker layer] addSublayer:layer];
//		layer.contents = (id)[marker image];	
//	}
}

@end
