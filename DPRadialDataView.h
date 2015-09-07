//
//  DPRadialDataView.h
//  ChronoViz
//
//  Created by Adam Fouse on 9/8/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationView.h"
#import "DPStateRecording.h"
@class TimeCodedData;
@class TimeCodedSpatialPoint;

@interface DPRadialDataView : NSView { //<AnnotationView,DPStateRecording> {
	
	NSImage *backgroundImage;
	
	QTTime currentTime;
	
	NSMutableArray* annotations;
	NSMutableArray* annotationLayers;
	BOOL annotationsVisible;
	
	CALayer *backgroundLayer;
    CALayer *indicatorGroupLayer;
    CALayer *linesGroupLayer;
    CALayer *pathsGroupLayer;
	
	NSMutableArray *dataSets;
	NSMutableDictionary *subsets;
	NSMutableDictionary *pathLayers;
	NSMutableDictionary *indicatorLayers;
	NSMutableDictionary *paths;
    NSMutableDictionary *pathConnections;
	
	CGFloat width;
	CGFloat height;
	
	CGFloat minX;
	CGFloat minY;
	CGFloat maxX;
	CGFloat maxY;
	
	CGFloat xDataToPixel;
	CGFloat yDataToPixel;
	
	BOOL autoBounds;
	BOOL fixedAspect;
	
	BOOL dragTool;
	
	BOOL showPath;
    BOOL showPosition;
    BOOL showConnections;
    
}

//- (void)addData:(TimeCodedData*)theData;
//- (void)setBackgroundFile:(NSString*)file;
//- (IBAction)togglePathVisiblity:(id)sender;
//
//- (CGPoint)viewPointForDataPoint:(CGPoint)dataPoint;
//- (CGPoint)viewPointForSpatialDataPoint:(TimeCodedSpatialPoint*)dataPoint;

@end
