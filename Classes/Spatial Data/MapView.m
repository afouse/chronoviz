//
//  MapView.m
//  Annotation
//
//  Created by Adam Fouse on 8/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MapView.h"
#import "TimeSeriesData.h"
#import "TimeCodedGeographicPoint.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "NSColorCGColor.h"
#import "Annotation.h"
#import "MapAnnotationLayer.h"
#import "NSArrayAFBinarySearch.h"
#import "AnnotationFilter.h"
#import "AnnotationFiltersController.h"
#import <AVKit/AVKit.h>
#import <SystemConfiguration/SystemConfiguration.h>

NSString * const AFMapTypeNormal = @"google.maps.MapTypeId.ROADMAP";
NSString * const AFMapTypeSatellite = @"google.maps.MapTypeId.SATELLITE";
NSString * const AFMapTypeHybrid = @"google.maps.MapTypeId.HYBRID";
NSString * const AFMapTypeTerrain = @"google.maps.MapTypeId.TERRAIN";

@interface MapView (MapViewViewPrivateMethods)

- (void)resetTrackingAreas;

@end

@implementation MapView

@synthesize dragTool;
@synthesize showPath;
@synthesize minLat;
@synthesize minLon;
@synthesize maxLat;
@synthesize maxLon;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		dataSets = [[NSMutableArray alloc] init];
		subsets  = [[NSMutableArray alloc] init];
		pathLayers  = [[NSMutableArray alloc] init];
		indicatorLayers  = [[NSMutableArray alloc] init];
		paths  = [[NSMutableArray alloc] init];
		shadowLayers = [[NSMutableArray alloc] init];
		
		mapImage = nil;
		mapView = nil;
		mapLayer = nil;
		updateDate = nil;
		rotated = NO;
		dragTool = NO;
		annotationsVisible = NO;
		staticMap = NO;
		showPath = YES;
        jsLoaded = NO;
		mapType = AFMapTypeTerrain;
		centerLat = 32.78;
		centerLon = -117.15;
		
		minLat = 0;
		maxLat = 0;
		minLon = 0;
		maxLon = 0;
		
		annotations = [[NSMutableArray alloc] init];
		annotationLayers = [[NSMutableArray alloc] init];
		
		loadTimer = nil;
		
		createStatic = NO;
		
		[self resetTrackingAreas];
    }
    return self;
}

- (void) dealloc
{
	[mapImage release];
	[dataSets release];
	[subsets release];
	[pathLayers release];
	[indicatorLayers release];
	[shadowLayers release];
	[paths release];
	
	[mapLayer release];
	[annotations release];
	[annotationLayers release];
	[super dealloc];
}

- (void)awakeFromNib
{
    NSWindow *hiddenWindow = nil;
    BOOL showHiddenWindow = NO;
    
    if(showHiddenWindow)
    {
        hiddenWindow = [[NSWindow alloc] initWithContentRect: NSMakeRect(20,20,[self frame].size.width,[self frame].size.height)
                                                             styleMask: NSTitledWindowMask |  NSClosableWindowMask
                                                               backing: NSBackingStoreBuffered
                                                                 defer: NO];
    }
    else
    {
        hiddenWindow = [[NSWindow alloc] initWithContentRect: NSMakeRect(-2000,-2000,[self frame].size.width,[self frame].size.height)
                                                             styleMask: NSTitledWindowMask |  NSClosableWindowMask
                                                               backing: NSBackingStoreBuffered
                                                                 defer: NO];
    }
    

    
	mapView = [[WebView alloc] initWithFrame:NSMakeRect(0,0,[self frame].size.width,[self frame].size.height) frameName:nil groupName:nil];
	[mapView setFrameLoadDelegate:self];
	[mapView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[[hiddenWindow contentView] addSubview:mapView];
	
	//NSURL *mapFileURL = [NSURL URLWithString:@"http://www.andreaandadam.com/annotationmap.html"];
    NSURL *mapFileURL = [NSURL URLWithString:@"http://www.chronoviz.com/map.html"];
	[[mapView mainFrame] loadRequest:[NSURLRequest requestWithURL:mapFileURL]];
    [[[mapView mainFrame] frameView] setAllowsScrolling:NO];
    [mapView setNeedsDisplay:YES];
    if(showHiddenWindow)
    {
        [hiddenWindow makeKeyAndOrderFront:self];
    }
	
	mapLayer = [[CATiledLayer layer] retain];
	[(CATiledLayer*)mapLayer setTileSize:CGSizeMake(512, 512)];
	[mapLayer setDelegate:self];
	mapLayer.contentsGravity = kCAGravityTopLeft;
	mapLayer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
	//mapLayer.anchorPoint = CGPointMake(0, 0);
	
	[mapLayer setBounds:NSRectToCGRect([self bounds])];
	
	[self setWantsLayer:YES];
	//[self setLayer:[CATiledLayer layer]];
	
	[[self layer] setAnchorPoint:CGPointMake(0.5,0.5)];
	[[self layer] setPosition:CGPointMake([self bounds].size.width/2.0, [self bounds].size.height/2.0)];
	[[self layer] setBackgroundColor:CGColorCreateGenericGray(0.2, 1.0)];
	[[self layer] addSublayer:mapLayer];
	[mapLayer setPosition:CGPointMake([self bounds].size.width/2.0, [self bounds].size.height/2.0)];
	//mapLayer.position = CGPointMake(0,0);
	
	[self resetTrackingAreas];

}

-(NSData*)currentState:(NSDictionary*)stateFlags
{	
	NSMutableArray *dataSetNames = [NSMutableArray array];
	for(GeographicTimeSeriesData *dataSet in dataSets)
	{
		[dataSetNames addObject:[dataSet name]];
	}
	
	NSObject *image = nil;
	
	BOOL recordImage = YES;
	
	if(recordImage && mapImage)
	{
		//NSLog(@"Record state with image");
		image = mapImage;
	}
	else
	{
		//NSLog(@"Record state without image");
		image = [NSNull null];
	}
	
	return [NSKeyedArchiver archivedDataWithRootObject:[NSDictionary dictionaryWithObjectsAndKeys:
														dataSetNames,@"DataSetNames",
														mapType,@"MapType",
														image,@"MapImage",
														[NSNumber numberWithFloat:centerLat],@"CenterLat",
														[NSNumber numberWithFloat:centerLon],@"CenterLon",
														[NSNumber numberWithFloat:minLat],@"MinLat",
														[NSNumber numberWithFloat:minLon],@"MinLon",
														[NSNumber numberWithFloat:maxLat],@"MaxLat",
														[NSNumber numberWithFloat:maxLon],@"MaxLon",
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
	
	NSString *type = [stateDict objectForKey:@"MapType"];
	if(type)		
	{
		if([type isEqualToString:AFMapTypeNormal])
		{
			mapType = AFMapTypeNormal;
		}
		else if([type isEqualToString:AFMapTypeTerrain])
		{
			mapType = AFMapTypeTerrain;
		}
		else if([type isEqualToString:AFMapTypeSatellite])
		{
			mapType = AFMapTypeSatellite;
		}
		else if([type isEqualToString:AFMapTypeHybrid])
		{
			mapType = AFMapTypeHybrid;
		}
		else
		{
			mapType = AFMapTypeTerrain;
		}
	}
	
	NSObject *image = [stateDict objectForKey:@"MapImage"];
	if([image isKindOfClass:[NSImage class]])
	{
		NSLog(@"Load saved map image");
		mapImage = (NSImage*)[image retain];
		centerLat = [[stateDict objectForKey:@"CenterLat"] floatValue];
		centerLon = [[stateDict objectForKey:@"CenterLon"] floatValue];
		minLat = [[stateDict objectForKey:@"MinLat"] floatValue];
		minLon = [[stateDict objectForKey:@"MinLon"] floatValue];
		maxLat = [[stateDict objectForKey:@"MaxLat"] floatValue];
		maxLon = [[stateDict objectForKey:@"MaxLon"] floatValue];
		
		[mapLayer setNeedsDisplay];
	}
	
	NSArray* dataSetNames = [stateDict objectForKey:@"DataSetNames"];
	for(NSString *name in dataSetNames)
	{
		for(NSObject* dataSet in [[AnnotationDocument currentDocument] dataSets])
		{
			if([dataSet isKindOfClass:[GeographicTimeSeriesData class]] && [[(GeographicTimeSeriesData*)dataSet name] isEqualToString:name])
			{
				[self addData:(GeographicTimeSeriesData*)dataSet];
				break;
			}
		}
	}	
	
	
	return YES;
}

- (void)setFrame:(NSRect)boundsRect
{
	[super setFrame:boundsRect];
	if(![self inLiveResize])
	{
		NSWindow *mapWindow = [mapView window];
		NSRect frame = [mapWindow frame];
		frame.size = boundsRect.size;
		[mapWindow setFrame:[mapWindow frameRectForContentRect:frame] display:YES];
		
		[self loadMap];
		[self updatePath];
		[mapLayer setNeedsDisplay];
		
		[self resetTrackingAreas];
	}
}


- (void)viewDidEndLiveResize
{
	[self setFrame:[self frame]];
//	[super viewDidEndLiveResize];
//	
//	NSWindow *mapWindow = [mapView window];
//	NSRect frame = [mapWindow frame];
//	frame.size = [self bounds].size;
//	[mapWindow setFrame:[mapWindow frameRectForContentRect:frame] display:YES];	
//
//	[self loadMap];
//	[self updatePath];
//	[mapLayer setNeedsDisplay];
}

- (void)resetTrackingAreas
{
	for(NSTrackingArea* ta in [self trackingAreas])
	{
		[self removeTrackingArea:ta];
	}
	int options = NSTrackingCursorUpdate | NSTrackingActiveInActiveApp;
	NSTrackingArea *ta;
	ta = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
	[self addTrackingArea:ta];
	[ta release];
}

- (void)addData:(GeographicTimeSeriesData*)theData
{
	if(![dataSets containsObject:theData])
	{
	
	int count = [dataSets count];
	if(count == 0)
	{
		[theData setColor:[NSColor blueColor]];
	}
	else if(count == 1)
	{
		[theData setColor:[NSColor redColor]];
	}
	else if (count == 2)
	{
		[theData setColor:[NSColor orangeColor]];
	}
	else if (count == 3)
	{
		[theData setColor:[NSColor cyanColor]];
	}
	
	[dataSets addObject:theData];
	
//	[mapImage release];
//	mapImage = nil;
	//[[self layer] setNeedsDisplay];
	
	BOOL loadMap = YES;
	
	SCNetworkReachabilityRef googleTarget;
	
	googleTarget = SCNetworkReachabilityCreateWithName(NULL,"google.com");
	if (googleTarget != NULL) {
		SCNetworkConnectionFlags flags;
		
		SCNetworkReachabilityGetFlags(googleTarget, &flags);
		
		if((flags & kSCNetworkFlagsConnectionRequired) || [[NSUserDefaults standardUserDefaults] boolForKey:AFUseStaticMapKey])
		{
			loadMap = NO;
			needsUpdate = NO;
			staticMap = YES;
		}
		
		CFRelease(googleTarget);
	}
	
	if(loadMap)
	{
		needsUpdate = YES;	
		
		if (loadTimer == nil) {
			NSLog(@"Start map timer");
			loadTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
														 target:self
													   selector:@selector(updateDisplay:)
													   userInfo:nil
														repeats:YES];
		}
	}
	
	int subsetTarget = 2000;
	
	NSArray *subset;
	
	if([[theData dataPoints] count] < subsetTarget)
	{
		subset = [[NSArray alloc] initWithArray:[theData dataPoints]];
	}
	else
	{
		int interval = floor([[theData dataPoints] count]/(float)subsetTarget);
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
	
	[subsets addObject:subset];
	
	if(!loadMap)
	{
		if(mapImage)
		{
			[self updatePath];
		}
		else
		{
			[self loadStaticMap];
		}		
	}
		
	}
	
	
}

- (BOOL)removeData:(TimeCodedData*)theData
{
	NSUInteger index = [dataSets indexOfObject:theData];
	
	NSLog(@"Map remove data, index: %i",index);
	
	if(index < [subsets count])
	{
		[subsets removeObjectAtIndex:index];
		[dataSets removeObjectAtIndex:index];
		[self updatePath];
		return YES;
	}
	
	return NO;
}

- (void)setData:(GeographicTimeSeriesData*)theData
{
	[self addData:theData];
}

- (NSArray*)displayedData
{
	return [subsets objectAtIndex:0];
}

- (NSArray*)dataSets
{
	return dataSets;
}

- (void)loadStaticMap
{
	NSArray *libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *mapImageCacheFile = [[libraryPath lastObject] stringByAppendingPathComponent:@"Application Support/Annotation/mapImage.jpg"];

	mapImage = [[NSImage alloc] initWithContentsOfFile:mapImageCacheFile];
	[mapLayer setNeedsDisplay];
	
	mapType = AFMapTypeTerrain;
	
	minLat = 33.031693;
	minLon = -117.526932;
	maxLat = 33.325939;
	maxLon = -117.175369;
	
	[self updatePath];

}

- (void)updateMap
{
	needsUpdate = NO;
	id map = [mapView windowScriptObject];
	
	float dataMinLat = FLT_MAX;
	float dataMinLon = FLT_MAX;
	float dataMaxLat = -FLT_MAX;
	float dataMaxLon = -FLT_MAX;
	
	for(GeographicTimeSeriesData* data in dataSets)
	{
		dataMinLat = fminf(dataMinLat, [data minLat]);
		dataMinLon = fminf(dataMinLon, [data minLon]);
		dataMaxLat = fmaxf(dataMaxLat, [data maxLat]);
		dataMaxLon = fmaxf(dataMaxLon, [data maxLon]);
	}
	
	centerLat = (dataMaxLat + dataMinLat)/2.0;
	centerLon = (dataMaxLon + dataMinLon)/2.0;
	
	NSString *zoomString = [NSString stringWithFormat:@"getZoomByBounds(map,new google.maps.LatLngBounds(new google.maps.LatLng(%f,%f),new google.maps.LatLng(%f,%f)));",
							dataMinLat,
							dataMinLon,
							dataMaxLat,
							dataMaxLon];
	NSLog(@"Javascript Command: %@", zoomString);
	
	
	NSNumber* zoomLevel = nil;
	id zoomResult = [map evaluateWebScript:zoomString];
	
	if(zoomResult == [WebUndefined undefined])
	{
		NSLog(@"Page not loaded");
		return;
	}
	else
	{
		zoomLevel = (NSNumber*)zoomResult;
	}
	
	[map evaluateWebScript:[NSString stringWithFormat:@"map.setCenter(new google.maps.LatLng(%f,%f));",centerLat,centerLon]];
    [map evaluateWebScript:[NSString stringWithFormat:@"map.setZoom(%i);",[zoomLevel intValue]]];
	[map evaluateWebScript:[NSString stringWithFormat:@"map.setMapTypeId(%@);",mapType]];
	
    updateDate = [[NSDate date] retain];
    
	[self updatePath];
	
	
}

- (void)updateCoordinates
{
	if(!staticMap)
	{
		id map = [mapView windowScriptObject];
		
		if(map == [WebUndefined undefined])
		{
			return;
		}

		id minLatObj = [map evaluateWebScript:@"map.getBounds().getSouthWest().lat();"];
		id minLonObj = [map evaluateWebScript:@"map.getBounds().getSouthWest().lng();"];
		id maxLatObj = [map evaluateWebScript:@"map.getBounds().getNorthEast().lat();"];
		id maxLonObj = [map evaluateWebScript:@"map.getBounds().getNorthEast().lng();"];
		
		if(minLatObj == [WebUndefined undefined])
		{
			return;
		}
		
		minLat = [minLatObj floatValue];
		minLon = [minLonObj floatValue];
		maxLat = [maxLatObj floatValue];
		maxLon = [maxLonObj floatValue];
		
		centerLat = minLat + (maxLat - minLat)/2.0;
		centerLon = minLon + (maxLon - minLon)/2.0;
		
		NSLog(@"MinLat: %f, MinLon: %f, MaxLat: %f, MaxLon: %f",minLat,minLon,maxLat,maxLon);
	}
	
}

- (void)updatePath
{
	[self updateCoordinates];
	
	if(YES) //if(createStatic)
	{
		NSLog(@"Update Path: MinLat: %f, MinLon: %f, MaxLat: %f, MaxLon: %f",minLat,minLon,maxLat,maxLon);
	}
	
	float spanLat = maxLat - minLat;
	float spanLon = maxLon - minLon;
	float latToPixel = [self bounds].size.height/spanLat;
	float lonToPixel = [self bounds].size.width/spanLon;
	
	int i;
	for(i = 0; i < [paths count]; i++)
	{
		[(CALayer*)[indicatorLayers objectAtIndex:i] removeFromSuperlayer];
		[(CALayer*)[pathLayers objectAtIndex:i] removeFromSuperlayer];
		[(CALayer*)[shadowLayers objectAtIndex:i] removeFromSuperlayer];
	}
	
	[shadowLayers removeAllObjects];
	[indicatorLayers removeAllObjects];
	[pathLayers removeAllObjects];
	[paths removeAllObjects];
	
	i = 0;
	for(NSArray *subset in subsets)
	{
		NSBezierPath *path = [[NSBezierPath alloc] init];
		
		[path setLineJoinStyle:NSRoundLineJoinStyle];
		
		TimeCodedGeographicPoint *first = [subset objectAtIndex:0];
		[path moveToPoint:NSMakePoint(([first lon] - minLon) * lonToPixel, 
									  ([first lat] - minLat) * latToPixel)];
		
		for(TimeCodedGeographicPoint *point in subset)
		{
			[path lineToPoint:NSMakePoint(([point lon] - minLon) * lonToPixel, 
										  ([point lat] - minLat) * latToPixel)];
		}
		
		[paths addObject:path];
		
		CALayer *shadowLayer = [CALayer layer];
		[shadowLayer setFrame:NSRectToCGRect([self bounds])];
		[shadowLayer setAutoresizingMask:(kCALayerMaxXMargin | kCALayerMinYMargin)];
		[shadowLayer setDelegate:self];
		[shadowLayer setShadowOpacity:1.0];
		[shadowLayer setOpacity:0.8];
		[[self layer] addSublayer:shadowLayer];
		[shadowLayer setNeedsDisplay];
		[shadowLayers addObject:shadowLayer];

		NSColor *pathColor = [[dataSets objectAtIndex:i] color];
		
		CALayer *indicatorLayer = [CALayer layer];
		[indicatorLayer setBounds:CGRectMake(0, 0, 10, 10)];
		[indicatorLayer setCornerRadius:3.0];
		CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		//CGFloat components[4] = {0.2f, 0.2f, 0.8f, 0.5f};
		//CGColorRef yellowColor = CGColorCreate(colorSpace, components);
		[indicatorLayer setBackgroundColor:[pathColor createCGColor]];
		CGFloat borderComponents[4] = {0.9f, 0.9f, 0.9f, 1.0f};
		CGColorRef borderColor = CGColorCreate(colorSpace, borderComponents);
		[indicatorLayer setBorderColor:borderColor];
		[indicatorLayer setBorderWidth:1.5];
		[indicatorLayer setShadowOpacity:0.6];
		[indicatorLayer setShadowOffset:CGSizeZero];
		[indicatorLayers addObject:indicatorLayer];
		
		CALayer *pathLayer = [CALayer layer];
		//[pathLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
		[pathLayer setFrame:NSRectToCGRect([self bounds])];
		[pathLayer setAutoresizingMask:(kCALayerMaxXMargin | kCALayerMinYMargin)];
		[pathLayer setDelegate:self];
		CALayer *imgLayer = [self layer];
		[imgLayer addSublayer:pathLayer];
		//[pathLayer setZPosition:100.0];
		[pathLayer setNeedsDisplay];
		[pathLayers addObject:pathLayer];

		[pathLayer setValue:path forKey:@"path"];
		[pathLayer setValue:pathColor forKey:@"pathColor"];
		[shadowLayer setValue:path forKey:@"path"];
		[indicatorLayer setValue:[subset objectAtIndex:0] forKey:@"currentPoint"];
		[indicatorLayer setValue:[NSNumber numberWithInt:0] forKey:@"currentIndex"];
		
		[pathLayer addSublayer:indicatorLayer];
		
		i++;
	}
		
	currentTime = CMTimeMake(-1, 600);
	[self update];
}

- (IBAction)rotate:(id)sender
{
	if([pathLayers count] > 1)
	{
		return;
	}
	
	CALayer *shadowLayer = [shadowLayers objectAtIndex:0];
	CALayer *pathLayer = [pathLayers objectAtIndex:0];
	
	
	CALayer *layer = [self layer];
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:2.0f]
					 forKey:kCATransactionAnimationDuration];
	if(rotated)
	{
		//layer.transform = CATransform3DIdentity;
		//[pathLayer setZPosition:0.0];
		//[pathLayer setValue:[NSNumber numberWithFloat:100.0f] forKeyPath:@"transform.translation.z"];
		
		[mapLayer setValue:[NSNumber numberWithFloat:0.0f] forKeyPath:@"transform.translation.y"];
		[mapLayer setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.rotation.x"];
		
		[shadowLayer setOpacity:0.0];
		[shadowLayer setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.translation.y"];
		[shadowLayer setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.rotation.x"];
		
		[pathLayer setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.translation.y"];
		[pathLayer setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.rotation.x"];
		
		CALayer* annotationLayer;
		for(MapAnnotationLayer *mapAnnotationLayer in annotationLayers)
		{
			annotationLayer = [mapAnnotationLayer annotationLayer];
			[annotationLayer setOpacity:0.5];
			[annotationLayer setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.translation.y"];
			[annotationLayer setValue:[NSNumber numberWithFloat:0] forKeyPath:@"transform.rotation.x"];
		}
		
		rotated = NO;
	}
	else
	{
		CGFloat zDistance = 2000.0;
		CATransform3D sublayerTransform = CATransform3DIdentity;
		//sublayerTransform = CATransform3DTranslate(sublayerTransform, -[layer bounds].size.width/2, 0, 0);
		sublayerTransform.m34 = 1.0 / -zDistance;  
		//sublayerTransform = CATransform3DTranslate(sublayerTransform, [layer bounds].size.width/2, 0, 0);
		layer.sublayerTransform = sublayerTransform;
		
		[mapLayer setValue:[NSNumber numberWithFloat:-20.0f] forKeyPath:@"transform.translation.y"];
		[mapLayer setValue:[NSNumber numberWithFloat:-0.6] forKeyPath:@"transform.rotation.x"];
		
		[shadowLayer setOpacity:0.9];
		[shadowLayer setValue:[NSNumber numberWithFloat:-19.9f] forKeyPath:@"transform.translation.y"];
		[shadowLayer setValue:[NSNumber numberWithFloat:-0.6] forKeyPath:@"transform.rotation.x"];
	
		[pathLayer setValue:[NSNumber numberWithFloat:20.0f] forKeyPath:@"transform.translation.y"];
		[pathLayer setValue:[NSNumber numberWithFloat:-0.6] forKeyPath:@"transform.rotation.x"];

		int n = 1;
		CALayer* annotationLayer;
		for(MapAnnotationLayer *mapAnnotationLayer in annotationLayers)
		{
			annotationLayer = [mapAnnotationLayer annotationLayer];
			[annotationLayer setOpacity:0.7];
			[annotationLayer setValue:[NSNumber numberWithFloat:20 + (n*10.0f)] forKeyPath:@"transform.translation.y"];
			[annotationLayer setValue:[NSNumber numberWithFloat:-0.6] forKeyPath:@"transform.rotation.x"];
			n++;
		}
		
		//[pathLayer setShadowOpacity:0.8];
		rotated = YES;
	}
	
	[CATransaction commit];
}

- (IBAction)zoomIn:(id)sender
{
	id map = [mapView windowScriptObject];
	NSString *zoomString = [NSString stringWithFormat:@"map.setZoom(map.getZoom() + 1);"];
	NSLog(@"Javascript Command: %@",zoomString);
	[map evaluateWebScript:zoomString];
	updateDate = [[NSDate date] retain];
	[CATransaction begin];
	[self updatePath];
	[mapLayer setAffineTransform:CGAffineTransformMakeScale(2.0, 2.0)];
	[CATransaction commit];
	if (loadTimer == nil) {
		loadTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
													 target:self
												   selector:@selector(updateDisplay:)
												   userInfo:nil
													repeats:YES];
	}
}

- (IBAction)zoomOut:(id)sender
{
	id map = [mapView windowScriptObject];
	NSString *zoomString = [NSString stringWithFormat:@"map.setZoom(map.getZoom() - 1);"];
	NSLog(@"Javascript Command: %@",zoomString);
	[map evaluateWebScript:zoomString];
	updateDate = [[NSDate date] retain];
	[CATransaction begin];
	[self updatePath];
	[mapLayer setAffineTransform:CGAffineTransformMakeScale(0.5, 0.5)];
	[CATransaction commit];
	if (loadTimer == nil) {
		loadTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
													 target:self
												   selector:@selector(updateDisplay:)
												   userInfo:nil
													repeats:YES];
	}
}

- (IBAction)togglePathVisiblity:(id)sender
{
	showPath = !showPath;
	
	CALayer *pathLayer;
	CALayer *shadowLayer;
	
	int i;
	for(i = 0; i < [pathLayers count]; i++)
	{
		pathLayer = [pathLayers objectAtIndex:i];
		shadowLayer = [shadowLayers objectAtIndex:i];
		
		[pathLayer setNeedsDisplay];
		
		if(![shadowLayer isHidden])
		{
			[shadowLayer setNeedsDisplay];
		}	
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

	if([pathLayers containsObject:layer] && showPath)
	{
		NSBezierPath* path = [layer valueForKey:@"path"];
		NSColor *pathColor = [layer valueForKey:@"pathColor"];
		[pathColor set];
		[path setLineWidth:2.0];
		[path stroke];	
		NSLog(@"draw layer");
	}
	else if([shadowLayers containsObject:layer] && showPath)
	{
		NSBezierPath* path = [layer valueForKey:@"path"];
		[[NSColor grayColor] set];
		[path setLineWidth:1.0];
		[path stroke];	
	}
	else if(layer == mapLayer)
	{
		//[mapImage drawAtPoint:NSMakePoint(-bounds.size.width/2,-bounds.size.height/2) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
		[mapImage drawAtPoint:NSMakePoint(0,0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
		
		//CGRect boundingBox = CGContextGetClipBoundingBox(ctx);
		
		//[mapImage drawAtPoint:NSPointFromCGPoint(boundingBox.origin) fromRect:NSRectFromCGRect(boundingBox) operation:NSCompositeCopy fraction:1.0];
		
		//NSLog(@"draw map");
	}
	else
	{
		Annotation *annotation = [layer valueForKey:@"annotation"];
		if(annotation)
		{
//			[[NSColor blackColor] set];
//			[path setLineWidth:1.0];
//			[path stroke];	
			
			NSBezierPath *annotationPath = [layer valueForKey:@"annotationPath"];
			[[annotation colorObject] set];
			[annotationPath setLineWidth:6.0];
			[annotationPath stroke];
			
			CALayer *indicator = [[layer sublayers] objectAtIndex:0];
			[indicator setBackgroundColor:[[annotation colorObject] createCGColor]];
			[indicator setBorderColor:CGColorCreateGenericGray(0.1, 1.0)];
			[indicator setBorderWidth:1.5];
		}
		
	}
	
	[NSGraphicsContext restoreGraphicsState];
	
	[CATransaction commit];
}

- (void)setMapTypeAction:(id)sender
{
	id type = [sender representedObject];
	if(type)
	{
		[self setMapType:type];
	}
}

- (void)setMapType:(NSString*)theType
{
	mapType = theType;
	id map = [mapView windowScriptObject];
	NSString *zoomString = [NSString stringWithFormat:@"map.setMapTypeId(%@);",theType];
	NSLog(@"Javascript Command: %@",zoomString);
	[map evaluateWebScript:zoomString];
	updateDate = [[NSDate date] retain];
	if (loadTimer == nil) {
		loadTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
													 target:self
												   selector:@selector(updateDisplay:)
												   userInfo:nil
													repeats:YES];
	}
}

- (void)setTilesLoaded
{
    NSLog(@"Tiles loaded");
    if(updateDate) {
        [updateDate release];
        updateDate = [[NSDate dateWithTimeIntervalSinceNow:-.7] retain];
    }
    
}

- (void)setMapLoaded
{
    NSLog(@"map idle");
    if(!jsLoaded) {
        jsLoaded = YES;
        [self updateMap];
    } else {
        if(updateDate) {
            [updateDate release];
            updateDate = [[NSDate dateWithTimeIntervalSinceNow:-.9] retain];
        }
        /*
        if(updateDate) {
            [updateDate release];
            updateDate = nil;
            [self loadMap];
            if(mapImage)
            {
                [mapLayer setNeedsDisplay];
            }
        }
         */
    }
}

- (void)loadMap
{	
//	NSString *prefix = @"http://maps.google.com/staticmap?";
//	NSString *postfix = @"&size=512x512&key=ABQIAAAALuJC7a-e8H3kfGhseiSaqhSedFgyjx5ylsSp7T3mW7eGIvJLBxQYamT1ujdyvHMC0NB8CV2RucXlow&sensor=false";
//	NSString *content = [NSString stringWithFormat:@"center=%f,%f&span=%f,%f",centerLat,centerLon,spanLat,spanLon];
//	
//	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",prefix,content,postfix]];
//	
//	NSLog(@"URL: %@",[url absoluteString]);
//	[mapImage release];
//	mapImage = [[NSImage alloc] initWithContentsOfURL:url];	
	
	[mapImage release];
	mapImage = nil;
	
    [CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	[mapLayer setAffineTransform:CGAffineTransformIdentity];
    
	[CATransaction commit];
    
	if(jsLoaded)
	{
		id map = [mapView windowScriptObject];
		NSString *jsCmd = @"map.getBounds().getSouthWest().lat();";
		id lat = [map evaluateWebScript:jsCmd];
        if([lat isKindOfClass:[NSNumber class]]) {
            NSLog(@"Map Lat: %f",[lat floatValue]);
		
		if(abs([lat floatValue]) > 0.01)
		{
		
			NSLog(@"Create map image");
			
			//[[mapView window] makeKeyAndOrderFront:self];
			//[mapView lockFocus];
			
            //NSBitmapImageRep *rep = [mapView bitmapImageRepForCachingDisplayInRect:[mapView bounds]];
            
            
            NSSize mySize = mapView.bounds.size;
            NSSize imgSize = NSMakeSize( mySize.width, mySize.height );
            NSBitmapImageRep *bir = [mapView bitmapImageRepForCachingDisplayInRect:[mapView bounds]];
            [bir setSize:imgSize];
            [mapView cacheDisplayInRect:[mapView bounds] toBitmapImageRep:bir];
            mapImage = [[NSImage alloc]initWithSize:imgSize];
            [mapImage addRepresentation:bir];
        
            
			//NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc]
			//						  initWithFocusedViewRect:[mapView bounds]] autorelease];
			
			//[mapView unlockFocus];
			
			//mapImage = [[NSImage alloc] init];
			//[mapImage addRepresentation:rep];
            
			// Store a local cache of the image
			if(createStatic)
			{
				for(NSImageRep *imageRep in [mapImage representations])
				{
					if([imageRep isKindOfClass:[NSBitmapImageRep class]])
					{
						NSArray *libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
						NSString *mapImageCacheFile = [[libraryPath lastObject] stringByAppendingPathComponent:@"Application Support/Annotation/mapImage.jpg"];
						if([[NSFileManager defaultManager] fileExistsAtPath:mapImageCacheFile])
						{
							NSError *err;
							[[NSFileManager defaultManager] removeItemAtPath:mapImageCacheFile error:&err];
						}
						
						NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
						NSData *imageData = [(NSBitmapImageRep*)imageRep representationUsingType:NSJPEGFileType properties:imageProps];
						[imageData writeToFile:mapImageCacheFile atomically:NO];
					}
				}
			}
		}
		}
	}
	
}

-(void)updateDisplay:(NSTimer*)timer
{
	[self update];
}

-(void)update
{
	
	if(updating || !jsLoaded)
		return;
	
	updating = YES;
	
	if(needsUpdate && mapView && jsLoaded)
	{
		[self updateMap];
	}
	if(updateDate)
	{
		if([updateDate timeIntervalSinceNow] < -1)
		{
			[updateDate release];
			updateDate = nil;
			[self loadMap];
			if(mapImage)
			{
				[mapLayer setNeedsDisplay];	
			}
		}
	}
	else if(!mapImage)
	{
		[self loadMap];
		if(mapImage)
		{
			//[[self layer] setNeedsDisplay];
			[mapLayer setNeedsDisplay];
		}
	}
	
	if(loadTimer && !needsUpdate && mapImage && !updateDate)
	{
		[loadTimer invalidate];
		loadTimer = nil;
	}
	
	if(([subsets count] == [indicatorLayers count])
        && (CMTIME_COMPARE_INLINE(currentTime, !=, [[[AppController currentDoc] movie] currentTime])))
	{
		NSTimeInterval currentTimeInterval;
		NSTimeInterval annotationStartTime;
		NSTimeInterval annotationEndTime;
		currentTime = [[[AppController currentDoc] movie] currentTime];
		currentTimeInterval = CMTimeGetSeconds(currentTime);
		float diff = FLT_MAX;
		
		TimeCodedGeographicPoint *currentTimePoint = [[TimeCodedGeographicPoint alloc] init];
		[currentTimePoint setTime:currentTime];
		
		int i;
		for(i = 0; i < [subsets count]; i++)
		{
			diff = FLT_MAX;
			NSArray *subset = [subsets objectAtIndex:i];
			CALayer *indicatorLayer = [indicatorLayers objectAtIndex:i];
			TimeCodedGeographicPoint *currentPoint = [indicatorLayer valueForKey:@"currentPoint"];

			NSInteger closestIndex = [subset binarySearch:currentTimePoint
											usingFunction:afTimeCodedPointSort
												  context:NULL];	
			
			if(closestIndex < 0)
			{
				closestIndex = -(closestIndex + 1);
			}
			
			if(closestIndex >= [subset count])
			{
				closestIndex = [subset count] - 1;
			}
			
			currentPoint = [subset objectAtIndex:closestIndex];

			// 		int index = 0;
//			for(TimeCodedGeographicPoint *point in subset)
//			{
//				pointTimeInterval = CMTimeGetSeconds([point time]);
//				if(fabs(pointTimeInterval - currentTimeInterval) > diff)
//				{
//					currentPoint = point;
//					//NSLog(@"map index: %i,data: %i, diff: %f, fabs: %f",index,i,diff,fabs(pointTimeInterval - currentTimeInterval));
//					break;
//				}
//				else
//				{
//					diff = fabs(pointTimeInterval - currentTimeInterval) + 0.005;
//				}
//				index++;
//			}
			
			[indicatorLayer setValue:currentPoint forKey:@"currentPoint"];
			[indicatorLayer setValue:[NSNumber numberWithInt:closestIndex] forKey:@"currentIndex"];
		}
		
		[currentTimePoint release];
		
		float spanLat = maxLat - minLat;
		float spanLon = maxLon - minLon;
		float latToPixel = [self bounds].size.height/spanLat;
		float lonToPixel = [self bounds].size.width/spanLon;
		
		[CATransaction flush];
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];

		for(CALayer *indicatorLayer in indicatorLayers)
		{
			TimeCodedGeographicPoint *currentPoint = [indicatorLayer valueForKey:@"currentPoint"];
			[indicatorLayer setPosition:CGPointMake(([currentPoint lon] - minLon) * lonToPixel, 
													([currentPoint lat] - minLat) * latToPixel)];
		}
		

		
		for(MapAnnotationLayer *layer in annotationLayers)
		{
			CALayer *annotationIndicator = [layer indicatorLayer];
			Annotation *annotation = [layer valueForKey:@"annotation"];
			annotationStartTime = CMTimeGetSeconds([annotation startTime]);
			annotationEndTime = CMTimeGetSeconds([annotation endTime]);
			
			TimeCodedGeographicPoint *currentPoint;
			if([indicatorLayers count] == 1)
			{
				currentPoint = [[indicatorLayers objectAtIndex:0] valueForKey:@"currentPoint"];
			}
			else
			{
				currentPoint = [annotationIndicator valueForKey:@"currentPoint"];
			}

			if(currentPoint && (currentTimeInterval >= annotationStartTime) && (currentTimeInterval <= annotationEndTime))
			{
				[annotationIndicator setPosition:CGPointMake(([currentPoint lon] - minLon) * lonToPixel, 
															 ([currentPoint lat] - minLat) * latToPixel)];
				[annotationIndicator setHidden:NO];
			}
			else
			{
				[annotationIndicator setHidden:YES];
			}
		}
		
		[CATransaction commit];
	}
	
	
	updating = NO;
}

#pragma mark Annotations

-(void)toggleAnnotations
{
	if(!annotationsVisible)
	{
        annotationsVisible = YES;
        
        
        if(annotationFilter)
        {
            for(Annotation* annotation in [[AppController currentDoc] annotations])
            {
                if([[annotationFilter predicate] evaluateWithObject:annotation])
                {
                    [self addAnnotation:annotation];
                }
            }
        }
        else
        {
            [self addAnnotations:[[AppController currentDoc] annotations]];
        }
		
		for(MapAnnotationLayer *layer in annotationLayers)
		{
			[[layer annotationLayer] setHidden:NO];
		}
		
		
		//		for(CALayer *layer in annotationLayers)
		//		{
		//			[layer setHidden:NO];
		//		}
	}
	else
	{
		
		for(MapAnnotationLayer *layer in annotationLayers)
		{
			[[layer annotationLayer] setHidden:YES];
			[[layer annotationLayer] removeFromSuperlayer];
		}
		
        [annotationLayers removeAllObjects];
		[annotations removeAllObjects];
		
		
		//		for(CALayer *layer in annotationLayers)
		//		{
		//			[layer setHidden:YES];
		//		}
		annotationsVisible = NO;
	}
	
}

-(void)addAnnotation:(Annotation*)annotation
{
	if(annotationsVisible && (minLat != maxLat) && ![annotations containsObject:annotation])
	{
		[annotations addObject:annotation];
		[self displayAnnotation:annotation];
	}
}

-(void)addAnnotations:(NSArray*)array
{
	for(Annotation* annotation in array)
	{
		[self addAnnotation:annotation];
	}
}

-(void)removeAnnotation:(Annotation*)annotation
{
	[annotations removeObject:annotation];
}

-(void)updateAnnotation:(Annotation*)annotation
{
	//[self displayAnnotation:annotation];
	//	for(CALayer *layer in annotationLayers)
	//	{
	//		if([layer valueForKey:@"annotation"] == annotation)
	//		{
	//			[layer setNeedsDisplay];
	//		}
	//	}
}



-(void)setAnnotationFilter:(AnnotationFilter*)filter
{
	if(filter)
	{
		[filter retain];
		[annotationFilter release];
		annotationFilter = filter;
	}
	else
	{
		[annotationFilter release];
		annotationFilter = nil;
	}
    
    if(annotationsVisible)
    {
        [self toggleAnnotations];
        [self toggleAnnotations];
    }
    else if([annotationLayers count])
    {
        [self toggleAnnotations];
        [self toggleAnnotations];
        [self toggleAnnotations];
    }
}

-(AnnotationFilter*)annotationFilter
{
	return annotationFilter;
}

-(IBAction)editAnnotationFilters:(id)sender
{
	AnnotationFiltersController* filtersController = [[AppController currentApp] annotationFiltersController];
    [filtersController attachToAnnotationView:self];
}


-(void)displayAnnotation:(Annotation*)annotation
{
    if([annotation isDuration])
    {
        MapAnnotationLayer *annotationLayer = [[MapAnnotationLayer alloc] initWithAnnotation:annotation];
        [annotationLayers addObject:annotationLayer];
        [annotationLayer release];
        
        [annotationLayer setMapView:self];
        [annotationLayer update];
        [[self layer] addSublayer:[annotationLayer annotationLayer]];
        [[annotationLayer annotationLayer] setHidden:!annotationsVisible];
    }
}

#pragma mark Mouse Events

- (void)mouseDown:(NSEvent *)theEvent
{
	if(dragTool)
	{
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];
		
		[[self layer] setAnchorPoint:CGPointMake(0.5,0.5)];
		[[self layer] setPosition:CGPointMake([self bounds].size.width/2.0, [self bounds].size.height/2.0)];
		
		[CATransaction commit];
		
		NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		dragOffset.x = [self bounds].size.width/2.0 - pt.x;
		dragOffset.y = [self bounds].size.height/2.0 - pt.y;
	}
	else
	{
		float spanLat = maxLat - minLat;
		float spanLon = maxLon - minLon;
		float pixelToLat = spanLat/[self bounds].size.height;
		float pixelToLon = spanLon/[self bounds].size.width;
		
		NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		pt.x = minLon + pt.x * pixelToLon;
		pt.y = minLat + pt.y * pixelToLat;
		
		CGFloat minDist = 5000;
		TimeCodedGeographicPoint *closestPoint = [[subsets objectAtIndex:0] objectAtIndex:0];
		for(TimeCodedGeographicPoint *point in [subsets objectAtIndex:0])
		{
			CGFloat distance = sqrt(powf((pt.x - point.lon),2) + powf((pt.y - point.lat),2));
			if(distance < minDist)
			{
				minDist = distance;
				closestPoint = point;
			}
		}
		
		[[AppController currentApp] moveToTime:[closestPoint time] fromSender:self];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if(dragTool)
	{
		NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		float newCenterLat = centerLat - (maxLat - minLat) * ((dragOffset.y - ([self bounds].size.height/2.0 - pt.y))/[self bounds].size.height);
		float newCenterLon = centerLon - (maxLon - minLon) * ((dragOffset.x - ([self bounds].size.width/2.0 - pt.x))/[self bounds].size.width);
		
		id map = [mapView windowScriptObject];
		
		[map evaluateWebScript:[NSString stringWithFormat:@"map.setCenter(new google.maps.LatLng(%f,%f));",newCenterLat,newCenterLon]];
		
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];
		
		[self layer].position = CGPointMake(pt.x + dragOffset.x, pt.y + dragOffset.y);
		
		[CATransaction commit];
	}
	else
	{
		float spanLat = maxLat - minLat;
		float spanLon = maxLon - minLon;
		float pixelToLat = spanLat/[self bounds].size.height;
		float pixelToLon = spanLon/[self bounds].size.width;
		
		NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		pt.x = minLon + pt.x * pixelToLon;
		pt.y = minLat + pt.y * pixelToLat;
		
		CGFloat minDist = 5000;
		TimeCodedGeographicPoint *closestPoint = [[subsets objectAtIndex:0] objectAtIndex:0];
		for(TimeCodedGeographicPoint *point in [subsets objectAtIndex:0])
		{
			CGFloat distance = sqrt(powf((pt.x - point.lon),2) + powf((pt.y - point.lat),2));
			if(distance < minDist)
			{
				minDist = distance;
				closestPoint = point;
			}
		}
		
		[[AppController currentApp] moveToTime:[closestPoint time] fromSender:self];		
	}	
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if(dragTool)
	{
//		NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
//		centerLat -= (maxLat - minLat) * ((dragOffset.y - ([self bounds].size.height/2.0 - pt.y))/[self bounds].size.height);
//		centerLon -= (maxLon - minLon) * ((dragOffset.x - ([self bounds].size.width/2.0 - pt.x))/[self bounds].size.width);

		[self updateCoordinates];
		
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];	
		[self loadMap];
		[self updatePath];
		[mapLayer setNeedsDisplay];
		[[self layer] setPosition:CGPointMake([self bounds].size.width/2.0, [self bounds].size.height/2.0)];
		[CATransaction commit];
	}
}

-(void)cursorUpdate:(NSEvent *)theEvent
{
	if(dragTool)
	{
		[[NSCursor openHandCursor] set];
	}
	else
	{
		[[NSCursor arrowCursor] set];
	}
    
}

- (void)drawRect:(NSRect)rect 
{
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
    if (
        (selector == @selector(setMapLoaded))
        || (selector == @selector(setTilesLoaded))
    ){
        return NO;
    }
    return YES;
}

#pragma mark WebView Delegate Methods

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
    [windowObject setValue:self forKey:@"chronoVizView"];
}


#pragma mark Contextual Menu

+ (NSMenu *)defaultMenu {
    NSMenu *theMenu = [[[NSMenu alloc] initWithTitle:@"Contextual Menu"] autorelease];
    return theMenu;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    NSMenu *theMenu = [[[NSMenu alloc] initWithTitle:@"Contextual Menu"] autorelease];
	[theMenu setAutoenablesItems:NO];
	
	if(showPath)
	{
		[theMenu addItemWithTitle:@"Hide Path" action:@selector(togglePathVisiblity:) keyEquivalent:@""];
	}
	else
	{
		[theMenu addItemWithTitle:@"Show Path" action:@selector(togglePathVisiblity:) keyEquivalent:@""];
	}
	
	
	if(annotationsVisible)
	{
		[theMenu addItemWithTitle:@"Hide Annotations" action:@selector(toggleAnnotations) keyEquivalent:@""];
	}
	else
	{
		[theMenu addItemWithTitle:@"Show Annotations" action:@selector(toggleAnnotations) keyEquivalent:@""];
	}

    NSMenuItem *item = [theMenu addItemWithTitle:@"Annotation Filters…" action:@selector(editAnnotationFilters:) keyEquivalent:@""];
	[item setTarget:self];
    
	[theMenu addItem:[NSMenuItem separatorItem]];
	
	[theMenu addItemWithTitle:@"Rotate" action:@selector(rotate:) keyEquivalent:@""];
	[theMenu addItem:[NSMenuItem separatorItem]];
	
	item = [theMenu addItemWithTitle:@"Normal Map" action:@selector(setMapTypeAction:) keyEquivalent:@""];
	[item setRepresentedObject:AFMapTypeNormal];
	[item setState:(mapType == AFMapTypeNormal)];
	item = [theMenu addItemWithTitle:@"Satellite Map" action:@selector(setMapTypeAction:) keyEquivalent:@""];
	[item setRepresentedObject:AFMapTypeSatellite];
	[item setState:(mapType == AFMapTypeSatellite)];
	item = [theMenu addItemWithTitle:@"Hybrid Map" action:@selector(setMapTypeAction:) keyEquivalent:@""];
	[item setRepresentedObject:AFMapTypeHybrid];
	[item setState:(mapType == AFMapTypeHybrid)];
	item = [theMenu addItemWithTitle:@"Terrain Map" action:@selector(setMapTypeAction:) keyEquivalent:@""];
	[item setRepresentedObject:AFMapTypeTerrain];
	[item setState:(mapType == AFMapTypeTerrain)];
    return theMenu;
}



@end
