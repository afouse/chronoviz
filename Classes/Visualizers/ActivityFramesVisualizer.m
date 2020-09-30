//
//  ActivityFramesVisualizer.m
//  ChronoViz
//
//  Created by Adam Fouse on 6/14/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "ActivityFramesVisualizer.h"
#import "DPActivityLog.h"
#import "NSImage-Extras.h"
#import "AnnotationDocument.h"
#import "ActivityFramesConfigurationController.h"

@interface ActivityFramesVisualizer (Updating)

- (void)activityUpdated:(NSNotification*)notification;

@end

@implementation ActivityFramesVisualizer

static void drawPatternImage (void *info, CGContextRef ctx)
{
    CGImageRef image = (CGImageRef) info;
    CGContextDrawImage(ctx, 
                       CGRectMake(0,0, CGImageGetWidth(image),CGImageGetHeight(image)),
                       image);
}

// callback for CreateImagePattern.
static void releasePatternImage( void *info )
{
    CGImageRelease((CGImageRef)info);
}


-(id)initWithTimelineView:(TimelineView*)timelineView
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{
		activityMaskImage = [[NSImage imageNamed:@"activityMaskImage"] cgImage];
		bins = [[NSMutableDictionary alloc] init];
        configurationController = nil;
        visMethod = 1;
	}
	return self;
}

- (void) dealloc
{
    [configurationController release];
	CGImageRelease(activityMaskImage);
	[bins release];
	self.activityLog = nil;
	[super dealloc];
}

- (DPActivityLog*)activityLog
{
	return activityLog;
}

- (void)setActivityLog:(DPActivityLog*)log
{
	if(activityLog)
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[log retain];
	[activityLog release];
	activityLog = log;
	
	if(activityLog)
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(activityUpdated:)
													 name:DPActivityLogUpdateNotification
												   object:activityLog];
}

- (void)activityUpdated:(NSNotification*)notification
{
	[self updateActivityLayer];
}
	 
-(void)setup
{
    if(!activityLog)
    {
        [self setActivityLog:[[AnnotationDocument currentDocument] activityLog]];
    }
	if(!activityLayer)
	{
		activityLayer = [[CALayer layer] retain];
		[activityLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
		[activityLayer setPosition:CGPointMake(0.0,-1.0)];
		[activityLayer setBounds:NSRectToCGRect([timeline bounds])];
		//[activityLayer setDelegate:self];
		[activityLayer setShadowOpacity:0.5];
		activityLayer.autoresizingMask = (kCALayerHeightSizable | kCALayerWidthSizable);
		
		//assume image is the CGImage you want to assign as the layer background
		int width = CGImageGetWidth(activityMaskImage);
		int height = CGImageGetHeight(activityMaskImage);
		static const CGPatternCallbacks callbacks = {0, &drawPatternImage, &releasePatternImage};
		CGPatternRef pattern = CGPatternCreate (activityMaskImage,
												CGRectMake (0, 0, width, height),
												CGAffineTransformMake (1, 0, 0, 1, 0, 0),
												width,
												height,
												kCGPatternTilingConstantSpacing,
												true,
												&callbacks);
		CGColorSpaceRef space = CGColorSpaceCreatePattern(NULL);
		CGFloat components[1] = {1.0};
		CGColorRef color = CGColorCreateWithPattern(space, pattern, components);
		CGColorSpaceRelease(space);
		CGPatternRelease(pattern);
		activityLayer.backgroundColor = color; //set your layer's background to the image
		CGColorRelease(color);
		
		activityLayerMask = [[CALayer layer] retain];
		[activityLayerMask setAnchorPoint:CGPointMake(0.0, 0.0)];
		[activityLayerMask setFrame:NSRectToCGRect([timeline bounds])];
		[activityLayerMask setDelegate:self];
		activityLayerMask.autoresizingMask = (kCALayerHeightSizable | kCALayerWidthSizable);
		[activityLayer setMask:activityLayerMask];
		
		framesLayer = [[CALayer layer] retain];
		[framesLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
		[framesLayer setFrame:NSRectToCGRect([timeline bounds])];
		//framesLayer.backgroundColor = CGColorCreateGenericRGB(1.0, 0, 0, 1.0);
		framesLayer.autoresizingMask = (kCALayerHeightSizable | kCALayerWidthSizable);
		
		[[timeline visualizationLayer] setMasksToBounds:YES];
		[[timeline visualizationLayer] addSublayer:framesLayer];
		[[timeline visualizationLayer] addSublayer:activityLayer];
		//[activityLayer setNeedsDisplay];
		//[framesLayer setNeedsDisplay];
		
		[self updateActivityLayer];
	}
	[super setup];
}

-(CALayer*)visualizationLayer
{
	if(!framesLayer)
	{
		[self setup];
	}
	return framesLayer;
}

- (void)setVisualizationMethod:(NSInteger)method
{
    visMethod = method;
    [self updateActivityLayer];
}

- (void)updateActivityLayer
{
	if(!activityLayer)
	{
		[self setup];
		return;
	}
	
	//CGFloat timelineWidth = [timeline bounds].size.width;
	
	CMTimeRange range = [timeline range];
	NSTimeInterval rangeDuration;
	NSTimeInterval rangeStart;
	rangeDuration = CMTimeGetSeconds(range.duration);
	rangeStart = CMTimeGetSeconds(range.start);
	//CGFloat pixelToMovieTime = rangeDuration/timelineWidth;
	CGFloat movieTimeToPixel = [timeline bounds].size.width/rangeDuration;
	
	int totalBins = self.activityLog.numberOfBins;
	CGFloat binDuration = self.activityLog.documentDuration/(float)totalBins;
	
	//int numberOfBins = ceil(rangeDuration/binDuration);
	
	//CGFloat binWidth = timelineWidth/numberOfBins;
	
	[bins removeAllObjects];
	NSTimeInterval time;
	for(time = rangeStart; time < (rangeStart + rangeDuration); time += binDuration)
	{		
		CGFloat beginX = floor((time - rangeStart) * movieTimeToPixel);
		CGFloat endX = floor(((time + binDuration) - rangeStart) * movieTimeToPixel);
		
		//NSLog(@"Begin: %f End: %f",beginX,endX);
		
		
		// Set up segment border
		NSRect rect = NSMakeRect(beginX, 
								 0,
								 endX - beginX,
								 [timeline bounds].size.height);
		
		[bins setObject:[NSNumber numberWithFloat:[self.activityLog scoreForSeconds:time withMethod:visMethod]]
				 forKey:[NSValue valueWithRect:rect]];
	
	}
	
	[activityLayerMask setNeedsDisplay];
	[activityLayer setNeedsDisplay];
	
	/*
	CGContextRef    context = NULL;
	CGColorSpaceRef colorSpace;
	int bitmapBytesPerRow;
	
	int pixelsHigh = (int)[activityLayer bounds].size.height;
	int pixelsWide = (int)[activityLayer bounds].size.width;
	
	bitmapBytesPerRow   = (pixelsWide * 4);
	
	colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	
	context = CGBitmapContextCreate (NULL,
									 pixelsWide,
									 pixelsHigh,
									 8,
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGImageAlphaPremultipliedLast);
	if (context== NULL)
	{
		NSLog(@"Failed to create context.");
		return NO;
	}
	
	CGColorSpaceRelease( colorSpace );
	
	if([theView isKindOfClass:[TimelineView class]])
	{
		[[(TimelineView*)theView layer] renderInContext:context];
	}
	else
	{
		[[theView layer] renderInContext:context];
	}
	
	CGImageRef img = CGBitmapContextCreateImage(context);
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:img];
	CFRelease(img);
	*/
	
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	for(NSValue *value in [bins allKeys])
	{
		CGRect rect = NSRectToCGRect([value rectValue]);
		NSNumber *level = [bins objectForKey:value];

		//NSLog(@"Fill rect %f %f with level %f",rect.origin.x,rect.size.width,[level floatValue]);
		
		CGContextSetGrayFillColor(ctx,1.0,1.0 - [level floatValue]);
		CGContextSetGrayStrokeColor(ctx,1.0,1.0 - [level floatValue]);
		CGContextFillRect(ctx, rect);
		//CGContextStrokeRectWithWidth(ctx, rect, 0.9);
	}
}

-(BOOL)updateMarkers
{
	BOOL result = [super updateMarkers];
	if(!result)
	{
		return NO;
	}
	else
	{
		return YES;
//		if([timeline inLiveResize])
//		{
//			for(TimelineMarker *marker in markers)
//			{
//				CGRect bounds = [marker layer].bounds;
//				bounds.size.height = [timeline frame].size.height;
//				//			CGPoint position = [marker layer].position;
//				//			position.y = 0;
//				[marker layer].bounds = bounds;
//			}
//			return YES;
//		}
//		else
//		{
//			return NO;
//		}
	}

}
	

- (void)configureVisualization:(id)sender
{
    [configurationController release];
	ActivityFramesConfigurationController * controller = [[ActivityFramesConfigurationController alloc] initForVisualizer:self];
	[controller showWindow:self];
	[[controller window] makeKeyAndOrderFront:self];
	configurationController = controller;
}
@end
