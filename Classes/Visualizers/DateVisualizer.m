//
//  DateVisualizer.m
//  Annotation
//
//  Created by Adam Fouse on 11/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DateVisualizer.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "VideoProperties.h"

@implementation DateVisualizer

-(id)initWithTimelineView:(TimelineView*)timelineView
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{		
		createdViz = NO;
		skyLayer = nil;
		groundLayer = nil;
		sunLayer = nil;

		lines = nil;
		orbs = nil;
		
		days = [[NSMutableArray alloc] init];
		lineDates = [[NSMutableArray alloc] init];
		lineTimes = [[NSMutableArray alloc] init];
		
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"EEE MMM d"];
		
		timeFormatter = [[NSDateFormatter alloc] init];
		[timeFormatter setDateFormat:@"h a"];
		
		sunColor = [[NSColor colorWithDeviceRed:(248.0/255.0) green:(198.0/255.0) blue:(66.0/255.0) alpha:1.0] retain];

		nightColor = [[NSColor colorWithDeviceRed:(48.0/255.0) green:(59.0/255.0) blue:(85.0/255.0) alpha:1.0] retain];
		
		dayColor = [[NSColor colorWithDeviceRed:(107.0/255.0) green:(181.0/255.0) blue:(228.0/255.0) alpha:1.0] retain];
		
		groundGradient = [[NSGradient alloc] initWithColorsAndLocations:
						  [NSColor colorWithDeviceRed:(89.0/255.0) green:(66.0/255.0) blue:(10.0/255.0) alpha:1.0],
						  0.0,
						  [NSColor colorWithDeviceWhite:0.2 alpha:1.0] ,
						  1.0,
						  nil];
		
//		dayGradient = [[NSGradient alloc] initWithColorsAndLocations:		
//					   nightColor,
//					   0.0,
//					   nightColor,
//					   0.1,
//					   dayColor,
//					   0.3,
//					   dayColor,
//					   0.5,
//					   dayColor,
//					   0.7,
//					   nightColor,
//					   0.9,
//					   nightColor,
//					   1.0,
//					   nil];
		
		dayGradient = [[NSGradient alloc] initWithColorsAndLocations:		
					   [NSColor colorWithDeviceRed:(48.0/255.0) green:(59.0/255.0) blue:(85.0/255.0) alpha:1.0],
					   0.0,
					   [NSColor colorWithDeviceRed:(0/255.0) green:(68.0/255.0) blue:(133.0/255.0) alpha:1.0],
					   0.15,
					   [NSColor colorWithDeviceRed:(0/255.0) green:(124.0/255.0) blue:(194.0/255.0) alpha:1.0],
					   0.3,
					   [NSColor colorWithDeviceRed:(107.0/255.0) green:(181.0/255.0) blue:(228.0/255.0) alpha:1.0],
					   0.5,
					   [NSColor colorWithDeviceRed:(0/255.0) green:(124.0/255.0) blue:(194.0/255.0) alpha:1.0],
					   0.7,
					   [NSColor colorWithDeviceRed:(0/255.0) green:(68.0/255.0) blue:(133.0/255.0) alpha:1.0],
					   0.85,
					   [NSColor colorWithDeviceRed:(48.0/255.0) green:(59.0/255.0) blue:(85.0/255.0) alpha:1.0],
					   1.0,
					   nil];
		
	}
	return self;
}

- (void) dealloc
{
	[skyLayer removeFromSuperlayer];
	[groundLayer removeFromSuperlayer];
	[skyLayer release];
	[groundLayer release];
	[orbs release];
	[lines release];
	[days release];
	[dayGradient release];
	[groundGradient release];
	[sunColor release];
	[super dealloc];
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
		[self createSky];
	}
}

-(TimelineMarker *)addKeyframe:(SegmentBoundary*)keyframe
{
	[self setup];
	return nil;
}

-(void)createGround
{	
	[groundLayer removeFromSuperlayer];
	[groundLayer release];
	groundLayer = [[CALayer layer] retain];
	[groundLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
	
	[groundLayer setFrame:CGRectMake(0, 0, [timeline bounds].size.width, [timeline bounds].size.height*0.7)];
	[groundLayer setShadowOpacity:0.8];
	[groundLayer setDelegate:self];
	[[timeline visualizationLayer] addSublayer:groundLayer];
	[groundLayer setNeedsDisplay];	
}

-(void)createSky
{	
	NSDate *annotationsStart = [[[AppController currentDoc] videoProperties] startDate];
	NSTimeInterval start;
	start = CMTimeGetSeconds([timeline range].time);
	NSTimeInterval duration;
	duration = CMTimeGetSeconds([timeline range].duration); 
	[startDate release];
	[endDate release];
	startDate = [[NSDate alloc] initWithTimeInterval:start sinceDate:annotationsStart];
	endDate = [[NSDate alloc] initWithTimeInterval:duration sinceDate:startDate];
	
	[days removeAllObjects];
	[orbs release];
	[lines release];
	orbs = nil;
	lines = nil;
	[lineDates removeAllObjects];
	[lineTimes removeAllObjects];
	
	if(duration > 60*60*6)
	{
		NSDate * currentDate = startDate;
		orbs = [[NSBezierPath alloc] init];
		lines = [[NSBezierPath alloc] init];
		
		CGFloat timeToPixel = [timeline bounds].size.width/duration;
		CGFloat height = [timeline bounds].size.height;
		CGFloat groundHeight = height * 0.7;
		
		//CGFloat sunSize = 10;
		
		NSTimeInterval hourInterval = 60 * 60;
		
		NSCalendar *gregorian = [[NSCalendar alloc]
								 initWithCalendarIdentifier:NSGregorianCalendar];
		
		NSDateComponents *timeComponents = [gregorian components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:currentDate];
		
		NSInteger hour = [timeComponents hour];
		NSInteger minute = [timeComponents minute];
		
        hour++;
        currentDate = [currentDate dateByAddingTimeInterval:(60 - minute) * 60];
        
		//hour++;
		
		//int offset = fmod(hour,3);
		
		//currentDate = [currentDate addTimeInterval:((3 - offset) * hourInterval) + (60 - minute) * 60];
		
		//hour += (3 - offset);
		
		
		while([currentDate compare:endDate] == NSOrderedAscending)
		{
			NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:startDate];
			CGFloat xPosition = timeInterval * timeToPixel;
			
			if(((hour == 6) || (hour == 18)) && (height > 30))
			{
				//[orbs appendBezierPathWithOvalInRect:NSMakeRect(xPosition - sunSize/2, height*.7 - sunSize/2, sunSize, sunSize)];
				
				if(hourInterval * 3 * timeToPixel > 20)
				{
					[lines moveToPoint:NSMakePoint(xPosition, 0)];
					[lines lineToPoint:NSMakePoint(xPosition, groundHeight/3.0)];
					[lineTimes addObject:currentDate];
				}
			}
			else if(((hour == 9) || (hour == 15)) && (height > 30))
			{
				//[orbs appendBezierPathWithOvalInRect:NSMakeRect(xPosition - sunSize/2, height*.85 - sunSize/2, sunSize, sunSize)];
				if(hourInterval * 3 * timeToPixel > 40)
				{
					[lines moveToPoint:NSMakePoint(xPosition, 0)];
					[lines lineToPoint:NSMakePoint(xPosition, groundHeight/3.0)];
					[lineTimes addObject:currentDate];
				}
			}
			else if((hour == 12) && (height > 30))
			{
				//[orbs appendBezierPathWithOvalInRect:NSMakeRect(xPosition - sunSize/2, height*.9 - sunSize/2, sunSize, sunSize)];
				[lines moveToPoint:NSMakePoint(xPosition, 0)];
				[lines lineToPoint:NSMakePoint(xPosition, groundHeight/3.0)];
				[lineTimes addObject:currentDate];
			}
			else if(((hour == 3) || (hour == 21)) && (height > 30))
			{
				if(hourInterval * 3 * timeToPixel > 40)
				{
					[lines moveToPoint:NSMakePoint(xPosition, 0)];
					[lines lineToPoint:NSMakePoint(xPosition, groundHeight/3.0)];
					[lineTimes addObject:currentDate];
				}
			}
			else if(hour == 24)
			{
				[days addObject:[NSNumber numberWithFloat:(xPosition)]];
				[lines moveToPoint:NSMakePoint(xPosition, 0)];
				[lines lineToPoint:NSMakePoint(xPosition, groundHeight)];
				[lineDates addObject:currentDate];
				
				if(height > 30)
				{
					[lineTimes addObject:currentDate];
				}
				
			}
            else if (hourInterval * 3 * timeToPixel > 100)
            {
                [lines moveToPoint:NSMakePoint(xPosition, 0)];
                [lines lineToPoint:NSMakePoint(xPosition, groundHeight/3.0)];
                [lineTimes addObject:currentDate];   
            }
			
            int hourIncrement = 1;
            
			hour += hourIncrement;
			if(hour > 24)
			{
				hour = hourIncrement;
			}
			
			currentDate = [currentDate dateByAddingTimeInterval:(hourIncrement*hourInterval)];
	
		}
	}
	
	
	
//	[skyLayer removeFromSuperlayer];
//	[skyLayer release];
//	skyLayer = [[CALayer layer] retain];
//	[skyLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
//	[skyLayer setFrame:NSRectToCGRect([timeline bounds])];
//	[skyLayer setDelegate:self];
//	//[skyLayer setShadowOpacity:0.5];
//	[[timeline layer] insertSublayer:skyLayer below:[timeline playheadLayer]];
//	[skyLayer setNeedsDisplay];
//	
//	[sunLayer removeFromSuperlayer];
//	[sunLayer release];
//	sunLayer = [[CALayer layer] retain];
//	[sunLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
//	[sunLayer setFrame:NSRectToCGRect([timeline bounds])];
//	[sunLayer setDelegate:self];
//	[sunLayer setShadowOpacity:0.5];
//	[skyLayer addSublayer:sunLayer];
//	[sunLayer setNeedsDisplay];
	
	[self createGround];
	
	createdViz = YES;
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
	
	if(NO) // layer == skyLayer)
	{
		[nightColor setFill];
		[NSBezierPath fillRect:NSRectFromCGRect([layer bounds])];
		
		CGFloat start = 0;
		CGFloat end = 0;
		for(NSNumber *endNum in days)
		{
			end = [endNum floatValue];
			
			[nightColor setFill];
			[NSBezierPath fillRect:NSMakeRect(start, 0, (end - start)/4.0, [layer bounds].size.height)];
			
			[dayColor setFill];
			[NSBezierPath fillRect:NSMakeRect(start + (end - start)/4, 0, (end - start)/2.0, [layer bounds].size.height)];
			
			[nightColor setFill];
			[NSBezierPath fillRect:NSMakeRect(start + 3*(end - start)/4, 0, (end - start)/4.0, [layer bounds].size.height)];
			

//			[dayGradient drawInRect:NSMakeRect(start, 0, end - start, [layer bounds].size.height) angle:0];
			start = end;
		}
		
	}
	else if (NO) //layer == sunLayer)
	{
		[sunColor setFill];
		[orbs fill];
	}
	else if (layer == groundLayer)
	{
		NSTimeInterval duration;
		duration = CMTimeGetSeconds([timeline range].duration);
		CGFloat timeToPixel = [timeline bounds].size.width/duration;
		
		//[[NSColor colorWithDeviceRed:(89.0/255.0) green:(66.0/255.0) blue:(10.0/255.0) alpha:1.0] setFill];
		//[groundGradient drawInRect:NSRectFromCGRect([layer bounds]) angle:90];
		//[NSBezierPath fillRect:NSRectFromCGRect([layer bounds])];
		
		[[NSColor whiteColor] set];
		[lines setLineWidth:2.0];
		[lines stroke];
		
		NSMutableParagraphStyle *labelstyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[labelstyle setAlignment:NSLeftTextAlignment];
		NSArray *labelkeys = [NSArray arrayWithObjects:NSFontAttributeName,NSParagraphStyleAttributeName,NSForegroundColorAttributeName,nil];
		NSArray *labelobjects = [NSArray arrayWithObjects:[NSFont fontWithName:@"Helvetica" size:12.0],labelstyle,[NSColor whiteColor],nil];
		NSDictionary *labelAttr = [NSDictionary dictionaryWithObjects:labelobjects
															 forKeys:labelkeys];
		
		for(NSDate *time in lineTimes)
		{
			NSString *label = [timeFormatter stringFromDate:time];
			[label drawAtPoint:NSMakePoint([time timeIntervalSinceDate:startDate] * timeToPixel + 3,5) withAttributes:labelAttr];
		}
		
		for(NSDate *date in lineDates)
		{
			NSString *label = [dateFormatter stringFromDate:date];
			[label drawAtPoint:NSMakePoint([date timeIntervalSinceDate:startDate] * timeToPixel + 8.5,[layer bounds].size.height - 20) withAttributes:labelAttr];
		}
		
	}
	

	
	[NSGraphicsContext restoreGraphicsState];
	
	[CATransaction commit];
}

-(BOOL)updateMarkers
{
	groundLayer.bounds = NSRectToCGRect([timeline bounds]);
	[self createSky];
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
