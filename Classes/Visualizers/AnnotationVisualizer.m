//
//  AnnotationVisualizer.m
//  Annotation
//
//  Created by Adam Fouse on 8/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationVisualizer.h"
#import "Annotation.h"
#import "AnnotationCategory.h"
#import "NSColorCGColor.h"
#import <AVKit/AVKit.h>

@interface AnnotationVisualizer (AnnotationVisualizerPrivateMethods)

- (NSString*)trackNameForMarker:(TimelineMarker*)marker;

@end

@implementation AnnotationVisualizer

@synthesize lineUpCategories;
@synthesize inlinePointAnnotations;
@synthesize drawLabels;

-(id)initWithTimelineView:(TimelineView*)timelineView
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{
		annotationRadius = 5;
		durationBarHeight = 15;
		categoryTracks = nil;
		trackLayers = nil;
		tracks = nil;
		[self setLineUpCategories:YES];
		[self setInlinePointAnnotations:YES];
		[self setDrawLabels:YES];
	}
	return self;
}

- (void) dealloc
{
	[categoryTracks release];
	[tracks release];
	[super dealloc];
}

-(void)reset
{
	[self clearTracks];
	[super reset];
}

-(void)toggleAlignCategories
{
	lineUpCategories = !lineUpCategories;
	[self updateMarkers];
}

-(void)toggleShowLabels
{
	drawLabels = !drawLabels;
	[self updateMarkers];
}

-(void)clearTracks
{
	[categoryTracks release];
	[tracks release];
	categoryTracks = nil;
	tracks = nil;
}

- (NSString*)trackNameForMarker:(TimelineMarker*)marker
{
	AnnotationCategory *category;
	if(lineUpCategories && [[[marker annotation] category] category])
	{
		category = [[[marker annotation] category] category];
	}
	else
	{
		category = [[marker annotation] category];
	}
	
	NSString *categoryName= [category name];
	
	if(!categoryName)
	{
		categoryName = @"";
	}
	
	return categoryName;
}

-(void)sortMarkers
{
	NSSortDescriptor *timeDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES] autorelease];
	[markers sortUsingDescriptors:[NSArray arrayWithObject:timeDescriptor]];
	
	if(!categoryTracks)
	{
		categoryTracks = [[NSMutableDictionary alloc] init];
		trackLayers = [[NSMutableDictionary alloc] init];
	}
	if(!tracks)
	{
		tracks = [[NSMutableDictionary alloc] init];
	}
	else
	{
		[tracks removeAllObjects];
	}
	NSInteger maxTrack = 0;
	for(NSNumber *existingTrack in [categoryTracks allValues])
	{
		if(maxTrack <= [existingTrack intValue])
		{
			maxTrack = [existingTrack intValue] + 1;
		}
	}
	for(TimelineMarker *marker in markers)
	{
		NSString *categoryName = [self trackNameForMarker:marker];
		NSNumber *trackNumber = [categoryTracks objectForKey:categoryName];
		NSMutableArray *track = [tracks objectForKey:categoryName];
		if(!trackNumber)
		{
			trackNumber = [NSNumber numberWithInteger:maxTrack];
			[categoryTracks setObject:trackNumber forKey:categoryName];
			maxTrack++;
		}
		if(!track)
		{
			track = [NSMutableArray array];
			[tracks setObject:track forKey:categoryName];
		}
		[marker setTrack:[trackNumber intValue]];
		[track addObject:marker];
	}
	durationBarHeight = round([timeline bounds].size.height/(maxTrack + 1));
	if(durationBarHeight < 10)
	{
		durationBarHeight = 10;
	}
	else if(durationBarHeight > 50)
	{
		durationBarHeight = 50;
	}
}

-(BOOL)canDragMarkers
{
	return YES; //[self lineUpCategories];
}

-(BOOL)dragMarker:(TimelineMarker*)marker forDragEvent:(NSEvent*)theEvent
{
	NSPoint curPoint = [timeline convertPoint:[theEvent locationInWindow] fromView:nil];
	
	if([[marker annotation] category] != dragCategory)
	{
		if(lineUpCategories && [[[marker annotation] category] category])
		{
			dragCategory = [[[marker annotation] category] category];
		}
		else
		{
			dragCategory = [[marker annotation] category];
		}
	}
	
	NSInteger targetTrack = (([timeline bounds].size.height - curPoint.y)/durationBarHeight);
	
	if(targetTrack < 0)
	{
		targetTrack = 0;
	}
	
	//curPoint.y = [timeline bounds].size.height - (durationBarHeight * ([marker track] + 1))
	
	if(targetTrack != [marker track])
	{
		NSString *name = [dragCategory name];
		if(!name)
		{
			name = @"";
		}
		[categoryTracks setObject:[NSNumber numberWithInteger:targetTrack] forKey:name];
		
		if(!([theEvent modifierFlags] & NSAlternateKeyMask))
		{
			
		
		//Shift other markers down
		for(NSString *key in [categoryTracks allKeys])
		{
			NSNumber *value = [categoryTracks objectForKey:key];
			if(([value intValue] == targetTrack) && ![key isEqualToString:[dragCategory name]])
			{
				[categoryTracks setObject:[NSNumber numberWithInteger:[marker track]] forKey:key];
			}
		}
		}
		[self updateMarkers];
		return YES;
	}
	
	
	return NO;
}


-(BOOL)updateMarkers
{
    minMarkerY = 0;
	[self sortMarkers];
	BOOL returnVal = [super updateMarkers];
    
    
    if(minMarkerY < 0)
    {
        if (!overflowLayer)
        {
            overflowLayer = [[CALayer layer] retain];
            [[timeline annotationsLayer] addSublayer:overflowLayer];
        }
		[overflowLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
		CGRect graphFrame = NSRectToCGRect([timeline bounds]);
        graphFrame.origin.y = -5;
		[overflowLayer setFrame:graphFrame];
		[overflowLayer setDelegate:self];
		[overflowLayer setNeedsDisplay];
    }
    else if (overflowLayer)
    {
        [overflowLayer removeFromSuperlayer];
        [overflowLayer release];
        overflowLayer = nil;
    }
    
    return returnVal;
}

-(void)updateMarker:(TimelineMarker*)marker
{	
	SegmentBoundary *segment = [marker boundary];
	NSString *trackName = [self trackNameForMarker:marker];
	NSArray* track = [tracks objectForKey:trackName]; 
	NSUInteger trackIndex = 0;
	
	if([markers containsObject:marker])
	{
		NSNumber *trackNumber = [categoryTracks objectForKey:trackName];
		if(!trackNumber)
		{
			//[self sortMarkers];
			[self updateMarkers];
			return;
		}
		if([trackNumber intValue] != [marker track]) 
		{
			[marker setTrack:[trackNumber intValue]];
		}
	}
	
	if(drawLabels && ![marker isDuration])
	{
		trackIndex = [track indexOfObject:marker];
	}
	
	CMTimeRange range = [timeline range];
	NSTimeInterval rangeDuration;
	NSTimeInterval rangeStart;
	rangeDuration = CMTimeGetSeconds(range.duration);
	rangeStart = CMTimeGetSeconds(range.start);
	float movieTimeToPixel = [timeline bounds].size.width/rangeDuration;
	
	BOOL alternate = NO;
	NSRect rect;
	NSBezierPath *path = nil;
	NSTimeInterval startTime;
	startTime = CMTimeGetSeconds([segment time]);
	if([marker isDuration])
	{
		NSTimeInterval endTime;
		endTime = CMTimeGetSeconds([[marker annotation] endTime]);
		
		
		CGFloat start = (startTime - rangeStart) * movieTimeToPixel;
		CGFloat end = (endTime - rangeStart) * movieTimeToPixel;
		if(end < start)
		{
			CGFloat starttemp = start;
			start = end;
			end = starttemp;
		}
		if(end - start < 1)
		{
			end += 2;
		}
		rect = NSMakeRect(start,0,round(end - start),durationBarHeight);
		path = [[NSBezierPath bezierPathWithRect:rect] retain];
	}
	else
	{
		CGFloat height;
		CGFloat y;
		
		if(drawLabels && (durationBarHeight > 32))
		{
			height = durationBarHeight/2.0;
			alternate = fmod(trackIndex,2);
			if(alternate)
			{
				y = height;
			}
			else
			{
				y = 0;
			}
			
		}
		else
		{
			height = durationBarHeight;
			y =  0;
		}
        
		CGFloat start = (startTime - rangeStart) * movieTimeToPixel;
		CGFloat radius = (height - 2.1)/2.0f;
        CGFloat x = start - (annotationRadius);
        if((CMTimeCompare(CMTimeRangeGetEnd([timeline range]), [[timeline movie] duration]) != NSOrderedAscending)
           && ((x + (annotationRadius * 2.0)) > [timeline bounds].size.width))
        {
            x = ([timeline bounds].size.width - (annotationRadius * 2.0));
        }
        
		rect = NSMakeRect(x,
						  y,
						  annotationRadius *2,
						  height);
		NSRect zeroedRect = NSMakeRect(1, 
									   1,
									   (annotationRadius * 2) - 2.0,
									   radius*2);
		path = [[NSBezierPath bezierPathWithRoundedRect:zeroedRect xRadius:4 yRadius:4] retain];
	}
	
	[marker setPath:path];
	[path release];
	
	// Layer Setup
	
    
//	if(CGRectIsNull(CGRectIntersection([timeline annotationsLayer].bounds, NSRectToCGRect(rect))))
//	{
//		[[marker layer] setHidden:YES];
//	}
//	else
//	{
    CALayer *base = [trackLayers objectForKey:trackName];
    if(!base)
    {
        base = [CALayer layer];
        //[base setMasksToBounds:YES];
        [trackLayers setObject:base forKey:trackName];
        [[timeline annotationsLayer] addSublayer:base];
    }
    
    CGRect frame;
    frame.size.width = [timeline bounds].size.width;
    frame.size.height = durationBarHeight;
    frame.origin.y = [timeline bounds].size.height - (durationBarHeight * ([marker track] + 1));
    frame.origin.x = 0;
    [base setFrame:frame];
    
    minMarkerY = fmin(minMarkerY,frame.origin.y);
    
    if((frame.origin.y + durationBarHeight) < 0)
    {
        [base setHidden:YES];
    }
    else
    {
        [base setHidden:NO];
        
		CALayer *layer = [marker layer];
		if(layer == nil)
		{
			layer = [CALayer layer];
			[marker setLayer:layer];
            if([marker isDuration] && [[base sublayers] count])
            {
                [base insertSublayer:layer below:[[base sublayers] objectAtIndex:0]];
            }
			else
			{
				[base addSublayer:layer];
			}
			
			if([marker isDuration])
			{
				[layer setEdgeAntialiasingMask:0];
			}
		}
		else
		{
			if([layer superlayer] != base)
			{
				[layer removeFromSuperlayer];
				[base addSublayer:layer];
			}
			
			[[[layer sublayers] objectAtIndex:0] removeFromSuperlayer];
		}
		
		[layer setHidden:NO];
		[layer setFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
		if(drawLabels && (rect.size.height > 16))
		{
			if([marker isDuration])
			{
				if(rect.size.width > 5)
				{
					
					CATextLayer *labelLayer = [CATextLayer layer];
					labelLayer.anchorPoint = CGPointMake(0,0);
					labelLayer.font = @"Helvetica-Bold";
					if([[marker annotation] source] != nil)
					{
						labelLayer.fontSize = 12.0;
						labelLayer.frame = CGRectMake(1,1,layer.bounds.size.width - 2,layer.bounds.size.height - 2);
						//labelLayer.wrapped = YES;
						labelLayer.truncationMode = kCATruncationMiddle;
					}
					else
					{
						labelLayer.fontSize = 14.0;
						//labelLayer.frame = CGRectMake(3,0,layer.bounds.size.width - 5,16);
						labelLayer.frame = CGRectMake(3,1,layer.bounds.size.width - 5,layer.bounds.size.height - 2);
						labelLayer.wrapped = NO;
						labelLayer.truncationMode = kCATruncationEnd;
					}
					
					NSColor *backgroundColor = [[marker annotation] colorObject];
					
					float brightness = 0.5;
					
					if([[backgroundColor colorSpaceName] isEqualToString:NSDeviceRGBColorSpace]
					   || [[backgroundColor colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace])
					{
						brightness = [backgroundColor brightnessComponent];
					}
					
					
					if((brightness > 0.7) || [timeline whiteBackground])
					{
						labelLayer.foregroundColor = CGColorGetConstantColor(kCGColorBlack);
					}
					else
					{
						labelLayer.foregroundColor = CGColorGetConstantColor(kCGColorWhite);
					}
					
					labelLayer.string = [[marker annotation] annotation];
					[layer addSublayer:labelLayer];
				}
			}
			else
			{
				CGFloat distance;
				
				int nextIndex;
				if(durationBarHeight > 32)
				{
					nextIndex = trackIndex + 2;
				}
				else
				{
					nextIndex = trackIndex + 1;	
				}
				
				if(nextIndex < [track count])
				{
					TimelineMarker *nextMarker = [track objectAtIndex:nextIndex];	
					distance = [nextMarker layer].frame.origin.x - rect.origin.x;	
				}
				else
				{
					distance = [timeline bounds].size.width - rect.origin.x;
				}
				
				if(distance > 30)
				{
					CATextLayer *labelLayer = [CATextLayer layer];
					labelLayer.anchorPoint = CGPointMake(0,0);
					labelLayer.frame = CGRectMake(10,0,distance - 10,16);
					labelLayer.fontSize = 14.0;
					labelLayer.font = @"Helvetica-Bold";
					labelLayer.truncationMode = kCATruncationEnd;
					labelLayer.string = [[marker annotation] annotation];
                    if([timeline whiteBackground])
                    {
                        labelLayer.foregroundColor = CGColorGetConstantColor(kCGColorBlack);
                    }
					[layer addSublayer:labelLayer];
				}
			}
		}
		
		
		[layer setDelegate:marker];
		[layer setNeedsDisplay];
		
		// Tracking area setup
		
		NSTrackingArea *ta;
		ta = [[NSTrackingArea alloc] initWithRect:NSRectFromCGRect([[timeline annotationsLayer] convertRect:layer.frame fromLayer:base])
										  options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow) 
											owner:marker 
										 userInfo:nil];
		if([marker trackingArea])
		{
			[timeline removeTrackingArea:[marker trackingArea]];
		}
		[marker setTrackingArea:ta];
		[timeline addTrackingArea:ta];
		[ta release];
		
	}
	
	//	if(marker.selected)
	//	{
	//		[timeline setSelected:marker];
	//	}
}


-(void)drawMarker:(TimelineMarker*)marker
{
	Annotation* annotation = [marker annotation];
	
	NSColor *backgroundColor = [annotation colorObject];
	if(!backgroundColor)
	{
		backgroundColor = [NSColor grayColor];
	}
	
	CGFloat defaultLineWidth = [NSBezierPath defaultLineWidth];
	
	if([marker isDuration])
	{
		CGRect layerBounds = [marker layer].bounds;
		layerBounds.size.height = durationBarHeight;
		[marker layer].bounds = layerBounds;
		NSRect border = NSMakeRect(layerBounds.origin.x, layerBounds.origin.y, layerBounds.size.width, layerBounds.size.height);
		
		if([marker backgroundColor] != backgroundColor)
		{
			[marker setBackgroundColor:backgroundColor];
			CGColorRef annColor = [backgroundColor createCGColor];
			//CGFloat components[] = {0.0,0.0,1.0,1.0};
			//CGColorRef annColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
			[marker layer].backgroundColor = annColor;
			CGColorRelease(annColor);
		}
		
		if([marker selected])
		{
			[NSBezierPath setDefaultLineWidth:5.0];
			[marker layer].shadowRadius = 5;
			[marker layer].shadowOpacity = 0.5;
		}
		else if([marker highlighted])
		{
			[NSBezierPath setDefaultLineWidth:2.0];
			[marker layer].shadowRadius = 0;
			[marker layer].shadowOpacity = 0;
		}
		else
		{
			[NSBezierPath setDefaultLineWidth:1.0];
			[marker layer].shadowRadius = 0;
			[marker layer].shadowOpacity = 0;
		}
		
		if([marker highlighted] || [marker selected])
		{
			[[NSColor whiteColor] set];
			[NSBezierPath strokeRect:border];
		} else {
			[[NSColor blackColor] set];
			[NSBezierPath strokeRect:border];
		}
	}
	else
	{
		[backgroundColor set];
		[[marker path] fill];
		
		if([marker selected])
		{
			[[marker path] setLineWidth:3.0f];
			[marker layer].shadowRadius = 5;
			[marker layer].shadowOpacity = 0.5;
			
		}
		else
		{
			[[marker path] setLineWidth:1.0f];
			[marker layer].shadowRadius = 0;
			[marker layer].shadowOpacity = 0;
		}
		
		if([marker highlighted] || [marker selected]) {
			[[NSColor whiteColor] set];
			[[marker path] stroke];
		} else {
			[[NSColor blackColor] set];
			[[marker path] stroke];
		}
	}
	
	
	[NSBezierPath setDefaultLineWidth:defaultLineWidth];
	
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    NSGradient *backgroundGradient = [[NSGradient alloc] initWithColorsAndLocations:
                                      [NSColor colorWithDeviceWhite:0.5 alpha:0],0.0,
                                      [NSColor colorWithDeviceWhite:0.5 alpha:0],0.7,
                                      [NSColor colorWithDeviceWhite:0.0 alpha:1],0.95,
                                      [NSColor colorWithDeviceWhite:0.0 alpha:1],1.0,nil];
    
    //NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.5 alpha:0]
    //                                                               endingColor:[NSColor colorWithDeviceWhite:0.0 alpha:1]];
    
    CGRect boundingBox = CGContextGetClipBoundingBox(ctx);
    //NSLog(@"Draw layer in context: width %f, x coord %f",boundingBox.size.width,boundingBox.origin.x);
    //NSLog(@"Draw Layer");
    NSGraphicsContext *nsGraphicsContext;
    nsGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx
                                                                   flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:nsGraphicsContext];
    
    //NSRect bounds = [self bounds];
    NSRect bounds = NSRectFromCGRect(boundingBox);
    
    //NSLog(@"draw background");
    [backgroundGradient drawInRect:bounds angle:270];
    
    [NSGraphicsContext restoreGraphicsState];
	
    [backgroundGradient release];
}


@end
