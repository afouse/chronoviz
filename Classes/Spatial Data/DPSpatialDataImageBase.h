//
//  DPSpatialDataImageBase.h
//  ChronoViz
//
//  Created by Adam Fouse on 10/11/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPSpatialDataFixedAspectBase.h"

@interface DPSpatialDataImageBase : DPSpatialDataFixedAspectBase {

    NSString *imageFilePath;
    
    NSObject *backgroundDelegate;
    
}

@property(copy) NSString* imageFilePath;

- (id)initWithBackgroundFile:(NSString*)imageFile;


@end
