//
//  DPMaskedSelectionView.m
//  ChronoViz
//
//  Created by Adam Fouse on 3/24/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPMaskedSelectionView.h"
#import "DPMaskedSelectionArea.h"
#import "NSColorCGColor.h"
#import "TimeCodedSpatialPoint.h"
#import "DPSpatialDataView.h"
#import "AJHBezierUtils.h"
#import "AppController.h"
#import "Annotation.h"
#import "NSStringTimeCodes.h"
#import "DPSelectionDataSource.h"
#import "SpatialTimeSeriesData.h"
#import "DPSpatialDataBase.h"

NSString * const DPMaskedSelectionChangedNotification = @"MaskedSelectionChangedNotification";
NSString * const DPMaskedSelectionAreaRemovedNotification = @"MaskedSelectionAreaRemovedNotification";

@interface DPMaskedSelectionArea (Internal)

- (CGRect)viewRectFromDataRect:(CGRect)dataRect;
- (CGRect)dataRectFromViewRect:(CGRect)viewRect;

@end

@implementation DPMaskedSelectionView

@synthesize transitionsTimeRange,dataBase;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setWantsLayer:YES];
        
        CGRect maskframe = NSRectToCGRect(frame);
        maskframe.origin = CGPointZero;
        
        selectionDataSources = [[NSMutableSet alloc] init];
        
        selectionLayers = [[NSMutableDictionary alloc] init];
        
        selectionsLayer = [[CALayer layer] retain];
        [selectionsLayer setFrame:maskframe];
        [[self layer] addSublayer:selectionsLayer];
        
        maskLayer = [[CALayer layer] retain];
        [maskLayer setDelegate:self];
        [maskLayer setFrame:maskframe];
        [[self layer] addSublayer:maskLayer];
        
		outlineLayer = [[CALayer layer] retain];
		
		maskColor = CGColorCreateGenericGray(0.3, 0.5);
		
		CGColorRef border = CGColorCreateGenericGray(0.2, 1.0);
		outlineLayer.borderColor = border;
		CGColorRelease(border);
		outlineLayer.borderWidth = 2.0;
		

		[[self layer] addSublayer:outlineLayer];
		
        maskedAreas = [[NSMutableArray alloc] init];
        [self newSelectionArea:self];
        
        transitionsLayer = nil;
        
		//maskedRect = CGRectNull;
        
        currentTransitions = nil;
        currentTransitionArrows = nil;
        
        [[AppController currentApp] addObserver:self forKeyPath:@"selectedAnnotation" options:0 context:nil];
		
	}
    return self;
}

- (void) dealloc
{
    [[AppController currentApp] removeObserver:self forKeyPath:@"selectedAnnotation"];
    [currentSelection removeObserver:self forKeyPath:@"color"];
    [currentSelection release];
    [selectionLayers release];
    [selectionsLayer release];
    [transitionsLayer release];
    [currentTransitions release];
    [maskedAreas release];
	[outlineLayer release];
    [selectionDataSources release];
    self.dataBase = nil;
	CGColorRelease(maskColor);
	[super dealloc];
}

- (void) drawArrowLine: (CGContextRef) context from: (CGPoint) from to: (CGPoint) to 
{
    double slopy, cosy, siny;
    // Arrow size
    double length = 10.0;  
    double width = 5.0;
    
    slopy = atan2((from.y - to.y), (from.x - to.x));
    cosy = cos(slopy);
    siny = sin(slopy);
    
    //draw a line between the 2 endpoint
    CGContextMoveToPoint(context, from.x - length * cosy, from.y - length * siny );
    CGContextAddLineToPoint(context, to.x + length * cosy, to.y + length * siny);
    //paints a line along the current path
    CGContextStrokePath(context);
    
    //here is the tough part - actually drawing the arrows
    //a total of 6 lines drawn to make the arrow shape
    CGContextMoveToPoint(context, from.x, from.y);
    CGContextAddLineToPoint(context,
                            from.x + ( - length * cosy - ( width / 2.0 * siny )),
                            from.y + ( - length * siny + ( width / 2.0 * cosy )));
    CGContextAddLineToPoint(context,
                            from.x + (- length * cosy + ( width / 2.0 * siny )),
                            from.y - (width / 2.0 * cosy + length * siny ) );
    CGContextClosePath(context);
    CGContextStrokePath(context);
    
    /*/-------------similarly the the other end-------------/*/
//    CGContextMoveToPoint(context, to.x, to.y);
//    CGContextAddLineToPoint(context,
//                            to.x +  (length * cosy - ( width / 2.0 * siny )),
//                            to.y +  (length * siny + ( width / 2.0 * cosy )) );
//    CGContextAddLineToPoint(context,
//                            to.x +  (length * cosy + width / 2.0 * siny),
//                            to.y -  (width / 2.0 * cosy - length * siny) );
//    CGContextClosePath(context);
//    CGContextStrokePath(context);
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    if(layer == transitionsLayer)
    {
        
//        NSArray *axiskeys = [NSArray arrayWithObjects:NSFontAttributeName,NSForegroundColorAttributeName,nil];
//        NSArray *axisobjects = [NSArray arrayWithObjects:[NSFont fontWithName:@"Helvetica-Bold" size:14.0],[NSColor whiteColor],nil];
//        NSDictionary *axisAttr = [NSDictionary dictionaryWithObjects:axisobjects
//                                                             forKeys:axiskeys];
        
        NSGraphicsContext *nsGraphicsContext;
        nsGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx
                                                                       flipped:NO];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:nsGraphicsContext];
        
        [[NSColor whiteColor] set];
        
        for(NSBezierPath *arrow in currentTransitionArrows)
        {
            //[arrow setLineWidth:4.0];
            [arrow stroke];
        }
        
//        for(NSString *probability in [currentTransitionLabels allKeys])
//        {
//            NSRange delimeter = [probability rangeOfString:@":"];
////            [[probability substringFromIndex:(delimeter.location + 1)] drawAtPoint:[[currentTransitionLabels objectForKey:probability] pointValue]
////                      withAttributes:axisAttr];
//            
//            
//        }
//        
        [NSGraphicsContext restoreGraphicsState];
        
    }
    else if(layer == maskLayer)
    {
        CGColorRef gray = CGColorCreateGenericGray(0.3, 0.5);
        CGContextSetFillColorWithColor(ctx, gray);
        CGContextFillRect(ctx, [maskLayer bounds]);
        
        CGContextClearRect(ctx, maskedRect);
        
        //CGContextClearRect(ctx, currentSelection.area);
        
        CGColorRelease(gray);   
    }
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    
    [CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
    
    [maskLayer setFrame:NSRectToCGRect([self bounds])];
    [selectionsLayer setFrame:NSRectToCGRect([self bounds])];
    [transitionsLayer setFrame:NSRectToCGRect([self bounds])];
	//CGFloat xScale = newSize.width/[self frame].size.width;
	//CGFloat yScale = newSize.height/[self frame].size.height;
    
    if([self inLiveResize])
    {
        [maskLayer setHidden:YES];
        [outlineLayer setHidden:YES];
        [selectionsLayer setHidden:YES];
    }
    
    [CATransaction commit];
}


- (void)viewDidEndLiveResize
{
    [maskLayer setHidden:NO];
    [selectionsLayer setHidden:NO];
    [outlineLayer setHidden:NO];
}

- (void)updateCoordinates
{
    maskedRect = [self viewRectFromDataRect:currentSelection.area];
    
    [CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
    
    [maskLayer setNeedsDisplay];
    [outlineLayer setFrame:maskedRect];
    
    for(CALayer *selectionLayer in [selectionLayers allValues])
    {
        DPMaskedSelectionArea *selection = [selectionLayer valueForKey:@"DPMaskedSelectionLayerArea"];
        selectionLayer.frame = [self viewRectFromDataRect:selection.area];
    }
    
    [CATransaction commit];
}

- (CGRect)viewRectFromDataRect:(CGRect)dataRect
{
    DPSpatialDataBase *base = nil;
    if(self.dataBase)
    {
        base = self.dataBase;
    }
    else
    {
        DPSelectionDataSource *source = [selectionDataSources anyObject];
        SpatialTimeSeriesData *spatialData = [source spatialData];
        base = [spatialData spatialBase];
    }
    CGFloat minX = CGRectGetMinX(dataRect);
    CGFloat minY = CGRectGetMinY(dataRect);
    CGFloat maxX = CGRectGetMaxX(dataRect);
    CGFloat maxY = CGRectGetMaxY(dataRect);
    
    CGPoint minPt = [base viewPointForDataPoint:CGPointMake(minX, minY)];
    CGPoint maxPt = [base viewPointForDataPoint:CGPointMake(maxX, maxY)];
    
    return CGRectMake(minPt.x, minPt.y, maxPt.x - minPt.x, maxPt.y - minPt.y);
}

- (CGRect)dataRectFromViewRect:(CGRect)viewRect
{
    DPSpatialDataBase *base = nil;
    if(self.dataBase)
    {
        base = self.dataBase;
    }
    else
    {
        base = [[[selectionDataSources anyObject] spatialData] spatialBase];
    }
    CGFloat minX = CGRectGetMinX(viewRect);
    CGFloat minY = CGRectGetMinY(viewRect);
    CGFloat maxX = CGRectGetMaxX(viewRect);
    CGFloat maxY = CGRectGetMaxY(viewRect);
    
    CGPoint minPt = [base dataPointForViewPoint:CGPointMake(minX, minY)];
    CGPoint maxPt = [base dataPointForViewPoint:CGPointMake(maxX, maxY)];
    
    return CGRectMake(minPt.x, minPt.y, maxPt.x - minPt.x, maxPt.y - minPt.y);
}

- (void)setMaskedRect:(CGRect)theMaskedRect
{
    maskedRect = theMaskedRect;
    
    //CGPoint reversedMinPt = [base viewPointForDataPoint:minPt];
    //NSLog(@"Original %f %f Translated %f %f Reversed %f %f",minX,minY,minPt.x,minPt.y,reversedMinPt.x,reversedMinPt.y);
    
    currentSelection.area = [self dataRectFromViewRect:theMaskedRect];
    
    //currentSelection.area = theMaskedRect;
	//CGRect maskedRect = theMaskedRect;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	if(CGRectIsNull(maskedRect))
	{
        [maskLayer setHidden:YES];
        
		[outlineLayer setHidden:YES];
	}
	else
	{
        [maskLayer setHidden: NO];
        [maskLayer setNeedsDisplay];
        
		[outlineLayer setHidden:NO];
		
		[outlineLayer setFrame:maskedRect];
	}
	
	[CATransaction commit];
}

- (CGRect)maskedRect
{
    if(currentSelection)
    {
        return maskedRect;
     	//return currentSelection.area;
    }
    else
    {
        return CGRectNull;
    }
}

- (DPMaskedSelectionArea*)newSelectionArea:(id)sender
{
    [self setCurrentSelection:nil];
    
    return currentSelection;
}

- (void)saveCurrentSelection:(id)sender
{
    if(![maskedAreas containsObject:currentSelection])
    {
        [maskedAreas addObject:currentSelection];
    }
    [self setCurrentSelection:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DPMaskedSelectionChangedNotification
														object:self];
    
}

- (void)deleteCurrentSelection:(id)sender
{
    NSString *selectionID = [[currentSelection guid] retain];
    DPMaskedSelectionArea *selection = currentSelection;
    [self setCurrentSelection:nil];
    [maskedAreas removeObject:selection];

    CALayer *selectionLayer = [selectionLayers objectForKey:selectionID];
    if(selectionLayer)
    {
        [selectionLayer removeFromSuperlayer];
        [selectionLayers removeObjectForKey:selectionID];
    }
    
    for(DPSelectionDataSource *source in selectionDataSources)
    {
        [source removeSelectionArea:selection];
    }
   
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DPMaskedSelectionAreaRemovedNotification
														object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:selectionID forKey:@"selectionID"]];
    [selectionID release];
}

- (void)removeSelection:(DPMaskedSelectionArea*)selection
{    
    if(selection != currentSelection)
    {
        for(DPSelectionDataSource *source in selectionDataSources)
        {
            [source removeSelectionArea:selection];
        }
    }
    
    [maskedAreas removeObject:selection];

}

- (void)setCurrentSelection:(DPMaskedSelectionArea*)selection
{
    [currentSelection removeObserver:self forKeyPath:@"color"];
    if([maskedAreas containsObject:currentSelection])
    {
        [self createSelectionLayer:currentSelection];
    }
    else
    {
        for(DPSelectionDataSource *source in selectionDataSources)
        {
            [source removeSelectionArea:currentSelection];
        }
    }
    [currentSelection release];
    
    
    if(selection == nil)
    {
        currentSelection = [[DPMaskedSelectionArea alloc] init];
        currentSelection.area = CGRectNull;
        
        for(DPSelectionDataSource *source in selectionDataSources)
        {
            [source addSelectionArea:currentSelection];
        }
    }
    else
    {    
        if([maskedAreas containsObject:selection])
        {
            CALayer *selectionLayer = [selectionLayers objectForKey:[selection guid]];
            if(selectionLayer)
            {
                [selectionLayer removeFromSuperlayer];
                [selectionLayers removeObjectForKey:[selection guid]];
            }
        }
                
        currentSelection = [selection retain];
    }
    
    CGColorRef borderColor = [[currentSelection.color colorWithAlphaComponent:0.7] createCGColor];
    outlineLayer.borderColor = borderColor;
    CGColorRelease(borderColor);
    
    [currentSelection addObserver:self
                       forKeyPath:@"color"
                          options:0
                          context:NULL];
    
    [self setMaskedRect:[self viewRectFromDataRect:currentSelection.area]];
    
    if(lastTransitionsData)
    {
        [self showTransitionsForData:lastTransitionsData];
    }
}

- (void)createSelectionLayer:(DPMaskedSelectionArea*)selection
{
    CALayer *selectionLayer = [CALayer layer];
    selectionLayer.frame = [self viewRectFromDataRect:selection.area];
    CGColorRef borderColor = [[selection.color colorWithAlphaComponent:0.7] createCGColor];
    selectionLayer.borderColor = borderColor;
    selectionLayer.borderWidth = 3.0;
    CGColorRelease(borderColor);
    [selectionLayer setValue:selection forKey:@"DPMaskedSelectionLayerArea"];
    
    CATextLayer *selectionNameLayer = [CATextLayer layer];
    selectionNameLayer.string = selection.name;
    selectionNameLayer.fontSize = 16.0;
    selectionNameLayer.shadowOpacity = 0.6;
    selectionNameLayer.autoresizingMask = kCALayerWidthSizable;
    CGFloat inset = 8;
    selectionNameLayer.frame = CGRectMake(inset, inset, selectionLayer.frame.size.width - (inset*2), selectionLayer.frame.size.height - (inset * 2));
    
    [selectionLayer addSublayer:selectionNameLayer];
    
    [selectionsLayer addSublayer:selectionLayer];
    
    [selectionLayers setObject:selectionLayer forKey:[selection guid]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"color"] && currentSelection.color) {
        CGColorRef borderColor = [[currentSelection.color colorWithAlphaComponent:0.7] createCGColor];
        outlineLayer.borderColor = borderColor;
        CGColorRelease(borderColor);  
    }
    else if ([keyPath isEqualToString:@"selectedAnnotation"] && lastTransitionsData) {
		[self showTransitionsForData:lastTransitionsData];
    }

}

- (DPMaskedSelectionArea*)currentSelection
{
    return currentSelection;
}

- (NSArray*)selections
{
    return [[maskedAreas copy] autorelease];
}

- (void)linkSelectionDataSource:(DPSelectionDataSource*)dataSource
{
    [selectionDataSources addObject:dataSource];
    
    if([maskedAreas count] == 0)
    {
        for(DPMaskedSelectionArea *area in [dataSource selectionAreas])
        {
            [maskedAreas addObject:area];
            [self createSelectionLayer:area];
        }
    }
    
    [dataSource addSelectionArea:currentSelection];
}

- (void)unlinkSelectionDataSource:(DPSelectionDataSource*)dataSource
{
    [selectionDataSources removeObject:dataSource];
}

- (NSSet*)selectionDataSources
{
    return selectionDataSources;
}

#pragma mark Transitions

- (BOOL)showTransitions
{
    return showTransitions;
}

- (void)setShowTransitions:(BOOL)show
{
    if(showTransitions != show)
    {
        showTransitions = show;
        if(showTransitions)
        {
            transitionsLayer = [[CALayer layer] retain];
            CGRect maskframe = NSRectToCGRect([self bounds]);
            [transitionsLayer setDelegate:self];
            transitionsLayer.shadowOpacity = 0.8;
            [transitionsLayer setFrame:maskframe];
            [[self layer] addSublayer:transitionsLayer];
        }
        else 
        {
            [transitionsLayer removeFromSuperlayer];
            [transitionsLayer autorelease];
            transitionsLayer = nil;
            
            [currentTransitions release];
            currentTransitions = nil;
            lastTransitionsData = nil;
        }
    }
}

- (void)showTransitionsForData:(SpatialTimeSeriesData*)data
{
    [currentTransitions release];
    currentTransitions = [[self transitionProbabilities:data] retain];
    
    if(!showTransitions)
        [self setShowTransitions:YES];
    
    [transitionsLayer setNeedsDisplay];
}

- (NSDictionary*)transitionProbabilities:(SpatialTimeSeriesData*)data
{
    lastTransitionsData = data;
    
    NSMutableDictionary *fromAreas = [NSMutableDictionary dictionary];
    
    for(DPMaskedSelectionArea* fromArea in maskedAreas)
    {
        NSMutableDictionary *toAreas = [NSMutableDictionary dictionary];
        [fromAreas setObject:toAreas forKey:[fromArea guid]];
        for(DPMaskedSelectionArea *toArea in maskedAreas)
        {
            NSNumber *count = [NSNumber numberWithUnsignedInteger:0];
            [toAreas setObject:count forKey:[toArea guid]];
        }
    }
    
    DPMaskedSelectionArea *currentArea = nil;
    
    NSUInteger totalTransitions = 0;
    
    CMTimeRange currentRange;
    Annotation *current = [[AppController currentApp] selectedAnnotation];
    if(current && [current isDuration])
    {
        currentRange = [current range];
        self.transitionsTimeRange = [NSString stringWithFormat:@"%@ to %@",
                                     [current startTimeString],
                                     [current endTimeString]];
    }
    else 
    {
        current = nil;
        self.transitionsTimeRange = [NSString stringWithFormat:@"%@ to %@",
                                [NSString stringWithQTTime:kCMTimeZero],
                                [NSString stringWithQTTime:[[[AppController currentApp] movie] duration]]];
    }
    
    for(TimeCodedSpatialPoint* point in [data dataPoints])
    {
        if(!current || QTTimeInTimeRange([point time],currentRange))
        {
            for(DPMaskedSelectionArea* selection in maskedAreas)
            {
                if(CGRectContainsPoint([selection area], CGPointMake(point.x, point.y)))
                {
                    if(currentArea && (currentArea != selection))
                    {
                        NSMutableDictionary *transitions = [fromAreas objectForKey:[currentArea guid]];
                        NSNumber *currentCount = [transitions objectForKey:[selection guid]];
                        [transitions setObject:[NSNumber numberWithUnsignedInteger:([currentCount unsignedIntegerValue] + 1)]
                                                                            forKey:[selection guid]];
                        totalTransitions++;
                    }
                    
                    currentArea = selection;
                }
            }
        }
    }
    
    if(currentTransitionArrows)
    {
        [currentTransitionArrows removeAllObjects];
        [currentTransitionLabels removeAllObjects];
    }
    else 
    {
        currentTransitionArrows = [[NSMutableArray alloc] initWithCapacity:([maskedAreas count] * [maskedAreas count])];
        currentTransitionLabels = [[NSMutableDictionary alloc] init];
    }
    
    CGFloat total = (CGFloat)totalTransitions;
    
    NSLog(@"total: %f",total);
    
    int i = 0;
    
    for(CALayer *textlayer in [[[transitionsLayer sublayers] copy] autorelease])
    {
        [textlayer removeFromSuperlayer];
    }
    
    for(DPMaskedSelectionArea* fromArea in maskedAreas)
    {
        NSMutableDictionary *toAreas = [fromAreas objectForKey:[fromArea guid]];
        
        NSUInteger areaTotal = 0;
        
        for(NSNumber *number in [toAreas allValues])
        {
            areaTotal += [number unsignedIntegerValue];
        }
        
        
        for(DPMaskedSelectionArea *toArea in maskedAreas)
        {
            if((fromArea != toArea)
               && (CGRectEqualToRect(currentSelection.area,CGRectNull) || (currentSelection == fromArea)))
            {            
                BOOL top = ([maskedAreas indexOfObject:fromArea] < [maskedAreas indexOfObject:toArea]);
                
                CGFloat offset = 10;
                CGFloat side = top ? -1.0 : 1.0;
                
                NSNumber *count = [toAreas objectForKey:[toArea guid]];
                //CGFloat probability = [count doubleValue]/total;
                CGFloat probability = areaTotal ? [count doubleValue]/areaTotal : 0;
                [toAreas setObject:[NSNumber numberWithDouble:probability] forKey:[toArea guid]];
                
                NSBezierPath *arrow = [[NSBezierPath alloc] init];
                CGRect fromRect = [self viewRectFromDataRect:[fromArea area]];
                CGRect toRect = [self viewRectFromDataRect:[toArea area]];
                NSPoint fromCenter = NSMakePoint(CGRectGetMidX(fromRect), CGRectGetMidY(fromRect));
                NSPoint toCenter = NSMakePoint(CGRectGetMidX(toRect), CGRectGetMidY(toRect));
                CGFloat xDiff = (toCenter.x - fromCenter.x);
                CGFloat yDiff = (toCenter.y - fromCenter.y);
                
                CGFloat slope = (fromCenter.y - toCenter.y)/(fromCenter.x - toCenter.x);
                
                CGFloat offsetSlope = -1/slope;
                
                CGFloat offsetX = side * sqrt(pow(offset,2)/(1 + pow(offsetSlope,2)));
                CGFloat offsetY = offsetSlope * offsetX;
                
                CGFloat lineWidth = fmax(probability * 12.0,2.0);
                
                [arrow setLineWidth:lineWidth];   
                
                [arrow moveToPoint:NSMakePoint(fromCenter.x + xDiff*0.2 + offsetX, fromCenter.y + yDiff*0.2 + offsetY)];
                [arrow lineToPoint:NSMakePoint(toCenter.x + xDiff*-0.2 + offsetX, toCenter.y + yDiff*-0.2 + offsetY)];
                [arrow appendBezierPath:[arrow bezierPathWithArrowHeadForEndOfLength:20 angle:20]];
                [currentTransitionArrows addObject:arrow];
                [arrow release];
                
                if(currentSelection == fromArea)
                {
                
                CGFloat labelWidth = 50.0;
                CGFloat labelHeight = 16.0;
                
                if(offsetY < 0)
                {
                    offset += (labelHeight + 5);
                }
                else 
                {
                    offset += 3;
                }
                offsetX = side * sqrt(pow(offset,2)/(1 + pow(offsetSlope,2)));
                offsetY = offsetSlope * offsetX;
                
                CGFloat distance = sqrt(pow(xDiff,2) + pow(yDiff,2));
                CGFloat labelPercentDistance = 0;
                if (xDiff < 0)
                {
                    labelPercentDistance = ((distance/2.0) + (labelWidth/2.0))/distance;
                }
                else
                {
                    labelPercentDistance = ((distance/2.0) - (labelWidth/2.0))/distance;
                }

                NSPoint midPoint = NSMakePoint(fromCenter.x + xDiff*labelPercentDistance,
                                               fromCenter.y + yDiff*labelPercentDistance);
                
                NSPoint labelPoint = NSMakePoint(midPoint.x + offsetX, midPoint.y + offsetY);
                
                [currentTransitionLabels setObject:[NSValue valueWithPoint:labelPoint]
                                            forKey:[NSString stringWithFormat:@"%i:%.2f",i,probability]];
                
                CGRect textframe = CGRectMake(labelPoint.x - (labelWidth/2.0), labelPoint.y - (labelHeight/2.0), labelWidth, labelHeight);
                
                //NSLog(@"Text frame: %f %f %f %f",textframe.origin.x,textframe.origin.y,textframe.size.width,textframe.size.height);
                
                CATextLayer *text = [CATextLayer layer];
                text.font = [NSFont fontWithName:@"Helvetica-Bold" size:14.0];
                text.alignmentMode = kCAAlignmentCenter;
                text.frame = textframe;
                text.anchorPoint = CGPointMake(0, 0);
                text.string = [NSString stringWithFormat:@"%.2f",probability];
                text.fontSize = 14;
                text.shadowOpacity = 0.8;
                
                //[text addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
                //[text addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
                text.transform = CATransform3DMakeRotation(atanf(yDiff/xDiff), 0.0, 0.0, 1.0);
                [transitionsLayer addSublayer:text];
                
    //            CATextLayer *text2 = [CATextLayer layer];
    //            text2.frame = CGRectMake(labelPoint.x, labelPoint.y, 50, 15);
    //            text2.string = [NSString stringWithFormat:@"%.2f",probability];
    //            text2.fontSize = 14;
    //            
    //            if(top)
    //            {
    //                CGColorRef redColor = [[NSColor redColor] createCGColor];
    //                text2.backgroundColor = redColor;
    //                CGColorRelease(redColor);
    //            }
    //            
    //            //[text addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
    //            //[text addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    //            [transitionsLayer addSublayer:text2];
                
                }
                NSLog(@"Probability of %@ to %@: %f",[fromArea name],[toArea name],probability);
                i++;
                
            }
        }
    }
    
    return fromAreas;
}

#pragma mark Mouse Events

- (void)mouseDown:(NSEvent *)theEvent
{
    if(currentSelection)
    {
        //[self setMaskedRect:CGRectNull];
        
        startPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint currentPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	CGFloat width = fabs(startPoint.x - currentPoint.x);
	CGFloat height = fabs(startPoint.y - currentPoint.y);
	CGFloat x = fmin(startPoint.x,currentPoint.x);
	CGFloat y = fmin(startPoint.y,currentPoint.y);
	
	[self setMaskedRect:CGRectMake(x, y, width, height)];
}

- (void)mouseUp:(NSEvent*)theEvent
{
    if(!currentSelection || CGRectIsNull(currentSelection.area))
    {
        CGPoint testPoint = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
        for(DPMaskedSelectionArea *selection in maskedAreas)
        {
            if(CGRectContainsPoint([self viewRectFromDataRect:selection.area], testPoint))
            {
                [self setCurrentSelection:selection];
                return;
            }
        }  
    }
    else if (currentSelection 
             && NSEqualPoints(startPoint, [self convertPoint:[theEvent locationInWindow] fromView:nil]))
    {
        if([maskedAreas containsObject:currentSelection])
        {
            [self setCurrentSelection:nil];
        }
        else
        {
            [self setMaskedRect:CGRectNull];
        }
    }
    
	[[NSNotificationCenter defaultCenter] postNotificationName:DPMaskedSelectionChangedNotification
														object:self];
}

@end
