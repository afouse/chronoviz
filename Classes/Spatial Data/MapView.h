//
//  MapView.h
//  Annotation
//
//  Created by Adam Fouse on 8/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
#import "GeographicTimeSeriesData.h"
#import <WebKit/WebKit.h>
#import "AnnotationView.h"
#import "DPStateRecording.h"
@class AnnotationFilter;

extern NSString * const AFMapTypeNormal;
extern NSString * const AFMapTypeSatellite;
extern NSString * const AFMapTypeHybrid;
extern NSString * const AFMapTypeTerrain;

@interface MapView : NSView <AnnotationView,DPStateRecording> {
	
	WebView* mapView;
	NSImage *mapImage;
	BOOL needsUpdate;
	NSDate *updateDate;
	NSString *mapType;
	BOOL rotated;
    BOOL jsLoaded;
	
	CMTime currentTime;
	
	NSPoint dragOffset;
	
	NSMutableArray* annotations;
	NSMutableArray* annotationLayers;
	BOOL annotationsVisible;
    AnnotationFilter* annotationFilter;
	
	CALayer *mapLayer;
	
	NSMutableArray *dataSets;
	NSMutableArray *subsets;
	NSMutableArray *pathLayers;
	NSMutableArray *indicatorLayers;
	NSMutableArray *shadowLayers;
	NSMutableArray *paths;
	
	CGFloat width;
	CGFloat height;
	
	float centerLat;
	float centerLon;
	float minLat;
	float minLon;
	float maxLat;
	float maxLon;
	
	NSTimer *loadTimer;
	BOOL updating;
	
	BOOL dragTool;
	
	BOOL createStatic;
	
	BOOL showPath;
	
	BOOL staticMap;
}

@property BOOL dragTool;
@property BOOL showPath;
@property float minLat;
@property float minLon;
@property float maxLat;
@property float maxLon;

- (void)addData:(GeographicTimeSeriesData*)theData;

- (IBAction)setMapTypeAction:(id)sender;
- (void)setMapType:(NSString*)theType;

- (IBAction)rotate:(id)sender;

- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;

- (IBAction)togglePathVisiblity:(id)sender;

-(void)toggleAnnotations;
-(void)displayAnnotation:(Annotation*)annotation;
-(IBAction)editAnnotationFilters:(id)sender;

- (void)loadMap;
- (void)updateMap;
- (void)updateCoordinates;

- (void)updatePath;

- (void)loadStaticMap;

- (NSArray*)displayedData;

@end
