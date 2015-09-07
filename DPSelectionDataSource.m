//
//  DPSelectionDataSource.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/1/12.
//
//

#import "DPSelectionDataSource.h"
#import "DPMaskedSelectionArea.h"
#import "SpatialTimeSeriesData.h"

@implementation DPSelectionDataSource

+(NSString*)dataTypeName
{
	return @"Selection Areas";
}

-(id)initWithPath:(NSString*)theFile
{
	self = [super initWithPath:theFile];
	if (self != nil) {
        selectedAreas = [[NSMutableArray alloc] init];
        selectedData = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc
{
    [selectedAreas release];
    [selectedData release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
        self.local = YES;
        self.timeCoded = YES;
        
        selectedAreas = [[coder decodeObjectForKey:@"DPSelectionDataSourceAreas"] mutableCopy];
        
        selectedData = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *areaIDsToDataIDs = [coder decodeObjectForKey:@"DPSelectionDataSourceDataDict"];
        
        for(NSString *areaID in [areaIDsToDataIDs allKeys])
        {
            DPMaskedSelectionArea *selectionArea = nil;
            for(DPMaskedSelectionArea *area in selectedAreas)
            {
                if([areaID isEqualToString:[area guid]])
                {
                    selectionArea = area;
                }
            }
            
            if(!selectionArea)
            {
                continue;
            }
            else
            {            
                NSString *dataID = [areaIDsToDataIDs objectForKey:areaID];
                for(TimeCodedData *data in [self dataSets])
                {
                    if([[data uuid] isEqualToString:dataID])
                    {
                        [selectedData setObject:data forKey:areaID];
                        [data bind:@"name" toObject:selectionArea withKeyPath:@"name" options:nil];
                    }
                }
            }
        }
        
	}
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:selectedAreas forKey:@"DPSelectionDataSourceAreas"];
    
    NSMutableDictionary *areaIDsToDataIDs = [NSMutableDictionary dictionary];
    for(NSString *areaID in [selectedData allKeys])
    {
        TimeCodedData *data = [selectedData objectForKey:areaID];
        [areaIDsToDataIDs setObject:[data uuid] forKey:areaID];
    }
    
    [coder encodeObject:areaIDsToDataIDs forKey:@"DPSelectionDataSourceDataDict"];
    
}

- (NSArray*)selectionAreas
{
    return selectedAreas;
}

- (void)addSelectionArea:(DPMaskedSelectionArea*)selectionArea
{
    [selectedAreas addObject:selectionArea];
}

- (void)removeSelectionArea:(DPMaskedSelectionArea*)selectionArea
{
    [selectedData removeObjectForKey:[selectionArea guid]];
    [selectedAreas removeObject:selectionArea];
}

- (void)setData:(TimeCodedData*)data forSelection:(DPMaskedSelectionArea*)selectedArea
{
    if([selectedData objectForKey:[selectedArea guid]])
    {
        [[selectedData objectForKey:[selectedArea guid]] unbind:@"name"];
        [self removeDataSet:[selectedData objectForKey:[selectedArea guid]]];
    }
    
    [selectedData setObject:data forKey:[selectedArea guid]];
    [data bind:@"name" toObject:selectedArea withKeyPath:@"name" options:nil];
    [self addDataSet:data];
}

- (TimeCodedData*)dataForSelection:(DPMaskedSelectionArea*)selectedArea
{
    return [selectedData objectForKey:[selectedArea guid]];
}

- (SpatialTimeSeriesData*)spatialData
{
    id data = self.originalDataSource;
    if([data isKindOfClass:[SpatialTimeSeriesData class]])
    {
        return (SpatialTimeSeriesData*)data;
    }
    
    return nil;
}

- (void)setSpatialData:(SpatialTimeSeriesData *)spatialData
{
    [self setOriginalDataSource:spatialData];
}

@end
