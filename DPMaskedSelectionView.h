//
//  DPMaskedSelectionView.h
//  ChronoViz
//
//  Created by Adam Fouse on 3/24/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
@class DPMaskedSelectionArea;
@class DPSelectionDataSource;
@class SpatialTimeSeriesData;
@class DPSpatialDataBase;

extern NSString * const DPMaskedSelectionChangedNotification;
extern NSString * const DPMaskedSelectionAreaRemovedNotification;

@interface DPMaskedSelectionView : NSView {

	NSPoint startPoint;
	CGRect maskedRect;
    
    DPMaskedSelectionArea *currentSelection;
    NSMutableArray *maskedAreas;
    
    NSMutableSet *selectionDataSources;
	DPSpatialDataBase *dataBase;
    
	CGColorRef maskColor;
	
	CALayer *outlineLayer;
    
    CALayer *maskLayer;
    CALayer *selectionsLayer;
	NSMutableDictionary *selectionLayers;
    
    BOOL showTransitions;
    SpatialTimeSeriesData *lastTransitionsData;
    CALayer *transitionsLayer;
    NSDictionary *currentTransitions;
    NSMutableArray *currentTransitionArrows;
    NSMutableDictionary *currentTransitionLabels;
    NSString *transitionsTimeRange;
}

@property(retain) DPMaskedSelectionArea* currentSelection;
@property BOOL showTransitions;
@property(retain) NSString *transitionsTimeRange;
@property(retain) DPSpatialDataBase *dataBase;

- (void)updateCoordinates;

- (void)setMaskedRect:(CGRect)theMaskedRect;
- (CGRect)maskedRect;

- (DPMaskedSelectionArea*)newSelectionArea:(id)sender;
- (void)saveCurrentSelection:(id)sender;
- (void)deleteCurrentSelection:(id)sender;

- (void)setCurrentSelection:(DPMaskedSelectionArea*)selection;
- (void)removeSelection:(DPMaskedSelectionArea*)selection;
- (DPMaskedSelectionArea*)currentSelection;
- (NSArray*)selections;

- (void)linkSelectionDataSource:(DPSelectionDataSource*)dataSource;
- (void)unlinkSelectionDataSource:(DPSelectionDataSource*)dataSource;
- (NSSet*)selectionDataSources;

- (void)showTransitionsForData:(SpatialTimeSeriesData*)data;
- (NSDictionary*)transitionProbabilities:(SpatialTimeSeriesData*)dataPoints;

@end
