//
//  ImageSequenceDataSource.h
//  ChronoViz
//
//  Created by Adam Fouse on 1/19/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import "DataSource.h"

@interface DPImageSequenceDataSource : DataSource {

	NSInteger imageFileColumn;
	NSDate *startDate;
	
}

- (NSArray*)imageFiles;

@end
