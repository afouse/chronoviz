//
//  SegmentDualVisualizer.m
//  Annotation
//
//  Created by Adam Fouse on 6/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SegmentDualVisualizer.h"
#import "Annotation.h"
#import "VideoProperties.h"
#import "AnnotationCategory.h"
#import "NSColorCGColor.h"

@implementation SegmentDualVisualizer

-(id)initWithTimelineView:(TimelineView*)timelineView
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{
		NSArray* array = [NSArray arrayWithObjects:
						  [NSColor colorWithDeviceWhite:0.2 alpha:0.5],
						  [NSColor colorWithDeviceRed:1.0 green:0.914 blue:.651 alpha:0.8],
						  [NSColor colorWithDeviceWhite:0.2 alpha:0.5],
						  nil];
		segmentHighlightedGradient = [[NSGradient alloc] initWithColors:array];
		
		NSArray* array2 = [NSArray arrayWithObjects:
						   [NSColor colorWithDeviceWhite:0.2 alpha:0.8],
						   [NSColor colorWithDeviceWhite:0.8 alpha:0.1],
						   [NSColor colorWithDeviceWhite:0.2 alpha:0.8],
						   nil];
		segmentGradient = [[NSGradient alloc] initWithColors:array2];
		
		borderColor = [NSColor blackColor];
		
		NSColor *segmentColorA = [NSColor colorWithDeviceWhite:0.3 alpha:1.0];
		NSColor *segmentColorB = [NSColor colorWithDeviceWhite:0.5 alpha:1.0];
		NSColor *segmentHighlightColor = [NSColor colorWithDeviceWhite:0.8 alpha:1.0];
		
		cgSegmentColorA = [segmentColorA createCGColor];
		cgSegmentColorB = [segmentColorB createCGColor];
		cgSegmentColorHighlight = [segmentHighlightColor createCGColor];
		
		annotationRadius = 3;
		durationBarHeight = 10;
		
	}
	return self;
}

-(void)dealloc
{
	[segmentHighlightedGradient release];
	[segmentGradient release];
	CGColorRelease(cgSegmentColorA);
	CGColorRelease(cgSegmentColorB);
	CGColorRelease(cgSegmentColorHighlight);
	[super dealloc];
}

-(void)reset
{
	for(TimelineMarker *marker in markers)
	{
		if([marker trackingArea])
		{
			[timeline removeTrackingArea:[marker trackingArea]];
			[marker setTrackingArea:nil];
		}
	}
	[markers removeAllObjects];
	[super reset];
}

-(TimelineMarker *)addKeyframe:(SegmentBoundary*)keyframe
{
	TimelineMarker *marker = nil;
	
	// Make sure that we only display full annotations
	if([keyframe isMemberOfClass:[Annotation class]])
	{
		marker = [super addKeyframe:keyframe];
		if(marker) {
			[markers addObject:marker];
			[self updateMarker:marker];
		}
	}
	return marker;
}

-(TimelineMarker*)removeSegmentBoundary:(SegmentBoundary*)boundary
{
	TimelineMarker *marker = [super removeSegmentBoundary:boundary];
	if(marker)
	{
		[marker retain];
		[markers removeObject:marker];
		if([marker trackingArea])
		{
			[timeline removeTrackingArea:[marker trackingArea]];
			[marker setTrackingArea:nil];
		}
		[marker autorelease];
	}
	return marker;
}

-(CALayer*)createTempLayer
{
	CALayer *visualizationLayer = [timeline visualizationLayer];
	
	//			NSRect r = [(NSView*)selectedView bounds];
	//            NSData *data = [(NSView*)selectedView dataWithPDFInsideRect:r];
	//            
	//            [data writeToFile:[savePanel filename] atomically:YES];
	
	
	
	CGContextRef    context = NULL;
	CGColorSpaceRef colorSpace;
	//int bitmapByteCount;
	int bitmapBytesPerRow;
	
	int pixelsHigh = (int)[visualizationLayer bounds].size.height;
	int pixelsWide = (int)[visualizationLayer bounds].size.width;
	
	bitmapBytesPerRow   = (pixelsWide * 4);
	//bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
	
	colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	
	context = CGBitmapContextCreate (NULL,
									 pixelsWide,
									 pixelsHigh,
									 8,
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGImageAlphaPremultipliedLast);
    
    CGColorSpaceRelease(colorSpace);
    
	if (context== NULL)
	{
		NSLog(@"Failed to create context.");
		return NO;
	}

	[visualizationLayer renderInContext:context];
	
	CGImageRef img = CGBitmapContextCreateImage(context);
	CALayer *layer = [CALayer layer];
	layer.frame = visualizationLayer.frame;
	layer.contents = (id)img;
	layer.opacity = 0.2;
	CFRelease(img);
	CGContextRelease(context);
	return layer;
}

-(BOOL)updateMarkers
{
	if([timeline inLiveResize] && ([addedSegments count] > 400))
	{
		if(![timeline visualizationLayer].hidden)
		{
			CALayer *tempLayer = [self createTempLayer];
			[[timeline visualizationLayer] setHidden:YES];
			[[timeline visualizationLayer] setValue:tempLayer  forKey:@"DPTempLayer"];
			[[timeline layer] insertSublayer:tempLayer above:[timeline visualizationLayer]];
			[tempLayer setAnchorPoint:CGPointMake(0,0)];
			[tempLayer setPosition:CGPointMake(0,0)];
			[tempLayer setValue:[NSValue valueWithCMTimeRange:[timeline range]] forKey:@"DPTempLayerRange"];
		}

		CALayer *tempLayer = [[timeline visualizationLayer] valueForKey:@"DPTempLayer"];
		//[tempLayer setBounds:[[timeline layer] bounds]];
		
		CMTimeRange imageRange = [[tempLayer valueForKey:@"DPTempLayerRange"] CMTimeRangeValue];
		NSTimeInterval imageStart;
		NSTimeInterval imageDuration;
		imageDuration = CMTimeGetSeconds(imageRange.duration);
		imageStart = CMTimeGetSeconds(imageRange.start);

		CMTimeRange range = [timeline range];
		NSTimeInterval rangeDuration;
		NSTimeInterval rangeStart;
		rangeDuration = CMTimeGetSeconds(range.duration);
		rangeStart = CMTimeGetSeconds(range.start);
		
		float scale = imageDuration/rangeDuration;
		float movieTimeToPixel = [timeline bounds].size.width/rangeDuration;
		
		CGPoint position = tempLayer.position;
		position.x = (imageStart - rangeStart)*movieTimeToPixel;
		tempLayer.position = position;
		
		CGRect vizBounds = NSRectToCGRect([timeline bounds]);
		vizBounds.size.width = vizBounds.size.width * scale;
		tempLayer.bounds = vizBounds;
			

	}
	else
	{
		[[timeline visualizationLayer] setHidden:NO];
		
		CALayer *tempLayer = [[timeline visualizationLayer] valueForKey:@"DPTempLayer"];
		if(tempLayer)
		{
			[tempLayer removeFromSuperlayer];
			[[timeline visualizationLayer] setValue:nil forKey:@"DPTempLayer"];
		}
		
//		NSLog(@"Start markers render");
//		NSDate *date = [NSDate date];
		for(TimelineMarker *marker in addedSegments)
		{
			[self updateMarker:marker];
		}	
//		NSLog(@"End markers render: %f",[date timeIntervalSinceNow]);
	}
	return YES;
}

-(void)updateMarker:(TimelineMarker*)marker
{
	SegmentBoundary *segment = [marker boundary];
	
	CMTimeRange range = [timeline range];
	NSTimeInterval rangeDuration;
	NSTimeInterval rangeStart;
	rangeDuration = CMTimeGetSeconds(range.duration);
	rangeStart = CMTimeGetSeconds(range.start);
	float movieTimeToPixel = [timeline bounds].size.width/rangeDuration;
	
	NSRect rect;
	NSBezierPath *path = nil;
	if([marker isDuration])
	{
		float start = (float)[segment time].value * movieTimeToPixel;
		float end = (float)[[marker annotation] endTime].value * movieTimeToPixel;
		if(end < start)
		{
			float starttemp = start;
			start = end;
			end = starttemp;
		}
		if(end - start < 1)
		{
			start += 1;
		}
		rect = NSMakeRect(start,[timeline bounds].size.height - durationBarHeight,end - start,durationBarHeight);
		path = [[NSBezierPath bezierPathWithRect:rect] retain];
	}
	else
	{
		rect = NSMakeRect(((float)[segment time].value * movieTimeToPixel) - annotationRadius,
						  0,
						  annotationRadius * 2,
						  [timeline bounds].size.height);
		path = [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:2 yRadius:2] retain];
	}
	[marker setPath:path];
	
	int options = NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp;
	NSTrackingArea *ta;
	ta = [[NSTrackingArea alloc] initWithRect:rect options:options owner:marker userInfo:nil];
	if([marker trackingArea])
	{
		[timeline removeTrackingArea:[marker trackingArea]];
	}
	[marker setTrackingArea:ta];
	[timeline addTrackingArea:ta];
	[ta release];
	[path release];

	CALayer *base = [timeline visualizationLayer];
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
	}
	
	[layer setFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
	[layer setDelegate:marker];
	[layer setNeedsDisplay];
	
	if(marker.selected)
	{
		[timeline setSelected:marker];
	}
}

-(void)drawMarker:(TimelineMarker*)marker
{
	CGRect layerBounds = [marker layer].bounds;
	NSRect border = NSMakeRect(layerBounds.origin.x, layerBounds.origin.y, layerBounds.size.width, layerBounds.size.height);
	Annotation* annotation = [marker annotation];
	
	NSColor *backgroundColor;
	if([annotation category]) 
	{
		backgroundColor = [[annotation category] color];
	}
	else
	{
		backgroundColor = [NSColor whiteColor];
	}
	CGColorRef annColor = [backgroundColor createCGColor];
	[marker layer].backgroundColor = annColor;
	CGColorRelease(annColor);
	
	if([marker isDuration])
	{
		CGRect layerBounds = [marker layer].bounds;
		layerBounds.size.height = durationBarHeight;
		[marker layer].bounds = layerBounds;
		NSRect border = NSMakeRect(layerBounds.origin.x, layerBounds.origin.y, layerBounds.size.width, layerBounds.size.height);
		if([marker highlighted])
		{
			[[NSColor whiteColor] set];
			[NSBezierPath strokeRect:border];
		} else if([annotation color]) {
			NSColor *color;
			if([annotation category])
			{
				color = [[annotation category] color];
			}
			else
			{
				color = [Annotation colorForString:[annotation color]];
			}
			CGColorRef annColor = [color createCGColor];
			[marker layer].backgroundColor = annColor;
			CGColorRelease(annColor);
			[[NSColor blackColor] set];
			[NSBezierPath strokeRect:border];
		} else{
			[marker layer].backgroundColor = cgSegmentColorA;
			[[NSColor blackColor] set];
			[NSBezierPath strokeRect:border];
		}
	}
	else
	{
		if([marker highlighted]) {
			
			
			[segmentHighlightedGradient drawInRect:border angle:0];
		} else {
			[segmentGradient drawInRect:border angle:0];
		}
	}
	if([marker selected])
	{
		[marker layer].shadowOpacity = 0.5;
	} else {
		[marker layer].shadowOpacity = 0;
	}
	
}

@end
