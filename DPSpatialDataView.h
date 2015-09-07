//
//  DPSpatialDataView.h
//  ChronoViz
//
//  Created by Adam Fouse on 8/30/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationView.h"
#import "DPStateRecording.h"
#import "AnnotationPlaybackControllerView.h"
@class TimeCodedData;
@class TimeCodedSpatialPoint;
@class DPMaskedSelectionView;
@class DPSpatialDataBase;


@interface DPSpatialDataView : AnnotationPlaybackControllerView <AnnotationView,DPStateRecording> {
    
    QTTime currentTime;
	
	NSMutableArray* annotations;
	NSMutableArray* annotationLayers;
	BOOL annotationsVisible;
	
    DPSpatialDataBase *backgroundProvider;
    
	CALayer *backgroundLayer;
    CALayer *indicatorGroupLayer;
    CALayer *linesGroupLayer;
    CALayer *pathsGroupLayer;
	
    NSArray *pathsFilters;
    
	NSMutableArray *dataSets;
	NSMutableDictionary *subsets;
	NSMutableDictionary *pathLayers;
	NSMutableDictionary *indicatorLayers;
    NSMutableDictionary *pathConnections;
    
	CGFloat width;
	CGFloat height;
	
//	CGFloat minX;
//	CGFloat minY;
//	CGFloat maxX;
//	CGFloat maxY;
//	CGFloat xDataToPixel;
//	CGFloat yDataToPixel;
	
    BOOL needsUpdate;
    
	BOOL autoBounds;
	BOOL fixedAspect;
	
	BOOL dragTool;
	
	BOOL showPath;
    BOOL showPosition;
    BOOL showConnections;
    BOOL subsetData;
    
    BOOL connectedPaths;
    BOOL blurPaths;
    BOOL aggregatePaths;
    BOOL staticPaths;
    CGFloat pathTailTime;
    CGFloat pathOpacity;
    CGFloat indicatorSize;
    
    BOOL invertX;
    BOOL invertY;
    int rotation;
    
    DPMaskedSelectionView *selectionView;
    NSMutableDictionary *selectedTimeSeries;
    NSMutableDictionary *selectionDataSources;

}

//@property CGFloat xDataToPixel;
//@property CGFloat yDataToPixel;
//@property CGFloat minX;
//@property CGFloat minY;
//@property CGFloat maxX;
//@property CGFloat maxY;
@property BOOL showPath;
@property BOOL showPosition;
@property BOOL showConnections;
@property BOOL subsetData;

@property BOOL connectedPaths;
@property BOOL blurPaths;
@property BOOL aggregatePaths;
@property BOOL staticPaths;
@property CGFloat pathTailTime;
@property CGFloat pathOpacity;
@property CGFloat indicatorSize;

@property BOOL invertX;
@property BOOL invertY;
@property int rotation;

@property(assign) DPMaskedSelectionView* selectionView;
@property BOOL showTransitionProbabilities;

- (void)addData:(TimeCodedData*)theData;
- (void)setBackgroundFile:(NSString*)file;
- (void)setBackgroundMovie:(QTMovie*)movie;
- (void)setSpatialBase:(DPSpatialDataBase*)spatialBase;
- (DPSpatialDataBase*)spatialBase;
- (IBAction)togglePathVisiblity:(id)sender;

- (void)setCurrentTime:(QTTime)time;
- (void)forceUpdate;

- (IBAction)toggleSelectionMode:(id)sender;
- (NSDictionary*)selectedTimeSeries;

- (CGImageRef)frameImageAtTime:(QTTime)time;
- (NSBitmapImageRep*)bitmapAtTime:(QTTime)time;

@end
