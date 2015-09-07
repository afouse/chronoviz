//
//  DPSpatialDataFixedAspectBase.h
//  ChronoViz
//
//  Created by Adam Fouse on 11/30/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPSpatialDataBase.h"

@interface DPSpatialDataFixedAspectBase : DPSpatialDataBase {
    CGFloat aspectRatio;
    
    CGFloat xCenterOffset;
    CGFloat yCenterOffset;
}

@property CGFloat aspectRatio;
@property CGFloat xCenterOffset;
@property CGFloat yCenterOffset;

@end
