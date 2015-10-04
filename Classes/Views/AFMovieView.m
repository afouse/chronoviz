//
//  AFMovieView.m
//  Annotation
//
//  Created by Adam Fouse on 2/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AFMovieView.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "VideoProperties.h"
#import "MovieViewerController.h"
#import "Annotation.h"
#import "DPConstants.h"
#import <QuartzCore/CoreAnimation.h>

@interface AFMovieView (LayerManagement)

- (void)setup;
- (QTMovieLayer*)createLayerForMovie:(QTMovie*)movie;
- (CALayer*)createControlLayerForMovieLayer:(QTMovieLayer*)movieLayer;
- (void)updateEnabledStatusForVideoProperties:(VideoProperties*)properties;
- (void)frameDidChange;
- (void)sizeMovieLayers;
- (void)sizeMovieLayersWithAnimation:(BOOL)animate;

@end

NSString * const DPVideoWidthPercentage = @"DPVideoWidthPercentage";

@implementation AFMovieView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		setup = NO;
		movies = nil;
		movieLayers = nil;
		resizeMovieIndex = 0;
		activeControlLayer = nil;
    }
    return self;
}

- (void)awakeFromNib
{
	[self setup];
}

- (void)setup
{
	if(!setup)
	{
		setup = YES;
		
		movies = [[NSMutableArray alloc] init];
		movieLayers = [[NSMutableArray alloc] init];
		controlLayers = [[NSMutableSet alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(frameDidChange)
													 name:NSViewFrameDidChangeNotification
												   object:self];
		
		
		if(![[[self window] windowController] isKindOfClass:[MovieViewerController class]])
		{
			NSArray *dragTypes = [NSArray arrayWithObject:DPVideoPropertiesPasteboardType];
			[self registerForDraggedTypes:dragTypes];	
		}
		
		[self setLayer:[[CALayer new] autorelease]];
		[self setWantsLayer:YES];
		[[self layer] setBackgroundColor:CGColorCreateGenericGray(0.05, 1.0)];
		
        self.layerUsesCoreImageFilters = true;
        
		controlBackground = CGColorCreateGenericGray(0.8, 0.5);
		controlBackgroundActive = CGColorCreateGenericGray(0.8, 1.0);
		
		CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
		[filter setDefaults];
		[filter setValue:[NSNumber numberWithFloat:0.0] forKey:@"inputSaturation"];
		inactiveVideoFilters = [[NSArray alloc] initWithObjects:filter,nil];
		
		magnifyCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"MagnifyingGlassGray.png"]
												hotSpot:NSMakePoint(7, 10)];
	}
}

- (void) dealloc
{
    
    NSArray *moviesTemp = [movies copy];
    for(QTMovie *movie in moviesTemp)
    {
        [self removeMovie:movie];
    }
    [moviesTemp release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[magnifyCursor release];
	[movies release];
    
//    for(CALayer *movieLayer in movieLayers)
//    {
//        VideoProperties *properties = [movieLayer valueForKey:@"DPVideoProperties"];
//        [properties removeObserver:self forKeyPath:@"enabled"];
//    }
    
	[movieLayers release];
	[controlLayers release];
	[inactiveVideoFilters release];
	CGColorRelease(controlBackground);
	CGColorRelease(controlBackgroundActive);
	[super dealloc];
}

- (void)setLocalControl:(MovieViewerController*)controller
{
	localController = controller;
}

- (void)setMovie:(QTMovie*)movie
{	
	for(QTMovieLayer *layer in movieLayers)
	{
		[layer removeFromSuperlayer];
	}
	[movies removeAllObjects];
	[movieLayers removeAllObjects];
	[controlLayers removeAllObjects];
	
	[self addMovie:movie];
}


- (void)addMovie:(QTMovie*)movie
{
    if(![movies containsObject:movie])
    {
        [self setup];
        [movies addObject:movie];
        QTMovieLayer *layer = [self createLayerForMovie:movie];
        
        float newPercentage = (float)[movieLayers count]/(float)([movieLayers count] + 1);
        for(CALayer *movieLayer in movieLayers)
        {
            NSNumber *oldPercentage = [movieLayer valueForKey:DPVideoWidthPercentage];
            if(oldPercentage)
            {
                [movieLayer setValue:[NSNumber numberWithFloat:(newPercentage * [oldPercentage floatValue])] forKey:DPVideoWidthPercentage];
            }
        }
        
        [movieLayers addObject:layer];
        [[self layer] addSublayer:[layer superlayer]];
        
        [self createControlLayerForMovieLayer:layer];
        
        [self sizeMovieLayers];
    }
}

- (void)removeMovie:(QTMovie*)movie
{
	NSUInteger index = [movies indexOfObject:movie];
	if(index != NSNotFound)
	{
        VideoProperties *properties = [[movieLayers objectAtIndex:index] valueForKey:@"DPVideoProperties"];
        [properties removeObserver:self forKeyPath:@"enabled"];
        
		CALayer *controlLayer = [[movieLayers objectAtIndex:index] valueForKey:@"DPControlLayer"];
		if(controlLayer)
		{
			[controlLayers removeObject:controlLayer];
		}
		
		[(CALayer*)[movieLayers objectAtIndex:index] removeFromSuperlayer];
		[movieLayers removeObjectAtIndex:index];
		[movies removeObjectAtIndex:index];
		[self sizeMovieLayers];
	}
}

- (void)toggleMute:(id)sender
{
	QTMovie *movie = [sender representedObject];
	if(movie)
	{
		[movie setMuted:![movie muted]];
	}
}

- (QTMovie*)movie
{
	if([movies count] > 0)
	{
		return [movies objectAtIndex:0];
	}
	else
	{
		return nil;
	}
}

- (NSArray*)movies
{
	return [[movies copy] autorelease];
}

- (void)zoomInMovie:(QTMovie*)movie
{
	NSUInteger index = [movies indexOfObject:movie];
	if(index != NSNotFound)
	{
		CALayer *layer = (CALayer*)[movieLayers objectAtIndex:index];
		float scale = [[layer valueForKeyPath:@"transform.scale.x"] floatValue];
		scale = fminf(scale * 2.0,20.0);
		[layer setTransform:CATransform3DMakeScale(scale, scale, 1.0)];
	}
}

- (void)zoomInMovie:(QTMovie*)movie toPoint:(CGPoint)pt
{	
	BOOL toPoint = YES;
	if(toPoint)
	{
		NSUInteger index = [movies indexOfObject:movie];
		if(index != NSNotFound)
		{
			CALayer *layer = (CALayer*)[movieLayers objectAtIndex:index];

			float scale = [[layer valueForKeyPath:@"transform.scale.x"] floatValue];
			
			CGFloat diffx = layer.frame.size.width/(2.0 * scale) - pt.x;
			CGFloat diffy = layer.frame.size.height/(2.0 * scale) - pt.y;
			
			scale = fminf(scale * 2.0,20.0);
							 
			
			CATransform3D move = CATransform3DMakeTranslation(diffx, diffy, 0);
			CATransform3D scalemat = CATransform3DMakeScale(scale, scale, 1.0);
			CATransform3D moveback = CATransform3DMakeTranslation(-diffx, -diffy, 0);
			
			[layer setTransform:CATransform3DConcat(CATransform3DConcat(move, scalemat), moveback)];
		}
	}
	else
	{
		[self zoomInMovie:movie];
	}
}

- (void)zoomOutMovie:(QTMovie*)movie
{
	NSUInteger index = [movies indexOfObject:movie];
	if(index != NSNotFound)
	{
		CALayer *layer = (CALayer*)[movieLayers objectAtIndex:index];
		float scale = [[layer valueForKeyPath:@"transform.scale.x"] floatValue];
		scale = fmaxf(scale/2.0,1.0);
		[layer setTransform:CATransform3DMakeScale(scale,scale, 1.0)];
	}
}

- (void)zoomOutMovie:(QTMovie*)movie toPoint:(CGPoint)pt
{	
	BOOL toPoint = YES;
	if(toPoint)
	{
		NSUInteger index = [movies indexOfObject:movie];
		if(index != NSNotFound)
		{
			CALayer *layer = (CALayer*)[movieLayers objectAtIndex:index];
			
			float scale = [[layer valueForKeyPath:@"transform.scale.x"] floatValue];
			
			CGFloat diffx = layer.frame.size.width/(2.0 * scale) - pt.x;
			CGFloat diffy = layer.frame.size.height/(2.0 * scale) - pt.y;
			
			scale = fmaxf(scale / 2.0,1.0);
			
			
			CATransform3D move = CATransform3DMakeTranslation(diffx, diffy, 0);
			CATransform3D scalemat = CATransform3DMakeScale(scale, scale, 1.0);
			CATransform3D moveback = CATransform3DMakeTranslation(-diffx, -diffy, 0);
			
			[layer setTransform:CATransform3DConcat(CATransform3DConcat(move, scalemat), moveback)];
		}
	}
	else
	{
		[self zoomInMovie:movie];
	}
}

- (IBAction)zoomIn:(id)sender
{
	if([[sender representedObject] isKindOfClass:[QTMovie class]])
	{
		[self zoomInMovie:(QTMovie*)[sender representedObject]];
	}

}

- (IBAction)zoomOut:(id)sender
{
	if([[sender representedObject] isKindOfClass:[QTMovie class]])
	{
		[self zoomOutMovie:(QTMovie*)[sender representedObject]];
	}
}

- (void)frameDidChange
{
	if([[self trackingAreas] count] > 0)
	{
		[self removeTrackingArea:[[self trackingAreas] objectAtIndex:0]];
	}
	int options = NSTrackingCursorUpdate | NSTrackingMouseMoved | NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited;
	NSTrackingArea *ta;
	ta = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
	[self addTrackingArea:ta];
	[ta release];
	
	[self sizeMovieLayersWithAnimation:NO];
}

- (void)sizeMovieLayers
{
	if(dragMovie)
	{
		[self sizeMovieLayersWithAnimation:YES];
	}
	else
	{
		[self sizeMovieLayersWithAnimation:NO];
	}	
}

- (QTTrack *)firstVideoTrack:(QTMovie*)theMovie
{
    QTTrack *track = nil;
    NSEnumerator *enumerator = [[theMovie tracks] objectEnumerator];
    while ((track = [enumerator nextObject]) != nil)
    {
        if ([track isEnabled])
        {
            QTMedia *media = [track media];
            NSString *mediaType;
            mediaType = [media attributeForKey:QTMediaTypeAttribute];
            if ([mediaType isEqualToString:QTMediaTypeVideo] || [mediaType isEqualToString:QTMediaTypeMPEG])
            {
                if ([media hasCharacteristic:QTMediaCharacteristicHasVideoFrameRate])
                    break; // found first video track
            }
        }
    }
    
    return track;
}

- (void)sizeMovieLayersWithAnimation:(BOOL)animate
{
	float total = 0;
	int nosize = 0;
	for(CALayer *movieLayer in movieLayers)
	{
		NSNumber *percent = [movieLayer valueForKey:DPVideoWidthPercentage];
		if(percent)
		{
			total += [percent floatValue];
		}
		else
		{
			nosize++;
		}
	}
	if(nosize > 0)
	{
		float remainder = (1.0 - total)/(float)nosize;
		for(CALayer *movieLayer in movieLayers)
		{
			NSNumber *percent = [movieLayer valueForKey:DPVideoWidthPercentage];
			if(!percent)
			{
				[movieLayer setValue:[NSNumber numberWithFloat:remainder] forKey:DPVideoWidthPercentage];
			}
		}
	}
	else
	{
		float remainder = (1.0 - total)/(float)[movieLayers count];
		for(CALayer *movieLayer in movieLayers)
		{
			NSNumber *percent = [movieLayer valueForKey:DPVideoWidthPercentage];
			[movieLayer setValue:[NSNumber numberWithFloat:[percent floatValue] + remainder] forKey:DPVideoWidthPercentage];
		}
	}
	
	NSRect boundsRect = [self bounds];
	//CGFloat width = boundsRect.size.width/(CGFloat)[movies count];
	CGFloat height = boundsRect.size.height;
	
	[CATransaction flush];
	[CATransaction begin];
	
	if(!animate)
	{
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];
	}
	
	int index = 0;
	CGFloat x = 0;
	for(QTMovieLayer *layer in movieLayers)
	{
		CALayer *maskLayer = [layer superlayer];
		QTMovie *movie = [movies objectAtIndex:index];
		CALayer *controlLayer = (CALayer*)[layer valueForKey:@"DPControlLayer"];
		
		CGFloat width = boundsRect.size.width * [[layer valueForKey:DPVideoWidthPercentage] floatValue];
		NSSize contentSize = [[movie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
        
//        CGFloat aspect = 1;
//        BOOL aperture = [[movie attributeForKey:QTMovieHasApertureModeDimensionsAttribute] boolValue];
//        if(aperture)
//        {
//            QTTrack *videoTrack = [self firstVideoTrack:movie];
//            NSSize apertureDimensions = [videoTrack apertureModeDimensionsForMode:[movie attributeForKey:QTMovieApertureModeAttribute]];
//            aspect = apertureDimensions.width/apertureDimensions.height;
//        }
//        else
//        {
//            aspect = (contentSize.width/contentSize.height);
//        }
        
        CGFloat aspect = contentSize.width/contentSize.height;
		float sizeRatio = width/height;
		
		CGRect frame = CGRectMake(0, 0, width, height);
		maskLayer.bounds = frame;
		
		if(aspect > sizeRatio)
		{
			frame.size.height = width / aspect;
		}
		else
		{
			frame.size.width = height * aspect;
		}
		
		layer.bounds = frame;
		layer.anchorPoint = CGPointMake(0.5, 0.5);
		layer.position = CGPointMake(width/2.0,height/2.0);
		
		controlLayer.anchorPoint = CGPointMake(1.0,1.0);
		controlLayer.position = CGPointMake(frame.size.width - 10, frame.size.height - 10);
		
		maskLayer.anchorPoint = CGPointMake(0.5, 0.5);
		maskLayer.position = CGPointMake(x + width/2.0,height/2.0);
		
		x += width;
		index++;
	}
	
	[CATransaction commit];	
}

- (QTMovieLayer*)createLayerForMovie:(QTMovie*)movie    
{
	QTMovieLayer *layer = [[QTMovieLayer alloc] initWithMovie:movie];
	
	CALayer *maskLayer = [[CALayer alloc] init];
	[maskLayer setMasksToBounds:YES];
	[maskLayer addSublayer:layer];
	[layer release];
	[maskLayer autorelease];
	
	for(VideoProperties* video in [[AnnotationDocument currentDocument] mediaProperties])
	{
		if([video movie] == movie)
		{
			[layer setValue:video forKey:@"DPVideoProperties"];
			if(![video enabled])
			{
				layer.filters = inactiveVideoFilters;
			}
            
            [video addObserver:self
                    forKeyPath:@"enabled"
                       options:0
                       context:NULL];
            
			break;
		}
	}
	
	return layer;
}

- (CALayer*)createControlLayerForMovieLayer:(QTMovieLayer*)movieLayer
{
	if(([movies count] > 1) || [[[self window] windowController] isKindOfClass:[MovieViewerController class]])
	{
		CGFloat controlWidth = 130;
		CGFloat controlHeight = 21;
		
		CGColorRef darkgrey = CGColorCreateGenericGray(0.1, 1.0);
		
		CALayer *controlLayer = [CALayer layer];
		controlLayer.frame = CGRectMake(0, 0, controlWidth, controlHeight);
		controlLayer.backgroundColor = controlBackground;
		controlLayer.borderColor = darkgrey;
		controlLayer.borderWidth = 2.0;
		controlLayer.cornerRadius = 5.0;
		controlLayer.shadowOpacity = 0.5;
		
		CATextLayer *controlTextLayer = [CATextLayer layer];
		controlTextLayer.font = @"Helvetica Bold";
		controlTextLayer.fontSize = 16.0;
		controlTextLayer.alignmentMode = kCAAlignmentCenter;
		controlTextLayer.autoresizingMask = (kCALayerMaxYMargin | kCALayerMinXMargin);
		controlTextLayer.bounds = CGRectMake(0.0, 0.0, controlWidth, 14);
		controlTextLayer.anchorPoint = CGPointMake(0.5, 0.5);
		controlTextLayer.position = CGPointMake(controlWidth/2.0,controlHeight/2.0);
		controlTextLayer.foregroundColor = darkgrey;
		
		CGColorRelease(darkgrey);
		//controlTextLayer.backgroundColor = CGColorCreateGenericRGB(1.0, 0, 0, 1.0);
		
		controlTextLayer.opacity = 1.0;
		
		VideoProperties* video = [movieLayer valueForKey:@"DPVideoProperties"];
		if([video enabled])
		{
			controlTextLayer.string = @"Disable Video";	
		}
		else
		{
			controlTextLayer.string = @"Activate Video";
		}
		[controlLayer addSublayer:controlTextLayer];
		[controlLayer setValue:controlTextLayer forKey:@"DPDisableTextLayer"];
        [controlLayer setValue:video forKey:@"DPVideoProperties"];
		
		[movieLayer addSublayer:controlLayer];
		
		[movieLayer setValue:controlLayer forKey:@"DPControlLayer"];
		
		[controlLayers addObject:controlLayer];
		controlLayer.opacity = 0.0;
		
        if([[self trackingAreas] count] == 0)
        {
            [self frameDidChange];
        }
        
		return controlLayer;
	}
	else
	{
		return nil;
	}
}

- (void)updateEnabledStatusForVideoProperties:(VideoProperties *)properties
{
    NSUInteger index = [movies indexOfObject:[properties movie]];
	if(index != NSNotFound)
	{
        CALayer *movieLayer = [movieLayers objectAtIndex:index];
        
        if([properties enabled])
        {
            movieLayer.filters = nil;
        }
        else
        {						
            movieLayer.filters = inactiveVideoFilters;
        }
        
		CALayer *controlLayer = [movieLayer valueForKey:@"DPControlLayer"];
		if(controlLayer)
		{
            CATextLayer *controlTextLayer = [controlLayer valueForKey:@"DPDisableTextLayer"];
            if(![properties enabled])
            {
                controlTextLayer.string = @"Activate Video";
            }
            else
            {
                controlTextLayer.string = @"Disable Video";
            }
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"enabled"]) {
        [self updateEnabledStatusForVideoProperties:object];
	}
}


#pragma mark Mouse Events

- (void)cursorUpdate:(NSEvent *)event 
{
	if([[AppController currentApp] currentTool] == DataPrismZoomTool)
	{
		[magnifyCursor push];
	}
	else
	{
		[[NSCursor arrowCursor] push];
	}
}

- (void)mouseExited:(NSEvent*)theEvent
{
	[CATransaction begin];
	
	for(CALayer *layer in controlLayers)
	{
		layer.opacity = 0;
	}
	
	[CATransaction commit];
}

- (void)mouseMoved:(NSEvent*)theEvent
{
	CGFloat x = 0;
	
	NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	int index = 1;
	for(CALayer *movieLayer in movieLayers)
	{
		if(index != [movieLayers count])
		{
			x += [movieLayer superlayer].frame.size.width;
			if(fabs(pt.x - x) < 5)
			{
				[[NSCursor resizeLeftRightCursor] push];
				resizeMovieIndex = index;
				return;
			}
		}
		index++;
	}
	
	resizeMovieIndex = 0;
	
	if([NSCursor currentCursor] == [NSCursor resizeLeftRightCursor])
	{
		[NSCursor pop];
	}
	
	CGPoint layerPt = NSPointToCGPoint(pt);

	
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.2f]
					 forKey:kCATransactionAnimationDuration];
	
	for(CALayer *layer in movieLayers)
	{
		CALayer *controlLayer = [layer valueForKey:@"DPControlLayer"];
		if([layer containsPoint:[layer convertPoint:layerPt fromLayer:[self layer]]])
		{
			controlLayer.opacity = 1.0;
			if([controlLayer containsPoint:[controlLayer convertPoint:layerPt fromLayer:[self layer]]])
			{
				controlLayer.backgroundColor = controlBackgroundActive;
			}
			else
			{
				controlLayer.backgroundColor = controlBackground;
			}
			
		}
		else
		{
			controlLayer.opacity = 0.0;
		}
	}
	
	[CATransaction commit];
}

- (void)mouseDown:(NSEvent*)theEvent
{
	NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	CGPoint layerPt = NSPointToCGPoint(pt);
	
	for(QTMovieLayer* layer in movieLayers)
	{
		CALayer *controlLayer = [layer valueForKey:@"DPControlLayer"];
		if([controlLayer containsPoint:[controlLayer convertPoint:layerPt fromLayer:[self layer]]])
		{
			activeControlLayer = controlLayer;
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue
							 forKey:kCATransactionDisableActions];
			controlLayer.backgroundColor = CGColorGetConstantColor(kCGColorWhite);
			[CATransaction commit];
			
			VideoProperties* video = [layer valueForKey:@"DPVideoProperties"];
			[video setEnabled:![video enabled]];
			[[AppController currentApp] setRate:[[[AppController currentApp] movie] rate] fromSender:self];
			
//			if([video enabled])
//			{
//				layer.filters = nil;
//				//layer.opacity = 1.0;
//			}
//			else
//			{						
//                layer.filters = inactiveVideoFilters;
////				CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
////				[filter setDefaults];
////				[filter setValue:[NSNumber numberWithFloat:0.0] forKey:@"inputSaturation"];
////				layer.filters = [NSArray arrayWithObject:filter];
//				//layer.opacity = 0.5;
//			}
			
		}
	}
	
	if(resizeMovieIndex > 0)
	{
		resizeMoviePoint = pt;
	}
	else if([[AppController currentApp] currentTool] == DataPrismZoomTool)
	{
		QTMovieLayer *layer = (QTMovieLayer*)[[self layer] hitTest:NSPointToCGPoint(pt)];
		
		CGPoint layerpoint = NSPointToCGPoint(pt);
		layerpoint = [layer convertPoint:layerpoint fromLayer:[self layer]];
		
		if([theEvent modifierFlags] & NSAlternateKeyMask)
		{
			[self zoomOutMovie:[layer movie] toPoint:layerpoint];
		}
		else
		{
			[self zoomInMovie:[layer movie] toPoint:layerpoint];
		}
		
//		CALayer *layer = [[self layer] hitTest:NSPointToCGPoint(pt)];
//		float scale = [[layer valueForKeyPath:@"transform.scale.x"] floatValue];
//		
//		if([theEvent modifierFlags] & NSAlternateKeyMask)
//		{
//			scale = fmaxf(scale/2.0,1.0);
//			[layer setTransform:CATransform3DMakeScale(scale,scale, 1.0)];
//		}
//		else
//		{
//			scale = fminf(scale * 2.0,20.0);
//			[layer setTransform:CATransform3DMakeScale(scale, scale, 1.0)];
//		}
	}
}

- (void)mouseUp:(NSEvent*)theEvent
{
	if(activeControlLayer)
	{
//		CATextLayer *controlTextLayer = [activeControlLayer valueForKey:@"DPDisableTextLayer"];
//        VideoProperties *properties = [activeControlLayer valueForKey:@"DPVideoProperties"];
//		if(![properties enabled])
//		{
//			controlTextLayer.string = @"Activate Video";
//		}
//		else
//		{
//			controlTextLayer.string = @"Disable Video";
//		}
		activeControlLayer.backgroundColor = controlBackgroundActive;
		activeControlLayer = nil;
	}
}

- (void)mouseDragged:(NSEvent*)theEvent
{
	if(activeControlLayer)
	{
		return;
	}
	else if(resizeMovieIndex > 0)
	{
		NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		CALayer *lMovie = [movieLayers objectAtIndex:(resizeMovieIndex - 1)];
		CALayer *rMovie = [movieLayers objectAtIndex:resizeMovieIndex];
				
		float lpercent = (pt.x - [lMovie superlayer].frame.origin.x)/[self bounds].size.width;
		
		
		float rpercent = (CGRectGetMaxX([rMovie superlayer].frame) - pt.x)/[self bounds].size.width;
		
		[lMovie setValue:[NSNumber numberWithFloat:lpercent] forKey:DPVideoWidthPercentage];
		[rMovie setValue:[NSNumber numberWithFloat:rpercent] forKey:DPVideoWidthPercentage];
		
		
		[self sizeMovieLayers];
		
		if([NSCursor currentCursor] != [NSCursor resizeLeftRightCursor])
		{
			[[NSCursor resizeLeftRightCursor] set];
		}
	}
	else
	{	
		QTMovie *theDragMovie = nil;
		
		QTMovieLayer *theLayer = nil;
		
		CGPoint basePoint = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
		for(QTMovieLayer* layer in movieLayers)
		{
			if([layer containsPoint:[layer convertPoint:basePoint fromLayer:[self layer]]])
			{
				theDragMovie = [layer movie];
				theLayer = layer;
			}
		}
		
		VideoProperties *dragProperties = nil;
		
		for(VideoProperties* video in [[AnnotationDocument currentDocument] mediaProperties])
		{
			if([video movie] == theDragMovie)
			{
				dragProperties = video;
			}
		}
		
		if(!dragProperties)
		{
			if((theDragMovie == [[AnnotationDocument currentDocument] movie]) 
			   && ([movies count] > 1))
			{
				dragProperties = [[AnnotationDocument currentDocument] videoProperties];
			}
		}
		
		if(dragProperties)
		{
			//NSSize contentSize = [[theDragMovie attributeForKey:QTMovie QTMovieNaturalSizeAttribute] sizeValue];
			NSSize contentSize = NSSizeFromCGSize([theLayer bounds].size);
			NSSize imageSize = NSMakeSize(contentSize.width/1.5,  contentSize.height/1.5);
			NSImage* image = [[NSImage alloc] initWithSize:imageSize];
			[image lockFocus];
			
			[[theDragMovie currentFrameImage] drawInRect:NSMakeRect(0,0,imageSize.width,imageSize.height)
												fromRect:NSZeroRect 
											   operation:NSCompositeCopy
												fraction:0.75];
			
			[image unlockFocus];
			
			[image autorelease];
			
			NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
			[pboard declareTypes:[NSArray arrayWithObject:DPVideoPropertiesPasteboardType]  owner:self];
			[pboard setString:[dragProperties title] forType:DPVideoPropertiesPasteboardType];
			
			NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
			NSPoint location = NSMakePoint(mousePoint.x - imageSize.width/2.0, mousePoint.y - imageSize.height/2.0);
			
			dragMovie = theDragMovie;
			
			BOOL slideBack = (([movies count] == 1)
							  || (dragProperties == [[AnnotationDocument currentDocument] videoProperties]));
			
			[self dragImage:image
						 at:location
					 offset:NSZeroSize 
					  event:theEvent 
				 pasteboard:pboard 
					 source:self 
				  slideBack:slideBack];
		}
	}
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{

	VideoProperties *video = nil;
	
	for(VideoProperties* props in [[AnnotationDocument currentDocument] mediaProperties])
	{
		if([props movie] == dragMovie)
		{
			if(video)
			{
				NSLog(@"Duplicate video titles!");
			}
			else
			{
				video = props;
			}
		}
	}
	
	if((operation == NSDragOperationMove)
	   && ([movies count] == 1) 
	   && [[[self window] windowController] isKindOfClass:[MovieViewerController class]])
	{
		[[self window] performClose:self];
		[video setEnabled:YES];
		
	}
	else if((operation != NSDragOperationMove)
			&& ![movies containsObject:dragMovie])
	{
		if(video)
		{
			
			MovieViewerController *movieViewer = nil;
			
			for(id view in [[AppController currentApp] annotationViews])
			{
				if([view isKindOfClass:[MovieViewerController class]])
				{
					if([view videoProperties] == video)
					{
						movieViewer = (MovieViewerController*)view;
					}
				}
			}
			
			if(!movieViewer)
			{
				movieViewer = [[MovieViewerController alloc] init];	
				[movieViewer setVideoProperties:video];
				[[AppController currentApp] addAnnotationView:movieViewer];
				[movieViewer release];
			}
			
			[[movieViewer window] setFrameOrigin:aPoint];
			[movieViewer showWindow:self];
			[[movieViewer window] makeKeyAndOrderFront:self];
			
		}
	}
		 
	dragMovie = nil;
	
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	if(isLocal)
	{
		return NSDragOperationMove;
	}
	else
	{
		return NSDragOperationNone;
	}
}

- (BOOL)ignoreModifierKeysWhileDragging
{
	return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
	
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	
    if ( [[pboard types] containsObject:DPVideoPropertiesPasteboardType]	
		&& (sourceDragMask & NSDragOperationMove))
	{
		QTMovie* testMovie = nil;
		if(!dragMovie)
		{
			NSString *videoTitle = [pboard stringForType:DPVideoPropertiesPasteboardType];
			VideoProperties *video = nil;
			
			for(VideoProperties* props in [[AnnotationDocument currentDocument] mediaProperties])
			{
				if([videoTitle isEqualToString:[props title]])
				{
					if(video)
					{
						NSLog(@"Duplicate video titles!");
					}
					else
					{
						video = props;
						testMovie = [video movie];
					}
				}
			}
		}
		else
		{
			testMovie = dragMovie;
		}
			

			
		if(testMovie && ![movies containsObject:testMovie])
		{
			dragMovie = testMovie;
			
			[movies addObject:dragMovie];
			QTMovieLayer *layer = [self createLayerForMovie:dragMovie];
			[self createControlLayerForMovieLayer:layer];
			
			float newPercentage = (float)[movieLayers count]/(float)([movieLayers count] + 1);
			for(CALayer *movieLayer in movieLayers)
			{
				NSNumber *oldPercentage = [movieLayer valueForKey:DPVideoWidthPercentage];
				if(oldPercentage)
				{
					[movieLayer setValue:[NSNumber numberWithFloat:(newPercentage * [oldPercentage floatValue])] forKey:DPVideoWidthPercentage];
				}
			}
			
			
			[movieLayers addObject:layer];
			
			[self sizeMovieLayersWithAnimation:YES];
			
			[layer setOpacity:0.3];
			
			[[self layer] addSublayer:[layer superlayer]];
			
			return NSDragOperationMove;	
		}
    }
	
	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
	if(([movies count] > 1) && dragMovie)
	{
		NSRect boundsRect = [self bounds];
		CGFloat width = boundsRect.size.width/(CGFloat)[movies count];
		NSSize imageSize = [[sender draggedImage] size];
		
		CGFloat imageCenterX = [sender draggedImageLocation].x + imageSize.width/2.0;
		
		int index = floor(imageCenterX / width);
	
		int currentIndex = [movies indexOfObject:dragMovie];
		
		if((currentIndex != NSNotFound) && (index != currentIndex))
		{
			QTMovieLayer *layer = [movieLayers objectAtIndex:currentIndex];
			
			[movies removeObjectAtIndex:currentIndex];
			[movieLayers removeObjectAtIndex:currentIndex];
			
			[movies insertObject:dragMovie atIndex:index];
			[movieLayers insertObject:layer atIndex:index];
			
			[self sizeMovieLayers];
			
		}
		return NSDragOperationMove;
	}
	return NSDragOperationNone;
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
	if(dragMovie && ([movies count] > 1) && (dragMovie != [[AnnotationDocument currentDocument] movie]))
	{
		[self removeMovie:dragMovie];
		if([sender draggingSource] != self)
		{
			dragMovie = nil;	
		}
	}
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if(dragMovie)
	{
		NSUInteger index = [movies indexOfObject:dragMovie];
		
		if(index != NSNotFound)
		{
			QTMovieLayer *layer = [movieLayers objectAtIndex:index];
			[layer setOpacity:1.0];
		}
		
		dragMovie = nil;
		
	
		return YES;
    }
	else
	{
		return NO;
	}
}


/*
- (void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
	// Pass on mouse down events
    //[[self nextResponder] mouseDown:theEvent];
}
*/

#pragma mark Key Events

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)resignFirstResponder {
    return NO;
}

- (void)keyDown:(NSEvent *)event
{
	if(localController)
	{
		unsigned short theKey = [event keyCode];
		//NSLog(@"KeyDown %i",theKey);
		if(theKey == 123) // Left Arrow
		{
			[localController moveAlignmentOneFrameBackward];
		} else if(theKey == 124) // Right Arrow
		{
			[localController moveAlignmentOneFrameForward];	
		} else if(theKey == 126)
		{
			[localController moveAlignmentOneStepBackward];		
		} else if(theKey == 125)
		{
			[localController moveAlignmentOneStepForward];		
		} else if(theKey == 49) // Space Bar
		{
			//[localController togglePlay:self];		
		}
		else {
			Annotation *result = [[AnnotationDocument currentDocument] addAnnotationForCategoryKeyEquivalent:[event characters]];
			if(!result)
			{
				[super keyDown:event];
			}
		}
	}
	else
	{
		if(!mAppController)
		{
			mAppController = [AppController currentApp];
		}
		
		unsigned short theKey = [event keyCode];
		//NSLog(@"AFMovieView KeyDown %i",theKey);
		if(theKey == 36)
		{
			
			if([event modifierFlags] & NSCommandKeyMask)
			{
				[super keyDown:event];
				//[mAppController newAnnotation:self];
			}
			else
			{
				[mAppController showAnnotationQuickEntry:self];	
			}
			
		} else if(theKey == 123) // Left Arrow
		{
			[mAppController stepOneFrameBackward:self];
		} else if(theKey == 124) // Right Arrow
		{
			[mAppController stepOneFrameForward:self];	
		} else if(theKey == 126) // Up Arrow
		{
			[mAppController stepBack:self];		
		} else if(theKey == 125) // Down Arrow
		{
			[mAppController stepForward:self];		
		} else if(theKey == 49) // Space Bar
		{
			[mAppController togglePlay:self];		
		} else if(theKey == 51) // Backspace
		{
			if([mAppController selectedAnnotation])
			{
				NSAlert *confirmation = [[NSAlert alloc] init];
				[confirmation setMessageText:@"Are you sure you want to delete the currently selected annotation?"];
				[[confirmation addButtonWithTitle:@"Delete"] setKeyEquivalent:@""];
				[[confirmation addButtonWithTitle:@"Cancel"] setKeyEquivalent:@"\r"];
				
				NSInteger result = [confirmation runModal];
				
				if(result == NSAlertFirstButtonReturn)
				{
					[mAppController removeCurrentAnnotation:self];	
				}
                
                [confirmation release];
			}
		
		}
		else {
			if([[NSUserDefaults standardUserDefaults] integerForKey:AFAnnotationShortcutActionKey] == AFCategoryShortcutEditor)
			{
				AnnotationCategory *category = [[AnnotationDocument currentDocument] annotationCategoryForKeyEquivalent:[event characters]];
				if(category)
				{
					[mAppController showAnnotationQuickEntryForCategory:category];
				}
			}
			else if([event isARepeat] && lastAddedAnnotation && 
			   ([lastAddedAnnotation category] == [[AnnotationDocument currentDocument] annotationCategoryForKeyEquivalent:[event characters]]))
			{
				[lastAddedAnnotation setIsDuration:YES];
				[lastAddedAnnotation setEndTime:[mAppController currentTime]];
			}
			else
			{
				lastAddedAnnotation = [[AnnotationDocument currentDocument] addAnnotationForCategoryKeyEquivalent:[event characters]];
			}
			if(!lastAddedAnnotation)
			{
				[super keyDown:event];
			}		
		}
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenu *theMenu = [[[NSMenu alloc] initWithTitle:@"Contextual Menu"] autorelease];
	[theMenu setAutoenablesItems:NO];
	
	QTMovie *theMovie = nil;
	
	CGPoint basePoint = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
	for(QTMovieLayer* layer in movieLayers)
	{
		if([layer containsPoint:[layer convertPoint:basePoint fromLayer:[self layer]]])
		{
			theMovie = [layer movie];
		}
	}
	
	if(theMovie)
	{
		NSMenuItem *item = [theMenu addItemWithTitle:@"Mute Video" action:@selector(toggleMute:) keyEquivalent:@""];
		[item setRepresentedObject:theMovie];
		[item setTarget:self];
		
		if([theMovie muted])
		{
			[item setState:NSOnState];
		}
		else
		{
			[item setState:NSOffState];
		}	
	}
	else
	{
		[[theMenu addItemWithTitle:@"No video" action:nil keyEquivalent:@""] setEnabled:NO];
	}
	

	return theMenu;
}

/*
- (void)rightMouseDown:(NSEvent *)event
{
	// Do nothing (to avoid showing the contextual menu)
	// Basically, we want the right mouse button disabled
}

*/


@end
