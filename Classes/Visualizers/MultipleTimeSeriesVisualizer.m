//
//  MultipleTimeSeriesVisualizer.m
//  ChronoViz
//
//  Created by Adam Fouse on 1/7/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "MultipleTimeSeriesVisualizer.h"
#import "TimeCodedDataPoint.h"
#import "TimeSeriesData.h"
#import "DataSource.h"

@implementation MultipleTimeSeriesVisualizer

-(id)initWithTimelineView:(TimelineView*)timelineView
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{
		NSArray *dataSets = [timeline dataSets];
		
		for(TimeSeriesData *dataSource in dataSets)
		{
			if(dataSource != [dataSets objectAtIndex:0])
			{
				[[NSNotificationCenter defaultCenter] addObserver:self
														 selector:@selector(reloadData)
															 name:DataSourceUpdatedNotification
														   object:dataSource];
			}
		}
		
		subsets = [[NSMutableArray alloc] initWithCapacity:[dataSets count]];
		subsetRanges = [[NSMutableArray alloc] initWithCapacity:[dataSets count]];
		subsetDataMaxes = [[NSMutableArray alloc] initWithCapacity:[dataSets count]];
		subsetDataMins = [[NSMutableArray alloc] initWithCapacity:[dataSets count]];
		graphs = [[NSMutableArray alloc] initWithCapacity:[dataSets count]];
		
		maxValuePoint = [[TimeCodedDataPoint alloc] init];
		[maxValuePoint setValue:-CGFLOAT_MAX];
		minValuePoint = [[TimeCodedDataPoint alloc] init];
		[minValuePoint setValue:CGFLOAT_MAX];

	}
	return self;
}

- (void) dealloc
{
	[subsets release];
	[subsetRanges release];
	[subsetDataMaxes release];
	[subsetDataMins release];
	[maxValuePoint release];
	[minValuePoint release];
	[graphs release];
	[super dealloc];
}

- (void)reloadData
{
	[subsets removeAllObjects];
	[self createGraph];
}

-(void)createGraph
{	
	NSTimeInterval movieTime;
	NSTimeInterval pointTime;
	NSTimeInterval rangeTime;
	NSTimeInterval rangeDuration;
	
	CGFloat graphWidth = [timeline bounds].size.width;
	
	if([subsets count] != [[timeline dataSets] count])
	{
		[subsets removeAllObjects];
		[subsetRanges removeAllObjects];
		[subsetDataMaxes removeAllObjects];
		[subsetDataMins removeAllObjects];
		for(NSObject *obj in [timeline dataSets])
		{
			
			[subsets addObject:[NSMutableArray arrayWithCapacity:graphWidth/2]];
			[subsetRanges addObject:[NSValue valueWithQTTimeRange:[timeline range]]];
			[subsetDataMaxes addObject:[NSNumber numberWithFloat:0]];
			[subsetDataMins addObject:[NSNumber numberWithFloat:0]];
		}
	}
	
	subsetMax = -CGFLOAT_MAX;
	subsetMin = CGFLOAT_MAX;
	
	// Calculate the data range and calibrate subsets
	int index = 0;
	for(TimeSeriesData *data in [timeline dataSets])
	{	
		
		if(index == 0)
		{
			[data setColor:[NSColor greenColor]];
		}
		else if (index == 1)
		{
			[data setColor:[NSColor blueColor]];
		}
		else if (index == 2)
		{
			[data setColor:[NSColor orangeColor]];
		}
		else if (index == 3)
		{
			[data setColor:[NSColor redColor]];
		}
		
		
		rangeTime = CMTimeGetSeconds([timeline range].start);
		rangeDuration = CMTimeGetSeconds([timeline range].duration);
		
		NSMutableArray *dataSubset = [subsets objectAtIndex:index];
		CMTimeRange dataSubsetRange = [[subsetRanges objectAtIndex:index] CMTimeRangeValue];
		
		
		// Check to see if there are too few or too many points represented
		if(!dataSubset
           || ([dataSubset count] == 0)
		   || ([dataSubset count] > graphWidth/1.9) 
		   || (([dataSubset count] < graphWidth/2.5) && ([[data dataPoints] count] > graphWidth/3))
		   || (!CMTimeRangeEqual([timeline range], dataSubsetRange) && ![timeline resizing]) )
		{
			[dataSubset removeAllObjects];
			CGFloat subsetDataMax = -CGFLOAT_MAX;
			CGFloat subsetDataMin = CGFLOAT_MAX;
			float pixelToMovieTime = rangeDuration/graphWidth;
			float pixel = 0;
			movieTime = rangeTime + pixel*pixelToMovieTime;
			
			//Better subset drawing
			TimeCodedDataPoint *pointMax = maxValuePoint;
			TimeCodedDataPoint *pointMin = minValuePoint;
			
			for(TimeCodedDataPoint *point in [data dataPoints])
			{
				pointMax = ([point value] >= [pointMax value]) ? point : pointMax;
				pointMin = ([point value] <= [pointMin value]) ? point : pointMin;
				
				pointTime = CMTimeGetSeconds([point time]);
				if(pointTime >= movieTime)
				{
					
					if(fabs([data mean] - [pointMax value]) > fabs([data mean] - [pointMin value]))
					{
						[dataSubset addObject:pointMax];
						subsetDataMax = fmax(subsetDataMax, [pointMax value]);
                        subsetDataMin = fmin(subsetDataMin, [pointMax value]);
					}
					else
					{
						[dataSubset addObject:pointMin];
                        subsetDataMax = fmax(subsetDataMax, [pointMin value]);
						subsetDataMin = fmin(subsetDataMin, [pointMin value]);
					}
				
					pointMax = maxValuePoint;
					pointMin = minValuePoint;
					
					//subsetDataMax = fmax(subsetDataMax, [point value]);
					//subsetDataMin = fmin(subsetDataMin, [point value]);
					//[dataSubset addObject:point];
					pixel += 2;
					movieTime = rangeTime + pixel*pixelToMovieTime;
					if(pixel > graphWidth)
					{
						break;
					}
				}
			}
			
			//NSLog(@"Created Subset for %@: %i/%i",[data name],[dataSubset count],[[data dataPoints] count]);
			
			[subsetRanges replaceObjectAtIndex:index withObject:[NSValue valueWithQTTimeRange:[timeline range]]];
			[subsetDataMaxes replaceObjectAtIndex:index withObject:[NSNumber numberWithDouble:subsetDataMax]];
			[subsetDataMins replaceObjectAtIndex:index withObject:[NSNumber numberWithDouble:subsetDataMin]];
			
		}
		
		subsetMax = fmax(subsetMax, [[subsetDataMaxes objectAtIndex:index] doubleValue]);
		subsetMin = fmin(subsetMin, [[subsetDataMins objectAtIndex:index] doubleValue]);
		
		index++;
	}
	
	float dataRange = subsetMax - subsetMin;
	
	// This gives the graph some padding on the top and bottom

	subsetMax = subsetMax + (dataRange * 0.05);
	subsetMin = subsetMin - (dataRange * 0.05);
	dataRange = subsetMax - subsetMin;
	
	float valueToPixel = [timeline bounds].size.height/dataRange;
	float movieTimeToPixel = graphWidth/rangeDuration;
	
	[graphs removeAllObjects];
	[graphLayer removeFromSuperlayer];
	[graphLayer release];
	
	graphLayer = [[CALayer layer] retain];
	[graphLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
	CGRect graphFrame = NSRectToCGRect([timeline bounds]);
	graphFrame.size.width = graphWidth;
	[graphLayer setFrame:graphFrame];
	[graphLayer setDelegate:self];
	[graphLayer setShadowOpacity:0.5];
	[[timeline visualizationLayer] addSublayer:graphLayer];
	
	for(NSArray *dataSubset in subsets)
	{	
		if([dataSubset count] > 0)
		{
			NSBezierPath *theGraph = [[NSBezierPath alloc] init];
			
			[theGraph setLineWidth:3.0];
			[theGraph setLineJoinStyle:NSRoundLineJoinStyle];
			TimeCodedDataPoint *first = [dataSubset objectAtIndex:0];
			QTGetTimeInterval([first time], &pointTime);
			[theGraph moveToPoint:NSMakePoint((pointTime - rangeTime) * movieTimeToPixel, 
										   ([first value] - subsetMin) * valueToPixel)];
			
			for(TimeCodedDataPoint *point in dataSubset)
			{
				QTGetTimeInterval([point time], &pointTime);
				[theGraph lineToPoint:NSMakePoint((pointTime - rangeTime) * movieTimeToPixel, 
											   ([point value] - subsetMin) * valueToPixel)];
			}
			
			[graphs addObject:theGraph];
			
			[theGraph release];
	
		}
	}
	
	[self createLines];
	[graphLayer setNeedsDisplay];
	
	createdGraph = YES;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	CGRect boundingBox = CGContextGetClipBoundingBox(ctx);
	
	BOOL numbers = NO;
	BOOL label = YES;
	
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
		[[NSColor whiteColor] set];
		
		
		NSMutableParagraphStyle *axisstyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[axisstyle setAlignment:NSRightTextAlignment];
		NSArray *axiskeys = [NSArray arrayWithObjects:NSFontAttributeName,NSParagraphStyleAttributeName,NSForegroundColorAttributeName,nil];
		NSArray *axisobjects = [NSArray arrayWithObjects:[NSFont fontWithName:@"Helvetica" size:12.0],axisstyle,[NSColor whiteColor],nil];
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
		
		if(label)
		{
            [timeline setLabel:@""];
            
			CGFloat labelsWidth = [timeline bounds].size.width;
			CGFloat labelHeight = 20;
			for(TimeSeriesData *data in [timeline dataSets])
			{
				// Draw name
				NSFont *helvBold = [[NSFontManager sharedFontManager] convertWeight:YES ofFont:[NSFont fontWithName:@"Helvetica Bold" size:16.0]];
				axisobjects = [NSArray arrayWithObjects:helvBold,axisstyle,[data color],nil];
				axisAttr = [NSDictionary dictionaryWithObjects:axisobjects forKeys:axiskeys];
				
				CGFloat width = [[data name] sizeWithAttributes:axisAttr].width + 5;
				
				labelsWidth -= width;
				
				[[data name] drawInRect:NSMakeRect(labelsWidth,0,width,labelHeight) withAttributes:axisAttr];
			}
		}
		
	}
	else
	{		
		int index = 0;
		for(TimeSeriesData *data in [timeline dataSets])
		{
			[[data color] set];
			
			NSBezierPath *theGraph = [graphs objectAtIndex:index];
			[theGraph setLineWidth:2.0];
			[theGraph stroke];	
			
			index++;
		}	
	}
	
	[NSGraphicsContext restoreGraphicsState];
	
	[CATransaction commit];
}




@end
