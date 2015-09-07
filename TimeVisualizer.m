//
//  TimeVisualizer.m
//  DataPrism
//
//  Created by Adam Fouse on 3/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TimeVisualizer.h"
#import "Annotation.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "NSStringTimeCodes.h"
#import "VideoProperties.h"

@implementation TimeVisualizer

-(id)initWithTimelineView:(TimelineView*)timelineView
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{		
		createdViz = NO;
		timesLayer = nil;
		
		lines = nil;
		
		minSpace = 40;
		maxSpace = 100;
		
		days = [[NSMutableArray alloc] init];
		lineDates = [[NSMutableArray alloc] init];
		lineTimes = [[NSMutableArray alloc] init];
				
		groundGradient = [[NSGradient alloc] initWithColorsAndLocations:
						  [NSColor colorWithDeviceRed:(89.0/255.0) green:(66.0/255.0) blue:(10.0/255.0) alpha:1.0],
						  0.0,
						  [NSColor colorWithDeviceWhite:0.2 alpha:1.0] ,
						  1.0,
						  nil];
		
		NSMutableParagraphStyle *labelstyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[labelstyle setAlignment:NSLeftTextAlignment];
		NSArray *labelkeys = [NSArray arrayWithObjects:NSFontAttributeName,NSParagraphStyleAttributeName,NSForegroundColorAttributeName,nil];
		NSArray *labelobjects = [NSArray arrayWithObjects:[NSFont fontWithName:@"Helvetica" size:12.0],labelstyle,[NSColor whiteColor],nil];
		labelAttr = [[NSDictionary alloc] initWithObjects:labelobjects
															  forKeys:labelkeys];
		
		[self setVideoProperties:[[AnnotationDocument currentDocument] videoProperties]];
		
		[[self videoProperties] addObserver:self
								 forKeyPath:@"startDate"
									options:0
									context:NULL];
				
	}
	return self;
}

- (void) dealloc
{
	[[self videoProperties] removeObserver:self forKeyPath:@"startDate"];
	
	[timesLayer removeFromSuperlayer];
	[timesLayer release];
	[lines release];
	[days release];
	[groundGradient release];
	[labelAttr release];
	[lineTimes release];
	[lineDates release];
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"startDate"])
	{
		[self updateMarkers];
    }
	else
	{
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
	}
}

-(void)reset
{
	createdViz = NO;
	[super reset];
}

-(void)setup
{
	if(!createdViz)
	{
		[self createLines];
	}
}

-(TimelineMarker *)addKeyframe:(SegmentBoundary*)keyframe
{
	[self setup];
	return nil;
}

-(void)createLayer
{	
	[timesLayer removeFromSuperlayer];
	[timesLayer release];
	timesLayer = [[CALayer layer] retain];
	[timesLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
	
	[timesLayer setFrame:CGRectMake(0, 0, [timeline bounds].size.width, [timeline bounds].size.height*0.7)];
	[timesLayer setShadowOpacity:0.8];
	[timesLayer setDelegate:self];
	//CALayer *existingSublayer = [[[timeline layer] sublayers] objectAtIndex:0];
	//[[timeline layer] insertSublayer:timesLayer below:[timeline visualizationLayer]];
	[[timeline timesLayer] addSublayer:timesLayer];
	[timesLayer setNeedsDisplay];	
}

-(void)createLines
{	
	NSTimeInterval start;
	QTGetTimeInterval([timeline range].time,&start);
	NSTimeInterval duration;
	QTGetTimeInterval([timeline range].duration,&duration); 
	NSTimeInterval end = start + duration;
	
	if(duration == 0)
		return;
	
	[days removeAllObjects];
	[lines release];
	lines = nil;
	[lineDates removeAllObjects];
	[lineTimes removeAllObjects];
	
	NSSize labelSize = [[self timeCodeString:0] sizeWithAttributes:labelAttr];
	if((labelSize.width > minSpace) || (labelSize.width < (minSpace - 15)))
	{
		minSpace = labelSize.width + 10;
		maxSpace = (minSpace * 2) + 20;
	}
	
//	NSTimeInterval durationInterval;
//	QTGetTimeInterval([timeline range].duration, &durationInterval);
//	
//	if(durationInterval > (60*60))
//	{
//		minSpace = 50;
//		maxSpace = 120;
//	}
	
	CGFloat timeToPixel = [timeline bounds].size.width/duration;
	interval = 1;
	BOOL goodInterval = NO;
	
	while(!goodInterval)
	{
		if((interval * timeToPixel) > maxSpace)
		{
			interval = interval/2;
		}
		else if ((interval * timeToPixel) < minSpace)
		{
			if(interval == 1)
			{
				interval = 5;
			}
			else if (interval == 20)
			{
				interval = 25;
			}
			else 
			{
				interval = interval * 2;
			}
		}
		else 
		{
			goodInterval = YES;
		}

	}
	
	CGFloat height = [timeline bounds].size.height;
	CGFloat groundHeight = height * 0.7;
	lineHeight = groundHeight/3.0;
	if(lineHeight > 10)
	{
		lineHeight = 10;
	}
	

	lines = [[NSBezierPath alloc] init];
	
	
	NSTimeInterval currentTime = interval;
	
	while(YES)
	{		
		CGFloat xPosition = (currentTime - start) * timeToPixel;
			
		if((xPosition > -20) && (xPosition < [timeline bounds].size.width + 20))
		{
			[lines moveToPoint:NSMakePoint(xPosition, 0)];
			[lines lineToPoint:NSMakePoint(xPosition, lineHeight)];
			[lineTimes addObject:[NSNumber numberWithFloat:currentTime] ];
		}
		else if (currentTime > end)
		{
			break;
		}
		
		currentTime += interval;
	}
	
	
	[self createLayer];
	
	createdViz = YES;
}
			 
- (NSString*)timeCodeString:(NSTimeInterval)time
{
	if([[AppController currentApp] absoluteTime])
	{
		return [NSString stringWithTimeInterval:time sinceDate:[[AnnotationDocument currentDocument] startDate]];
	}
	
	NSTimeInterval durationInterval;
	QTGetTimeInterval([timeline range].duration, &durationInterval);
	
	if(durationInterval > (60*60))//minutes > 60)
	{
        return [NSString stringWithTimeInterval:time sinceDate:nil withOptions:(DPTimeCodeHoursMask | DPTimeCodeMinutesMask | DPTimeCodeSecondsMask)];
	}
	
	if(interval > 0.9)
	{
        return [NSString stringWithTimeInterval:time sinceDate:nil withOptions:(DPTimeCodeMinutesMask | DPTimeCodeSecondsMask)];
	}
	else
	{
        return [NSString stringWithTimeInterval:time sinceDate:nil withOptions:(DPTimeCodeMinutesMask | DPTimeCodeSecondsMask | DPTimeCodeDecisecondsMask)];
	}
	
}
			 

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	NSGraphicsContext *nsGraphicsContext;
	nsGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx
																   flipped:NO];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:nsGraphicsContext];
	
	if (layer == timesLayer)
	{
		NSTimeInterval start;
		QTGetTimeInterval([timeline range].time,&start);
		NSTimeInterval duration;
		QTGetTimeInterval([timeline range].duration,&duration);
		CGFloat timeToPixel = [timeline bounds].size.width/duration;
		
		//[[NSColor colorWithDeviceRed:(89.0/255.0) green:(66.0/255.0) blue:(10.0/255.0) alpha:1.0] setFill];
		//[groundGradient drawInRect:NSRectFromCGRect([layer bounds]) angle:90];
		//[NSBezierPath fillRect:NSRectFromCGRect([layer bounds])];
		
        NSDictionary *labelAttributes = labelAttr;
        NSColor *lineColor = [NSColor whiteColor];
        
        if([timeline whiteBackground])
        {
            lineColor = [NSColor darkGrayColor];
            NSMutableDictionary *whiteLabelAttributes = [NSMutableDictionary dictionaryWithDictionary:labelAttr];
            [whiteLabelAttributes setObject:lineColor forKey:NSForegroundColorAttributeName];
            labelAttributes = whiteLabelAttributes;
            
            [timesLayer setShadowOpacity:0];
        }
        else
        {
            [timesLayer setShadowOpacity:0.8];
        }
        
		[lineColor set];
		[lines setLineWidth:2.0];
		[lines stroke];
		
		NSSize labelSize = [[self timeCodeString:[[lineTimes objectAtIndex:0] floatValue]] sizeWithAttributes:labelAttributes];
		for(NSNumber *time in lineTimes)
		{
			NSString *label = [self timeCodeString:[time floatValue]];
			[label drawAtPoint:NSMakePoint((timeToPixel * ([time floatValue] - start)) - labelSize.width/2,lineHeight + 2) withAttributes:labelAttributes];
		}
		
	}
	
	
	
	[NSGraphicsContext restoreGraphicsState];
	
	[CATransaction commit];
}

-(BOOL)updateMarkers
{
	timesLayer.bounds = NSRectToCGRect([timeline bounds]);
	[self createLines];
	return YES;
	
	//	if([timeline inLiveResize])
	//	{
	//
	//	}
	//	else
	//	{
	//		return NO;
	//	}
	
}


@end
