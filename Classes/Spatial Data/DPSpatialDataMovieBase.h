//
//  DPSpatialDataMovieBase.h
//  ChronoViz
//
//  Created by Adam Fouse on 11/30/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPSpatialDataFixedAspectBase.h"
@class VideoProperties;

@interface DPSpatialDataMovieBase : DPSpatialDataFixedAspectBase {
    
    NSString *videoID;
    VideoProperties* video;
    
}

@property(readonly) VideoProperties* video;

- (id)initWithVideo:(VideoProperties*)videoProperties;

@end
