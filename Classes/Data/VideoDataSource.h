//
//  VideoDataSource.h
//  ChronoViz
//
//  Created by Adam Fouse on 7/13/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DataSource.h"
@class VideoProperties;

@interface VideoDataSource : DataSource {

	VideoProperties *videoProperties;
	
}

@property(readonly) VideoProperties* videoProperties;

-(id)initWithVideoProperties:(VideoProperties*)props;

@end
