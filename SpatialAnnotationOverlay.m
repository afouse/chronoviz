//
//  SpatialAnnotationOverlay.m
//  DataPrism
//
//  Created by Adam Fouse on 8/21/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "SpatialAnnotationOverlay.h"
#import "NSImage-Extras.h"

@interface SpatialAnnotationOverlay (SetupMethods)

- (void)createLayers;

@end

@implementation SpatialAnnotationOverlay

-(id)initForView:(NSView<AnnotationView>*)view 
{
	if(view)
	{
		self = [super initWithFrame:[view frame]];
		if (self) {
			[self setWantsLayer:YES];
			annotationView = view;
			overlayLayer = nil;
			toolLayer = nil;
			
			[view addSubview:self];
			
			[self createLayers];
		}
		return self;
	}
	return nil;
}

-(void)showOverlay
{
	[self setFrame:[[self superview] frame]];
	
	if(!overlayLayer || !toolLayer)
	{
		[self createLayers];
	}
	
	[self setHidden:NO];
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	[[self layer] setPosition:CGPointZero];
	
	CABasicAnimation *theAnimation;
	
	theAnimation=[CABasicAnimation animationWithKeyPath:@"position.y"];
	theAnimation.duration=1.0;
	theAnimation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	//theAnimation.removedOnCompletion=NO;
	//theAnimation.toValue=[NSNumber numberWithFloat:0.0];
	[[self layer] addAnimation:theAnimation forKey:@"animatePositionY"];
	[CATransaction commit];
	[self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
}

-(void)hideOverlay
{
	[self setAutoresizingMask:NSViewNotSizable];
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	[[self layer] setPosition:CGPointMake(0.0,[annotationView frame].size.height)];
	
	CABasicAnimation *theAnimation;
	
	theAnimation=[CABasicAnimation animationWithKeyPath:@"position.y"];
	theAnimation.duration=1.0;
	theAnimation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	[[self layer] addAnimation:theAnimation forKey:@"animatePositionY"];
	[CATransaction commit];
}

-(void)createLayers
{
	CALayer *baseLayer = [self layer];
	baseLayer.anchorPoint = CGPointMake(0.0, 0.0);
	//baseLayer.backgroundColor = CGColorCreateGenericRGB(1.0, 0, 0, 0.5);
	
	[overlayLayer removeFromSuperlayer];
	[toolLayer removeFromSuperlayer];
	[overlayLayer release];
	[toolLayer release];
	
	overlayLayer = [[CALayer layer] retain];
	overlayLayer.frame = baseLayer.frame;
	//overlayLayer.backgroundColor = CGColorCreateGenericGray(0.1, 0.2);
	overlayLayer.backgroundColor = CGColorCreateGenericRGB(0.5, 0, 0, 0.5);
	overlayLayer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
	
	toolLayer = [[CALayer layer] retain];
	toolLayer.anchorPoint = CGPointMake(0.0,1.0);
	toolLayer.bounds = CGRectMake(0, 0, 20, 20);
	toolLayer.position = CGPointMake(5.0,baseLayer.frame.size.height - 5.0);
	toolLayer.autoresizingMask = kCALayerMinYMargin;
	toolLayer.cornerRadius = 5.0;
	toolLayer.backgroundColor = CGColorCreateGenericGray(0.8, 0.8);
	toolLayer.shadowOpacity = 0.5;
	
	NSImage* actionNSImage = [NSImage imageNamed:NSImageNameStopProgressTemplate];
	CGImageRef actionImage = [actionNSImage cgImage];
	
	toolLayer.contentsGravity		= kCAGravityCenter;
	toolLayer.contents = (id)actionImage;
	
	[baseLayer addSublayer:overlayLayer];
	[baseLayer addSublayer:toolLayer];
	
	baseLayer.position = CGPointMake(0,[annotationView frame].size.height);
	
	[CATransaction flush];
}



- (void)mouseDown:(NSEvent*)theEvent
{
	NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	if([toolLayer containsPoint:[toolLayer convertPoint:NSPointToCGPoint(pt) fromLayer:[self layer]]])
	{
		[self hideOverlay];
	}
	else
	{
		selectionStart = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	}
	
	
	//[annotationView mouseDown:theEvent];
}

- (void)mouseDragged:(NSEvent*)theEvent
{
	NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	selection = NSMakeRect(fmin(pt.x,selectionStart.x),fmin(pt.y,selectionStart.y),fabs(pt.x - selectionStart.x),fabs(pt.y - selectionStart.y));
	
	if(!selectionLayer)
	{
		selectionLayer = [[CALayer layer] retain];
		selectionLayer.backgroundColor = CGColorCreateGenericGray(0.5, 0.2);
		selectionLayer.borderColor = CGColorCreateGenericGray(1.0, 0.9);
		selectionLayer.borderWidth = 2.0;
		[overlayLayer addSublayer:selectionLayer];
	}
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];

	selectionLayer.frame = NSRectToCGRect(selection);
	
	[CATransaction commit];
}


@end
