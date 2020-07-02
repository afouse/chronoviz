//
//  DPSpatialDataView.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/30/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPSpatialDataView.h"
#import "TimeCodedData.h"
#import "SpatialTimeSeriesData.h"
#import "OrientedSpatialTimeSeriesData.h"
#import "TimeCodedSpatialPoint.h"
#import "TimeCodedOrientationPoint.h"
#import "AnnotationDocument.h"
#import "NSColorCGColor.h"
#import "NSColorUniqueColors.h"
#import "NSArrayAFBinarySearch.h"
#import "AppController.h"
#import "DPViewManager.h"
#import "DPSpatialPathLayer.h"
#import "DPSpatialConnectionsLayer.h"
#import "NSImage-Extras.h"
#import "DPMaskedSelectionView.h"
#import "DPMaskedSelectionArea.h"
#import "DPSpatialDataBase.h"
#import "DPSpatialDataImageBase.h"
#import "DPSpatialDataMovieBase.h"
#import "VideoProperties.h"
#import "DataSource.h"
#import "DPSelectionDataSource.h"
#import "DPSpatialDataWindowController.h"

@interface DPSpatialDataView (Internal)

- (void)updatePath:(SpatialTimeSeriesData*)data;

//- (void)updatePixelMappings;

- (void)updateSelection:(id)sender;

- (void)createDefaultConnections;

- (SpatialTimeSeriesData*)dataSetWithVariable:(NSString*)variable andSource:(DataSource*)source;

@end

@implementation DPSpatialDataView

@synthesize subsetData;
@synthesize connectedPaths,blurPaths,pathTailTime,pathOpacity,aggregatePaths,staticPaths,indicatorSize;
@synthesize selectionView;
@synthesize invertX,invertY;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		dataSets = [[NSMutableArray alloc] init];
		subsets  = [[NSMutableDictionary alloc] init];
		pathLayers  = [[NSMutableDictionary alloc] init];
		indicatorLayers  = [[NSMutableDictionary alloc] init];
        pathConnections = [[NSMutableDictionary alloc] init];
		
        selectedTimeSeries = [[NSMutableDictionary alloc] init];
        
        backgroundLayer = nil;
        backgroundProvider = nil;
        
        needsUpdate = NO;
		fixedAspect = YES;
		showPath = YES;
        showPosition = YES;
        showConnections = NO;
		autoBounds = YES;
//		minX = CGFLOAT_MAX;
//		minY = CGFLOAT_MAX;
//		maxX = -CGFLOAT_MAX;
//		maxY = -CGFLOAT_MAX;
        
        subsetData = NO;
        
        connectedPaths = YES;
        blurPaths = YES;
        aggregatePaths = NO;
        staticPaths = NO;
        pathTailTime = 0.5;
        pathOpacity = 0.6;
        indicatorSize = 10;
        
        [self addObserver:self
               forKeyPath:@"connectedPaths"
                  options:0
                  context:NULL];
        [self addObserver:self
               forKeyPath:@"blurPaths"
                  options:0
                  context:NULL];
        [self addObserver:self
               forKeyPath:@"aggregatePaths"
                  options:0
                  context:NULL];
        [self addObserver:self
               forKeyPath:@"staticPaths"
                  options:0
                  context:NULL];
        [self addObserver:self
               forKeyPath:@"pathTailTime"
                  options:0
                  context:NULL];
        [self addObserver:self
               forKeyPath:@"pathOpacity"
                  options:0
                  context:NULL];
    }
    return self;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"connectedPaths"];
    [self removeObserver:self forKeyPath:@"blurPaths"];
    [self removeObserver:self forKeyPath:@"aggregatePaths"];
    [self removeObserver:self forKeyPath:@"staticPaths"];
    [self removeObserver:self forKeyPath:@"pathTailTime"];
    [self removeObserver:self forKeyPath:@"pathOpacity"];
    
    for(SpatialTimeSeriesData *data in dataSets)
    {
        [data removeObserver:self forKeyPath:@"color"];
        [data removeObserver:self forKeyPath:@"xOffset"];
        [data removeObserver:self forKeyPath:@"yOffset"];
    }
    
    [dataSets release];
    [subsets release];
    [pathLayers  release];
    [indicatorLayers  release];
    [pathConnections release];

    [selectedTimeSeries release];
    [selectionDataSources release];
    
    [indicatorGroupLayer removeFromSuperlayer];
    [pathsGroupLayer removeFromSuperlayer];
    [linesGroupLayer removeFromSuperlayer];
    
    [indicatorGroupLayer release];
    [pathsGroupLayer release];
    [linesGroupLayer release];
    
    [pathsFilters release];
        
    [super dealloc];
}

- (void)awakeFromNib
{
	[self setWantsLayer:YES];
	
	[[self layer] setBackgroundColor:CGColorCreateGenericGray(0.2, 1.0)];
    
    indicatorGroupLayer = [[CALayer layer] retain];
    pathsGroupLayer = [[CALayer layer] retain];
    linesGroupLayer = [[CALayer layer] retain];

    [linesGroupLayer setFrame:NSRectToCGRect([self bounds])];
    //[linesGroupLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
    [[self layer] addSublayer:linesGroupLayer];
    
    [pathsGroupLayer setFrame:NSRectToCGRect([self bounds])];
    //[pathsGroupLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
    [[self layer] addSublayer:pathsGroupLayer];
    
    [indicatorGroupLayer setFrame:NSRectToCGRect([self bounds])];
    //[indicatorGroupLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
    [[self layer] addSublayer:indicatorGroupLayer];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:3.0] forKey:@"inputRadius"];

    //CIFilter *filter = [CIFilter filterWithName:@"CIMaskToAlpha"];
    //[filter setDefaults];
    //[filter setValue:[NSNumber numberWithFloat:3.0] forKey:@"inputIntensity"];
    
    pathsFilters = [[NSArray alloc] initWithObjects:filter, nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(frameDidChange:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:self];
}

- (void)frameDidChange:(NSNotification*)notification
{
    [pathsGroupLayer setFrame:NSRectToCGRect([self bounds])];
    [backgroundLayer setFrame:NSRectToCGRect([self bounds])];
    [indicatorGroupLayer setFrame:NSRectToCGRect([self bounds])];
    [linesGroupLayer setFrame:NSRectToCGRect([self bounds])];
    
    [backgroundProvider setDisplayBounds:[backgroundLayer bounds]];
    
    if(![self inLiveResize])
    {
        if(staticPaths)
        {
            for(DPSpatialPathLayer *path in [pathLayers allValues])
            {
                path.entirePathNeedsRedraw = YES;
            }
        }
        [self setCurrentTime:currentTime];
        
        if(selectionView)
        {
            [selectionView updateCoordinates];
        }
    }
    else
    {
        [pathsGroupLayer setHidden:YES];
    }
}

- (void)viewDidEndLiveResize
{
    if(staticPaths)
    {
        for(DPSpatialPathLayer *path in [pathLayers allValues])
        {
            path.entirePathNeedsRedraw = YES;
        }
    }
    
    [self setCurrentTime:currentTime];
    
    if(selectionView)
    {
        [selectionView updateCoordinates];
    }
}

- (void)setBackgroundFile:(NSString*)file
{
    DPSpatialDataImageBase *base = [[DPSpatialDataImageBase alloc] initWithBackgroundFile:file];
    [self setSpatialBase:base];
    [base release];
}

- (void)setBackgroundMovie:(AVPlayer*)movie
{
    for(VideoProperties *props in [[AnnotationDocument currentDocument] allMediaProperties])
    {
        if([props movie] == movie)
        {
            
            [[[AppController currentApp] viewManager] closeVideo:props];
            
            DPSpatialDataMovieBase *base = [[DPSpatialDataMovieBase alloc] initWithVideo:props];
            [self setSpatialBase:base];
            [base release];
            
            return;
        }
    }
}

- (void)setSpatialBase:(DPSpatialDataBase *)base
{
    if(base)
    {
        [base retain];
        [backgroundLayer removeFromSuperlayer];
        [backgroundProvider release];
        backgroundProvider = base;
        
        backgroundLayer = [backgroundProvider backgroundLayer];
        [backgroundLayer setFrame:[[self layer] bounds]];
        [[self layer] insertSublayer:backgroundLayer below:linesGroupLayer];
        [self setRotation:rotation];
        
        if(staticPaths)
        {
            for(DPSpatialPathLayer *path in [pathLayers allValues])
            {
                path.entirePathNeedsRedraw = YES;
            }
        }
        
        [self forceUpdate];
        
        for(SpatialTimeSeriesData *data in dataSets)
        {
            data.spatialBase = [[backgroundProvider copy] autorelease];
        }
        
    }
}

- (DPSpatialDataBase*)spatialBase
{
    return backgroundProvider;
}

- (void)addData:(TimeCodedData*)data
{
	SpatialTimeSeriesData *theData = nil;
	if(![data isKindOfClass:[SpatialTimeSeriesData class]])
	{
		return;
	}
	else
	{
		theData = (SpatialTimeSeriesData*)data;
	}
	
	if(![dataSets containsObject:theData])
	{
        if(([dataSets count] == 0) // No data sets loaded
           || ![theData spatialBase] // This data set doesn't have a base yet
           || !backgroundProvider // The loaded data sets don't have a base
           || [[theData spatialBase] compatibleWithBase:backgroundProvider]) // The new base is compatible with the existing base
        {
            if(backgroundProvider)
            {
                if(![theData spatialBase] || [[theData spatialBase] isMemberOfClass:[DPSpatialDataBase class]])
                {
                    if([backgroundProvider isMemberOfClass:[DPSpatialDataBase class]])
                    {
                        CGRect coordinateSpace = backgroundProvider.coordinateSpace;
                        CGFloat maxX = fmax(coordinateSpace.size.width + coordinateSpace.origin.x, theData.maxX);
                        CGFloat maxY = fmax(coordinateSpace.size.height + coordinateSpace.origin.y, theData.maxY);
                        
                        CGFloat minX = fmin(coordinateSpace.origin.x,theData.minX);
                        CGFloat minY = fmin(coordinateSpace.origin.y,theData.minY);
                        
                        backgroundProvider.coordinateSpace = CGRectMake(minX, minY, maxX - minX, maxY - minY);
                        for(SpatialTimeSeriesData *existingData in dataSets)
                        {
                            existingData.spatialBase.coordinateSpace = backgroundProvider.coordinateSpace;
                        }
                    }
                    theData.spatialBase = [[backgroundProvider copy] autorelease];
                }
                else
                {
                    theData.spatialBase.coordinateSpace = backgroundProvider.coordinateSpace;
                }
            }
            else if (([dataSets count] == 0) && [theData spatialBase])
            {
                [[theData spatialBase] load];
                DPSpatialDataBase *newBase = [[theData spatialBase] copy];
                [self setSpatialBase:newBase];
                [newBase release];

                theData.spatialBase.coordinateSpace = backgroundProvider.coordinateSpace;
            }
            else
            {
                DPSpatialDataBase *emptyBackground = [[DPSpatialDataBase alloc] init];
                emptyBackground.coordinateSpace = CGRectMake(theData.minX, theData.minY, (theData.maxX - theData.minX), (theData.maxY - theData.minY));
                
                [self setSpatialBase:emptyBackground];
                
                [emptyBackground release];
                
//                backgroundProvider = [[DPSpatialDataBase alloc] init];
//                backgroundProvider.coordinateSpace = CGRectMake(theData.minX, theData.minY, (theData.maxX - theData.minX), (theData.maxY - theData.minY));
//
//                theData.spatialBase = [[backgroundProvider copy] autorelease];
//                theData.spatialBase.coordinateSpace = backgroundProvider.coordinateSpace;
//                
//                backgroundLayer = [backgroundProvider backgroundLayer];
//                [backgroundLayer setFrame:[[self layer] bounds]];
            }
        }
        else
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Incompatible Data Set."];
            [alert setInformativeText:@"The data set you are trying to add has a coordinate space that is incompatible with an existing data set in this view. Do you want to change the coordinate space?"];
            [alert addButtonWithTitle:@"Cancel"];
            [alert addButtonWithTitle:@"Change Coordinate Space"];
            NSInteger result = [alert runModal];
            [alert release];
            if(result == NSAlertSecondButtonReturn)
            {
               theData.spatialBase = [[backgroundProvider copy] autorelease];
            }
            else
            {
                [alert release];
                return;
            }
        }
        
        [theData addObserver:self
                    forKeyPath:@"xOffset"
                       options:0
                       context:NULL];
        
        [theData addObserver:self
                    forKeyPath:@"yOffset"
                       options:0
                       context:NULL];
        
		if(![theData color])
		{
            NSColor *color = [NSColor basicColorConsideringArrayOfObjects:dataSets];
            if(!color)
            {
                color = [NSColor blueColor];
            }
			[theData setColor:color];
		}
		
		[dataSets addObject:theData];
		
        [self createSubsetForData:theData];
		
		[self updatePath:theData];
        
        [theData addObserver:self
                  forKeyPath:@"color"
                     options:0
                     context:NULL];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dataSetWasUpdated:)
                                                     name:DPDataSetUpdatedNotification
                                                   object:theData];
        
        needsUpdate = YES;
		
	}
	
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if([dataSets count] > 0)
    {
        if ([keyPath isEqual:@"color"]) {
            
            TimeCodedData *data = (TimeCodedData*)object;
            
            CALayer *indicator = [indicatorLayers objectForKey:[data uuid]];
            CGColorRef color = [[data color] createCGColor];
            indicator.backgroundColor = color;
            CGColorRelease(color);
            
            DPSpatialPathLayer *path = [pathLayers objectForKey:[data uuid]];
            path.strokeColor = [data color];
            
            
        }
        else if (object == self)
        {
            for(SpatialTimeSeriesData *data in dataSets)
            {
                [self updatePath:data];
            }
            [self setCurrentTime:[[AppController currentApp] currentTime]];
        }
        else if ([object isKindOfClass:[DPSpatialDataBase class]])
        {
            if(staticPaths)
            {
                for(DPSpatialPathLayer *path in [pathLayers allValues])
                {
                    path.entirePathNeedsRedraw = YES;
                }
            }
            [self forceUpdate];
        }
    }
}

- (void)dataSetWasUpdated:(NSNotification *)aNotification
{
    id dataSet = [aNotification object];
    
    if([dataSets containsObject:dataSet])
    {
        SpatialTimeSeriesData *theData = (SpatialTimeSeriesData*)dataSet;
        
        [self createSubsetForData:theData];
        
        needsUpdate = YES;
        
        [self updatePath:theData];
    }
}

- (void)createSubsetForData:(SpatialTimeSeriesData*)theData
{
    int subsetTarget = 2000;
    
    NSArray *subset;
    
    if(!subsetData || ([[theData dataPoints] count] < subsetTarget))
    {
        subset = [[NSArray alloc] initWithArray:[theData dataPoints]];
    }
    else
    {
        int interval = floor((float)[[theData dataPoints] count]/(float)subsetTarget);
        NSMutableArray *subsetArray = [[NSMutableArray alloc] initWithCapacity:[[theData dataPoints] count]/interval];
        
        int i;
        for(i = 0; i < [[theData dataPoints] count]; i += interval)
            //for(TimeCodedDataPoint *point in [data dataPoints])
        {
            [subsetArray addObject:[[theData dataPoints] objectAtIndex:i]];
        }
        [subsetArray sortUsingFunction:afTimeCodedPointSort context:NULL];
        subset = subsetArray;
        NSLog(@"Created Map Subset: %i/%i",[subset count],[[theData dataPoints] count]);
    }
    
    [subsets setObject:subset forKey:[theData uuid]];
    
    [subset release];
}

- (BOOL)removeData:(TimeCodedData*)data
{
    if([dataSets containsObject:data])
    {
        [data removeObserver:self forKeyPath:@"color"];
        [data removeObserver:self forKeyPath:@"xOffset"];
        [data removeObserver:self forKeyPath:@"yOffset"];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:DPDataSetUpdatedNotification
                                                      object:data];
        
        NSString *key = [data uuid];
                
        DPSpatialPathLayer *path = [pathLayers objectForKey:key];
        [path.pathLayer removeFromSuperlayer];
        [pathLayers removeObjectForKey:key];
        
        CALayer *indicatorLayer = [indicatorLayers objectForKey:key];
        [indicatorLayer removeFromSuperlayer];
        [indicatorLayers removeObjectForKey:key];
        
        [subsets removeObjectForKey:key];
        
        [dataSets removeObject:data];
        
        DPSelectionDataSource *selections = [selectionDataSources objectForKey:[data uuid]];
        if(selections)
        {
            [selectionView unlinkSelectionDataSource:selections];
            [selectionDataSources removeObjectForKey:[data uuid]];
        }
        
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)updatePath:(SpatialTimeSeriesData*)data
{	
//	[self updatePixelMappings];
	
	NSArray *subset = [subsets objectForKey:[data uuid]];
	
    CALayer *indicatorLayer = [CALayer layer];
	
    
    if([data isKindOfClass:[OrientedSpatialTimeSeriesData class]])
    {
        CGFloat indicatorwidth = 15;
        CGFloat indicatorheight = 20;
        [indicatorLayer setBounds:CGRectMake(0, 0, indicatorwidth, indicatorheight)];
        NSBezierPath *indicatorShape = [[NSBezierPath alloc] init];
        [indicatorShape moveToPoint:NSMakePoint(1,1)];
        [indicatorShape lineToPoint:NSMakePoint(indicatorwidth/2.0, (indicatorheight - 1.0))];
        [indicatorShape lineToPoint:NSMakePoint(indicatorwidth - 1.0, 1)];
        [indicatorShape closePath];
        
        [indicatorLayer setValue:indicatorShape forKey:@"indicatorShape"];
        [indicatorLayer setValue:data forKey:@"indicatorData"];
        
        [indicatorShape release];
        
        [indicatorLayer setDelegate:self];
        [indicatorLayer setNeedsDisplay];
    }
    else
    {
        [indicatorLayer setBounds:CGRectMake(0, 0, indicatorSize, indicatorSize)];
    	CGColorRef pathColor = [[data color] createCGColor];
        [indicatorLayer setBackgroundColor:pathColor];
        CGColorRelease(pathColor);
        
        CGColorRef borderColor = CGColorCreateGenericRGB(0.9, 0.9, 0.9, 1.0);
        [indicatorLayer setBorderColor:borderColor];
        CGColorRelease(borderColor);
        
        [indicatorLayer setCornerRadius:(indicatorSize * .33)];
        [indicatorLayer setBorderWidth:1.5];
    }
	
	[indicatorLayer setShadowOpacity:0.6];
	[indicatorLayer setShadowOffset:CGSizeZero];
	[[indicatorLayers objectForKey:[data uuid]] removeFromSuperlayer];
	[indicatorLayers setObject:indicatorLayer forKey:[data uuid]];
	
    DPSpatialPathLayer *pathLayer = [[DPSpatialPathLayer alloc] init];
    pathLayer.spatialView = self;
    pathLayer.pathData = data;
    pathLayer.pathSubset = subset;
    
    pathLayer.strokeColor = [[data color] colorWithAlphaComponent:pathOpacity];
    if(staticPaths)
    {
        pathLayer.tailTime = -1;
        pathLayer.entirePathNeedsRedraw = YES;
        pathLayer.entirePath = YES;
    }
    else if(aggregatePaths)
    {
        pathLayer.tailTime = -1;
        pathLayer.entirePath = NO;
    }
    else
    {
        pathLayer.tailTime = pathTailTime;
        pathLayer.entirePath = NO;
    }
    
    if(blurPaths)
    {
        pathsGroupLayer.filters = pathsFilters;
    }
    else
    {
        pathsGroupLayer.filters = nil;
    }
    pathLayer.connected = connectedPaths;
    
    //pathLayer.strokeColor = [[data color] colorWithAlphaComponent:0.6];
    //pathLayer.tailTime = 0.5;
    //pathsGroupLayer.filters = pathsFilters;
    //pathLayer.tailTime = -1;
    //pathLayer.connected = NO;
    //[pathLayer.pathLayer setOpacity:0.5];
    //[pathLayer.pathLayer setFrame:NSRectToCGRect([self bounds])];
    [pathLayer.pathLayer setFrame:pathsGroupLayer.bounds];
    [pathLayer.pathLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
    [pathsGroupLayer addSublayer:pathLayer.pathLayer];
    [[[pathLayers objectForKey:[data uuid]] pathLayer] removeFromSuperlayer];
    [pathLayers setObject:pathLayer forKey:[data uuid]];
    [pathLayer release];
    
//	CALayer *pathLayer = [CALayer layer];
//	[pathLayer setFrame:NSRectToCGRect([self bounds])];
//	[pathLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
//	[pathLayer setDelegate:self];
//	[[self layer] addSublayer:pathLayer];
//	[pathLayer setNeedsDisplay];
//	[[pathLayers objectForKey:[data uuid]] removeFromSuperlayer];
//	[pathLayers setObject:pathLayer forKey:[data uuid]];
//	
//	[pathLayer setValue:path forKey:@"path"];
//	[pathLayer setValue:[data color] forKey:@"pathColor"];
    
    if([subset count])
    {
     	[indicatorLayer setValue:[subset objectAtIndex:0] forKey:@"currentPoint"];
        [indicatorLayer setValue:[NSNumber numberWithInt:0] forKey:@"currentIndex"];   
    }
	
	[indicatorGroupLayer addSublayer:indicatorLayer];

	[self update];
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
	
	if(layer == [self layer])
	{
		//[mapImage drawAtPoint:NSMakePoint(0,0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	}
    else if ([layer valueForKey:@"indicatorData"])
    {
        OrientedSpatialTimeSeriesData *data = [layer valueForKey:@"indicatorData"];
        
        NSBezierPath* shape = [layer valueForKey:@"indicatorShape"];
        NSColor *fillColor = [data color];
        [fillColor set];
        [shape fill];
        NSColor *strokeColor = [NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:1.0];
        [strokeColor set];
        [shape setLineWidth:1.5];
        [shape stroke];
        
    }
	else if ([layer valueForKey:@"path"])
	{
		NSBezierPath* path = [layer valueForKey:@"path"];
		NSColor *pathColor = [layer valueForKey:@"pathColor"];
		[pathColor set];
		[path setLineWidth:2.0];
		[path stroke];	
		//NSLog(@"draw layer");
	}
	
	[NSGraphicsContext restoreGraphicsState];
	
	[CATransaction commit];
}

//- (void)updatePixelMappings
//{
//	CGFloat spanX = maxX - minX;
//	CGFloat spanY = maxY - minY;
//	yDataToPixel = [self bounds].size.height/spanY;
//	xDataToPixel = [self bounds].size.width/spanX;
//	
//	if(fixedAspect)
//	{
//		if(yDataToPixel < xDataToPixel)
//		{
//			xDataToPixel = yDataToPixel;
//		}
//		else
//		{
//			yDataToPixel = xDataToPixel;
//		}
//	}
//}

#pragma mark Visualization Options

- (IBAction)togglePathVisiblity:(id)sender
{
	[self setShowPath:!showPath];
	
}

- (void)setShowPath:(BOOL)shouldShowPaths
{
    showPath = shouldShowPaths;
   	for(DPSpatialPathLayer *path in [pathLayers allValues])
	{
		[path.pathLayer setHidden:!showPath];
	} 
}

- (BOOL)showPath
{
    return showPath;
}

- (void)setShowPosition:(BOOL)shouldShowPosition
{
    showPosition = shouldShowPosition;
    [indicatorGroupLayer setHidden:!showPosition];
//    for(CALayer *indicator in [indicatorLayers allValues])
//	{
//		[indicator setHidden:!showPosition];
//	}
}

- (BOOL)showPosition
{
    return showPosition;
}

- (void)setShowConnections:(BOOL)shouldShowConnections
{
    showConnections = shouldShowConnections;
    if(showConnections)
    {
        if([pathConnections count] == 0)
        {
            [self createDefaultConnections];
        }
    }
    else
    {
        for(DPSpatialConnectionsLayer *connection in [pathConnections allValues])
        {
            [connection.linesLayer removeFromSuperlayer];
        }
        [pathConnections removeAllObjects];
    }
}

- (BOOL)showConnections
{
    return showConnections;
}

- (void)setRotation:(int)theRotation
{
    rotation = theRotation;
	
	float rotationValue = (float)rotation * M_PI_2;
	
	CATransform3D rotate = CATransform3DMakeRotation(rotationValue, 0, 0, 1);
	
    [CATransaction begin];
    
    [backgroundLayer setTransform:rotate];
    [indicatorGroupLayer setTransform:rotate];
    [linesGroupLayer setTransform:rotate];
    [pathsGroupLayer setTransform:rotate];
    
	[CATransaction commit];
    
    [self frameDidChange:nil];
}

- (int)rotation
{
    return rotation;
}


#pragma mark Selection

- (IBAction)toggleSelectionMode:(id)sender
{
	if(selectionView)
	{
		[selectionView removeFromSuperview];
		self.selectionView = nil;
	}
	else
	{	
		self.selectionView = [[DPMaskedSelectionView alloc] initWithFrame:[self frame]];
        self.selectionView.dataBase = backgroundProvider;
        
        if(!selectionDataSources)
        {
            selectionDataSources = [[NSMutableDictionary alloc] init];
        }
        
        
        for(TimeCodedData *dataSet in dataSets)
        {
            NSString *uuid = [dataSet uuid];
            DPSelectionDataSource *selectionSource = [selectionDataSources objectForKey:uuid];
            if(!selectionSource)
            {
                // If no selection source loaded, see if one exists already for this data set
                for(DataSource *source in [[AnnotationDocument currentDocument] dataSources])
                {
                    if([source isKindOfClass:[DPSelectionDataSource class]] &&
                       [[[(DPSelectionDataSource*)source originalDataSource] uuid] isEqualToString:uuid])
                    {
                        [selectionDataSources setObject:source forKey:uuid];
                        selectionSource = (DPSelectionDataSource*)source;
                        break;
                    }
                }
            }
            
            if(!selectionSource)
            {
                // No selection source was found, so create one
                selectionSource = [[DPSelectionDataSource alloc] initWithPath:nil];
                [selectionDataSources setObject:selectionSource forKey:uuid];
                [selectionSource release];
                
                [selectionSource setName:[[dataSet name] stringByAppendingString:@" Selections"]];
                selectionSource.originalDataSource = dataSet;
                [[AnnotationDocument currentDocument] addDataSource:selectionSource];

            }
            
            [selectionView linkSelectionDataSource:selectionSource];

        }
        
        
		[selectionView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
		//[selectionView setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
		[[self superview] addSubview:selectionView];
		[selectionView release];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateSelection:)
													 name:DPMaskedSelectionChangedNotification
												   object:selectionView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(removeSelection:)
													 name:DPMaskedSelectionAreaRemovedNotification
												   object:selectionView];
		
	}
}

- (BOOL)showTransitionProbabilities
{
    return selectionView.showTransitions;
}

- (void)setShowTransitionProbabilities:(BOOL)show
{
    if(show != selectionView.showTransitions)
    {
        if(selectionView.showTransitions)
        {
            [selectionView setShowTransitions:NO];
        }
        else if([dataSets count] > 0)
        {
            [selectionView showTransitionsForData:(SpatialTimeSeriesData*)[dataSets lastObject]];
        }
    }
}

- (NSDictionary*)selectedTimeSeries
{
    return [[selectedTimeSeries copy] autorelease];
}

- (void)removeSelection:(NSNotification*)notification
{
    NSString *selectionID = [[notification userInfo] objectForKey:@"selectionID"];
    if(selectionID)
    {
        [selectedTimeSeries removeObjectForKey:selectionID];
    }
}

- (void)updateSelection:(id)sender
{
    if(selectionView && [selectionView currentSelection])
    {
        
        NSString *selectionID = [[selectionView currentSelection] guid];
        CGRect area = [[selectionView currentSelection] area];
        
        if(CGRectIsNull(area))
        {
            [selectedTimeSeries removeObjectForKey:selectionID];
        }
        else
        {        
            NSMutableDictionary *selections = [selectedTimeSeries objectForKey:selectionID];
            if(!selections)
            {
                selections = [[NSMutableDictionary alloc] initWithCapacity:[dataSets count]];
                [selectedTimeSeries setObject:selections forKey:selectionID];
            }
            
            [selections removeAllObjects];
            
            for(SpatialTimeSeriesData *dataSet in dataSets)
            {
                DPSelectionDataSource *selectionSource = [selectionDataSources objectForKey:[dataSet uuid]];
                TimeSeriesData* dataToRemove = nil;
                for(TimeSeriesData* existing in [selectionSource dataSets])
                {
                    if([[existing name] isEqualToString:[selectionView currentSelection].name])
                    {
                        dataToRemove = existing;
                        break;
                    }
                }
                
                if(dataToRemove)
                {
                    [selectionSource removeDataSet:dataToRemove];
                }
                
                NSArray *dataArray = [dataSet dataPoints];
                NSMutableArray *timeSeriesData = [NSMutableArray arrayWithCapacity:[dataArray count]];
                
                
                for(TimeCodedSpatialPoint *point in dataArray)
                {
                    
                    TimeCodedDataPoint *dataPoint = [[TimeCodedDataPoint alloc] init];
                    if(CGRectContainsPoint(area, CGPointMake(point.x,point.y)))
                    {
                        [dataPoint setValue:1.0];
                    }
                    else
                    {
                        [dataPoint setValue:0.0];
                    }
                    
                    [dataPoint setTime:[point time]];
                    [timeSeriesData addObject:dataPoint];
                                        
                    [dataPoint release];		
                }
                
                if(selectionView.showTransitions)
                {
                    [selectionView showTransitionsForData:dataSet];
                }
                                
                TimeSeriesData *timeSeries = (TimeSeriesData*)[selectionSource dataForSelection:[selectionView currentSelection]];
                if(!timeSeries)
                {
                    timeSeries = [[TimeSeriesData alloc] initWithDataPointArray:timeSeriesData];
                    if([dataSets count] > 1)
                    {
                        [timeSeries setColor:[dataSet color]];
                    }
                    else
                    {
                        [timeSeries setColor:[selectionView currentSelection].color];
                    }
                    [timeSeries setName:[selectionView currentSelection].name];
                    [selections setObject:timeSeries forKey:[dataSet uuid]];
                    [timeSeries setSource:[dataSet source]];
                    [timeSeries release];
                    
                    [selectionSource setData:timeSeries forSelection:[selectionView currentSelection]];
                }
                else
                {
                    [timeSeries addPoints:timeSeriesData];
                    [[NSNotificationCenter defaultCenter] postNotificationName:DataSourceUpdatedNotification object:selectionSource];

                }
                
                
//                TimeSeriesData *timeSeries = [[TimeSeriesData alloc] initWithDataPointArray:timeSeriesData];
//                [timeSeries setColor:[selectionView currentSelection].color];
//                [timeSeries setName:[selectionView currentSelection].name];
//                [selections setObject:timeSeries forKey:[dataSet uuid]];
//                [timeSeries setSource:[dataSet source]];
//                [timeSeries release];
//                
//                [selectionSource setData:timeSeries forSelection:[selectionView currentSelection]];
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DPMaskedSelectionChangedNotification
         															object:self];
    }
    
}


#pragma mark AnnotationView Methods

-(void)addAnnotation:(Annotation*)annotation
{

}

-(void)addAnnotations:(NSArray*)array
{

}

-(void)removeAnnotation:(Annotation*)annotation
{

}

-(void)updateAnnotation:(Annotation*)annotation
{

}

-(void)setAnnotationFilter:(AnnotationFilter*)filter
{

}

-(AnnotationFilter*)annotationFilter
{
	return nil;
}

-(NSArray*)dataSets
{
	return [[dataSets copy] autorelease];
}

-(void)update
{
    if([[self window] isVisible]
       && (needsUpdate || (CMTIME_COMPARE_INLINE(currentTime, !=, [[AppController currentApp] currentTime]))))
	{
        [self setCurrentTime:[[AppController currentApp] currentTime]];
    }
}

-(void)forceUpdate
{
    [self setCurrentTime:[[AppController currentApp] currentTime]];
}

-(void)setCurrentTime:(CMTime)time
{
//    NSLog(@"Current layers");
//    
//    for(CALayer* sublayer in [[self layer] sublayers])
//    {
//        NSLog(@"%@",[sublayer description]);
//    }
//    
    needsUpdate = NO;
    
    NSTimeInterval currentTimeInterval;
    currentTime = time;
    currentTimeInterval = CMTimeGetSeconds(currentTime);
    
    if([backgroundLayer bounds].size.width < 1.0)
    {
        return;
    }
    
    TimeCodedSpatialPoint *currentTimePoint = [[TimeCodedSpatialPoint alloc] init];
    [currentTimePoint setTime:currentTime];
    
    NSTimeInterval currentPointInterval;
    
    //NSLog(@"Spatial Update Background Bounds: %f %f",[backgroundLayer bounds].size.width,[backgroundLayer bounds].size.height);
    
    [backgroundProvider setDisplayBounds:[backgroundLayer bounds]];
    
    for(SpatialTimeSeriesData *data in dataSets)
    {
        NSArray *subset = [subsets objectForKey:[data uuid]];
        
        CALayer *pathLayer = [[pathLayers objectForKey:[data uuid]] pathLayer];
        CALayer *indicatorLayer = [indicatorLayers objectForKey:[data uuid]];
        if([subset count])
        {        
            
            TimeCodedSpatialPoint *currentPoint = [indicatorLayer valueForKey:@"currentPoint"];
            
            NSInteger closestIndex = [subset binarySearch:currentTimePoint
                                            usingFunction:afTimeCodedPointSort
                                                  context:NULL];	
            
            if(closestIndex < 0)
            {
                closestIndex = -(closestIndex + 2);
            }
            
            if(closestIndex >= [subset count])
            {
                closestIndex = [subset count] - 1;
            }
            
            currentPoint = [subset objectAtIndex:closestIndex];
            
            currentPointInterval = CMTimeGetSeconds(currentPoint.time);
            
            if(fabs(currentPointInterval - currentTimeInterval) > 0.5)
            {
                [indicatorLayer setHidden:YES];
                [pathLayer setHidden:!(staticPaths || aggregatePaths)]; 
            }
            else
            {
                [indicatorLayer setHidden:NO];
                [pathLayer setHidden:!showPath];
            }
            
            [indicatorLayer setValue:currentPoint forKey:@"currentPoint"];
            [indicatorLayer setValue:[NSNumber numberWithInt:closestIndex] forKey:@"currentIndex"];
        }
        else
        {
            [indicatorLayer setHidden:YES];
            [pathLayer setHidden:YES];
        }
    }
    
    [currentTimePoint release];
    
//    [self updatePixelMappings];
    
    [CATransaction flush];
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    
    
    for(SpatialTimeSeriesData *data in dataSets)
    {
        CALayer *indicatorLayer = [indicatorLayers objectForKey:[data uuid]];

        TimeCodedSpatialPoint *currentPoint = [indicatorLayer valueForKey:@"currentPoint"];
        
        if(currentPoint)
        {
            [indicatorLayer setPosition:[backgroundProvider viewPointForSpatialDataPoint:currentPoint withOffsets:CGPointMake(data.xOffset,data.yOffset)]];
            
//            NSLog(@"Current Position: %f %f:",
//                  [backgroundProvider viewPointForSpatialDataPoint:currentPoint withOffsets:CGPointMake(data.xOffset,data.yOffset)].x,
//                  [backgroundProvider viewPointForSpatialDataPoint:currentPoint withOffsets:CGPointMake(data.xOffset,data.yOffset)].y);
            
            if([currentPoint isKindOfClass:[TimeCodedOrientationPoint class]])
            {
                //NSLog(@"Update indicator to angle: %f radians %f",[(TimeCodedOrientationPoint*)currentPoint orientation],[(TimeCodedOrientationPoint*)currentPoint radians]);
                [indicatorLayer setTransform:CATransform3DMakeRotation(-[(TimeCodedOrientationPoint*)currentPoint radians], 0, 0, 1.0)];
            }
        }
    }
    
    if(showPath)
    {       
        [pathsGroupLayer setHidden:NO];
        for(DPSpatialPathLayer *path in [pathLayers allValues])
        {
            if(![path.pathLayer isHidden])
                [path updateForTime:currentTime];
        }
    }
    
    if(showConnections)
    {
        for(DPSpatialConnectionsLayer *connection in [pathConnections allValues])
        {
            if([connection hasVisibleSegments])
            {
                [connection.linesLayer setHidden:NO];
                [connection.linesLayer setNeedsDisplay];
            }
            else
            {
                [connection.linesLayer setHidden:YES];
            }
        }
    }
    
    [CATransaction commit];
	
}

#pragma mark State Recording

-(NSData*)currentState:(NSDictionary*)stateFlags
{	
	NSMutableArray *dataSetIDs = [NSMutableArray array];
	for(TimeCodedData *dataSet in dataSets)
	{
		[dataSetIDs addObject:[dataSet uuid]];
	}
    
    
    NSNumber *invertYState = [NSNumber numberWithBool:self.invertY];
	
    NSNumber *rotationLevel = [NSNumber numberWithInt:rotation];
    
    NSNumber *staticPathsState = [NSNumber numberWithBool:self.staticPaths];
    NSNumber *blurPathsState = [NSNumber numberWithBool:self.blurPaths];
    NSNumber *connectedPathsState = [NSNumber numberWithBool:self.connectedPaths];
    NSNumber *aggregatePathsState = [NSNumber numberWithBool:self.aggregatePaths];
    NSNumber *tailTimeState = [NSNumber numberWithFloat:self.pathTailTime];
    NSNumber *pathOpacityState = [NSNumber numberWithFloat:self.pathOpacity];
    NSNumber *selectionState = [NSNumber numberWithBool:(self.selectionView != nil)];
    NSString *currentSelectionID = (self.selectionView != nil) ? self.selectionView.currentSelection.guid : @"";
    
	return [NSKeyedArchiver archivedDataWithRootObject:[NSDictionary dictionaryWithObjectsAndKeys:
														dataSetIDs,@"DataSetIDs",
                                                        invertYState,@"InvertY",
                                                        //baseData,@"SpatialImageBaseArchive",
//                                                        spatialImageBase,@"SpatialImageBase",
//                                                        spatialImageBaseCoords,@"SpatialImageBaseCoords",
                                                        rotationLevel,@"RotationLevel",
                                                        staticPathsState,@"StaticPathsState",
                                                        blurPathsState,@"BlurPathsState",
                                                        connectedPathsState,@"ConnectedPathsState",
                                                        aggregatePathsState,@"AggregatedPathsState",
                                                        tailTimeState,@"PathTailTimeState",
                                                        pathOpacityState,@"PathOpacityState",
                                                        selectionState,@"SelectionState",
                                                        currentSelectionID,@"CurrentSelectionID",
														nil]];
}

-(BOOL)setState:(NSData*)stateData
{
	NSDictionary *stateDict;
	@try {
		stateDict = [NSKeyedUnarchiver unarchiveObjectWithData:stateData];
	}
	@catch (NSException *e) {
		NSLog(@"Invalid archive, %@", [e description]);
		return NO;
	}
	
	
	NSNumber *invertYState = [stateDict objectForKey:@"InvertY"];
    self.invertY = [invertYState boolValue];

    NSData *baseData = [stateDict objectForKey:@"SpatialImageBaseArchive"];
    DPSpatialDataBase *existingBase = nil;
    if([baseData length] > 0)
    {
        existingBase = [NSKeyedUnarchiver unarchiveObjectWithData:baseData];
    }
    
//    NSString *spatialImageBase = [stateDict objectForKey:@"SpatialImageBase"];
//    if(spatialImageBase && ([spatialImageBase length] > 0))
//    {
//        [self setBackgroundFile:spatialImageBase];
//        //spatialBase.coordinateSpace = NSRectToCGRect([[stateDict objectForKey:@"SpatialImageBaseCoords"] rectValue]);
//    }
    
    NSNumber *rotationLevel = [stateDict objectForKey:@"RotationLevel"];
    if(rotationLevel)
    {
        [self setRotation:[rotationLevel intValue]];
    }
    
    NSNumber *staticPathsState = [stateDict objectForKey:@"StaticPathsState"];
    if(staticPathsState)
    {
        [self setStaticPaths:[staticPathsState boolValue]];
    }
    
    NSNumber *blurPathsState = [stateDict objectForKey:@"BlurPathsState"];
    if(blurPathsState)
    {
        [self setBlurPaths:[blurPathsState boolValue]];
    }
    
    NSNumber *connectedPathsState = [stateDict objectForKey:@"ConnectedPathsState"];
    if(connectedPathsState)
    {
        [self setConnectedPaths:[connectedPathsState boolValue]];
    }
    
    NSNumber *aggregatePathsState = [stateDict objectForKey:@"AggregatedPathsState"];
    if(aggregatePathsState)
    {
        [self setAggregatePaths:[aggregatePathsState boolValue]];
    }
    
    NSNumber *tailTimeState = [stateDict objectForKey:@"PathTailTimeState"];
    if(tailTimeState)
    {
        [self setPathTailTime:[tailTimeState floatValue]];
    }
    
    NSNumber *pathOpacityState = [stateDict objectForKey:@"PathOpacityState"];
    if(pathOpacityState)
    {
        [self setPathOpacity:[pathOpacityState floatValue]];
    }
    
    NSArray* dataSetIDs = [stateDict objectForKey:@"DataSetIDs"];
	for(NSString *uuid in dataSetIDs)
	{
		for(TimeCodedData* dataSet in [[AnnotationDocument currentDocument] dataSets])
		{
			if([[dataSet uuid] isEqualToString:uuid])
			{
                if(([dataSets count] == 0)
                   && [dataSet isKindOfClass:[SpatialTimeSeriesData class]]
                   && existingBase
                   && ![(SpatialTimeSeriesData*)dataSet spatialBase])
                {
                    ((SpatialTimeSeriesData*)dataSet).spatialBase = existingBase;
                }
				[self addData:dataSet];
				break;
			}
		}
	}
    
    NSNumber *selectionState = [stateDict objectForKey:@"SelectionState"];
    if(selectionState && [selectionState boolValue])
    {
        if([[[self window] windowController] respondsToSelector:@selector(toggleSelection:)])
        {
            [[[self window] windowController] toggleSelection:nil];
            [selectionView updateCoordinates];
            [[NSNotificationCenter defaultCenter] postNotificationName:DPMaskedSelectionChangedNotification
                                                                object:self];
        }
        
        NSString *currentSelectionID = [stateDict objectForKey:@"CurrentSelectionID"];
        if(currentSelectionID && ([currentSelectionID length] > 0))
        {
            DPSelectionDataSource *source = [[selectionDataSources allValues] lastObject];
            for(DPMaskedSelectionArea *area in [source selectionAreas])
            {
                if([[area guid] isEqualToString:currentSelectionID])
                {
                    [selectionView setCurrentSelection:area];
                    [selectionView removeSelection:area];
                    break;
                }
            }
            
        }
    }

    
	return YES;
}

#pragma mark Connections

- (void)createDefaultConnections
{
    NSMutableDictionary *defaultConnections = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                               @"Head",@"ShoulderCenter",
                                               @"ShoulderCenter",@"ShoulderLeft",
                                               @"ShoulderCenter",@"ShoulderRight",
                                               @"ShoulderLeft",@"ElbowLeft",
                                               @"ElbowLeft",@"WristLeft",
                                               @"WristLeft",@"HandLeft",
                                               @"ShoulderRight",@"ElbowRight",
                                               @"ElbowRight",@"WristRight",
                                               @"WristRight",@"HandRight",
                                               @"ShoulderCenter",@"Spine",
                                               @"Spine",@"HipCenter",
                                               @"HipCenter",@"HipLeft",
                                               @"HipLeft",@"KneeLeft",
                                               @"KneeLeft",@"AnkleLeft",
                                               @"AnkleLeft",@"FootLeft",
                                               @"HipCenter",@"HipRight",
                                               @"HipRight",@"KneeRight",
                                               @"KneeRight",@"AnkleRight",
                                               @"AnkleRight",@"FootRight",
                                               nil];
    
    for(SpatialTimeSeriesData *dataSet in dataSets)
    {
        DataSource *source = [dataSet source];
        if(![pathConnections objectForKey:[[dataSet source] uuid]])
        {        
            DPSpatialConnectionsLayer *connectionsLayer = [[DPSpatialConnectionsLayer alloc] init];
            connectionsLayer.spatialView = self;
            connectionsLayer.linesLayer = [CALayer layer];
            [connectionsLayer.linesLayer setDelegate:connectionsLayer];
            [connectionsLayer.linesLayer setFrame:NSRectToCGRect([self bounds])];
            [connectionsLayer.linesLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
            connectionsLayer.linesColor = [dataSet color];
            [linesGroupLayer addSublayer:connectionsLayer.linesLayer];
            [pathConnections setObject:connectionsLayer forKey:[dataSet uuid]];
            [connectionsLayer release];
            
            for(NSString *key in [defaultConnections allKeys])
            {
                SpatialTimeSeriesData *start = [self dataSetWithVariable:key andSource:source];
                SpatialTimeSeriesData *end = [self dataSetWithVariable:[defaultConnections objectForKey:key] andSource:source];
                
                if(start && end)
                {
                    [connectionsLayer addConnectionFrom:[indicatorLayers objectForKey:[start uuid]] to:[indicatorLayers objectForKey:[end uuid]]]; 
                }
            }
            
        }
    }
    
    for(DPSpatialConnectionsLayer *connection in [pathConnections allValues])
    {
        [connection.linesLayer setNeedsDisplay];
    }
    
    [defaultConnections release];

}

- (SpatialTimeSeriesData*)dataSetWithVariable:(NSString*)variable andSource:(DataSource*)source
{
    for(SpatialTimeSeriesData *dataSet in dataSets)
    {
        if(([dataSet source] == source) && 
           ([[dataSet variableName] rangeOfString:variable].location != NSNotFound))
        {
            return dataSet;
        }
    }
    return nil;
}

#pragma mark Images


- (NSBitmapImageRep*)bitmapAtTime:(CMTime)time
{
    [self setCurrentTime:time];
    
    [self lockFocus];
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:[self bounds]];
    [self unlockFocus];
    
    return [rep autorelease];
}

- (CGImageRef)frameImageAtTime:(CMTime)time
{
    [self setCurrentTime:time];
    
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    int bitmapByteCount;
    int bitmapBytesPerRow;
    
    int pixelsHigh = (int)[[self layer] bounds].size.height;
    int pixelsWide = (int)[[self layer] bounds].size.width;
    
    bitmapBytesPerRow   = (pixelsWide * 4);
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
    
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
    
    [[self layer] renderInContext:context];
    
    CGImageRef img = CGBitmapContextCreateImage(context);
    [NSMakeCollectable(img) autorelease];
    
    return img;
    
//    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:img];
//    CFRelease(img);     
//    
//    //NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
//    NSData *imageData = [bitmap representationUsingType:NSPNGFileType properties:nil];
//    [imageData writeToFile:[savePanel filename] atomically:NO];
//    
//    [bitmap release];
}

@end
