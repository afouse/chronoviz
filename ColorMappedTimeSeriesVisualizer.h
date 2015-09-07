//
//  ColorMappedTimeSeriesVisualizer.h
//  ChronoViz
//
//  Created by Adam Fouse on 7/20/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
#import "SegmentVisualizer.h"
#import "DPConstants.h"


@interface ColorMappedTimeSeriesVisualizer : SegmentVisualizer {
	
    DPSubsetMethod subsetMethod;
    
    NSMutableArray *loadedDataSets;
	NSMutableArray *subsets;
	NSMutableArray *subsetRanges;
	NSMutableArray *graphLayers;
	NSMutableArray *labelLayers;
	
    NSMutableDictionary *subsetIntervalModes;
    
	NSMutableDictionary *colorMaps;
	CGFloat valueMin;
	CGFloat valueMax;
	
	CGFloat graphHeightMax;
	CGFloat graphHeightMin;
	CGFloat graphHeight;
	CGFloat graphSpace;
	
	// Number of pixels per data point
	CGFloat subsetResolutionRatio;
	
	BOOL createdGraph;
	
	id configurationController;
	
}

- (NSDictionary*)colorMaps;
- (void)setUniformColorMap:(NSGradient*)gradient;
- (void)setColorMap:(NSGradient*)gradient forDataID:(NSString*)dataID;

- (void)setSubsetMethod:(DPSubsetMethod)method;

- (void)createGraph;

- (void)reloadData;

- (void)configureVisualization:(id)sender;

@end
