//
//  DPSelectionDataSource.h
//  ChronoViz
//
//  Created by Adam Fouse on 8/1/12.
//
//

#import "InternalDataSource.h"
@class TimeCodedData;
@class DPMaskedSelectionArea;
@class DPSpatialDataBase;
@class SpatialTimeSeriesData;

@interface DPSelectionDataSource : InternalDataSource
{
    NSMutableArray *selectedAreas;
    NSMutableDictionary *selectedData;
    
}

@property(retain) SpatialTimeSeriesData *spatialData;

- (NSArray*)selectionAreas;
- (void)addSelectionArea:(DPMaskedSelectionArea*)selectionArea;
- (void)removeSelectionArea:(DPMaskedSelectionArea*)selectionArea;

- (void)setData:(TimeCodedData*)data forSelection:(DPMaskedSelectionArea*)selectedArea;
- (TimeCodedData*)dataForSelection:(DPMaskedSelectionArea*)selectedArea;

@end
