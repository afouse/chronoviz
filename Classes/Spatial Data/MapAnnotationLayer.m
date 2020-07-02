//
//  MapAnnotationLayer.m
//  Annotation
//
//  Created by Adam Fouse on 10/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MapAnnotationLayer.h"
#import "Annotation.h"
#import "MapView.h"
#import "TimeCodedGeographicPoint.h"
#import "NSColorCGColor.h"

@implementation MapAnnotationLayer

@synthesize annotationLayer;
@synthesize indicatorLayer;
@synthesize annotationPath;
@synthesize mapView;

-(id)initWithAnnotation:(Annotation*)theAnnotation
{
	self = [super init];
	if(self != nil)
	{
		annotation = [theAnnotation retain];
		
			
//		[[NSNotificationCenter defaultCenter] addObserver:self
//												 selector:@selector(select)
//													 name:AnnotationSelectedNotification
//												   object:annotation];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(update)
													 name:AnnotationUpdatedNotification
												   object:annotation];

		[self setAnnotationLayer:[CALayer layer]];
		[self setIndicatorLayer:nil];
		
		[self setAnnotationPath:[NSBezierPath bezierPath]];
		
	}
	return self;
}

- (void) dealloc
{
	[annotation release];
	[annotationLayer release];
	[indicatorLayer release];
	[annotationPath release];
	[super dealloc];
}

- (void)update
{
	if(mapView && [annotation isDuration])
	{
		[annotationLayer setFrame:NSRectToCGRect([mapView bounds])];
		
		float spanLat = [mapView maxLat] - [mapView minLat];
		float spanLon = [mapView maxLon] - [mapView minLon];
		
		float latToPixel = [mapView bounds].size.height/spanLat;
		float lonToPixel = [mapView bounds].size.width/spanLon;
		
		[annotationPath removeAllPoints];
		
		[annotationPath setLineJoinStyle:NSRoundLineJoinStyle];
		
		BOOL drawLine = NO;
		for(TimeCodedGeographicPoint *point in [mapView displayedData])
		{
			if(CMTIME_COMPARE_INLINE([point time], >, [annotation endTime]))
			{
				break;
			}
			else if(drawLine)
			{
				[annotationPath lineToPoint:NSMakePoint(([point lon] - [mapView minLon]) * lonToPixel, 
														([point lat] - [mapView minLat]) * latToPixel)];
			}
			else if(CMTIME_COMPARE_INLINE([point time], >, [annotation startTime]))
			{
				[annotationPath moveToPoint:NSMakePoint(([point lon] - [mapView minLon]) * lonToPixel, 
														([point lat] - [mapView minLat]) * latToPixel)];
				drawLine = YES;
			}
		}
		
		[annotationLayer setOpacity:0.5];
		[annotationLayer setDelegate:self];
		
		if(!indicatorLayer)
		{
			indicatorLayer = [[CALayer layer] retain];
			[indicatorLayer setBounds:CGRectMake(0, 0, 10, 10)];
			[indicatorLayer setCornerRadius:3.5];
			CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
			CGFloat components[4] = {0.2f, 0.2f, 0.8f, 0.5f};
			CGColorRef blueColor = CGColorCreate(colorSpace, components);
			[indicatorLayer setBackgroundColor:blueColor];
			[annotationLayer addSublayer:indicatorLayer];
		}

		[annotationLayer setNeedsDisplay];	
		
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
	
	[[annotation colorObject] set];
	[annotationPath setLineWidth:6.0];
	[annotationPath stroke];
	
	[indicatorLayer setBackgroundColor:[[annotation colorObject] createCGColor]];
	[indicatorLayer setBorderColor:CGColorCreateGenericGray(0.1, 1.0)];
	[indicatorLayer setBorderWidth:1.5];
	
	[NSGraphicsContext restoreGraphicsState];
	
	[CATransaction commit];
}

-(Annotation*)annotation
{
	return annotation;
}

@end
