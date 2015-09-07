//
//  ProtoVisExport.h
//  DataPrism
//
//  Created by Adam Fouse on 2/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DPExport.h"
@class TimeSeriesData;
@class VideoProperties;

@interface ProtoVisExport : DPExport {
	
	VideoProperties *video;
	
	NSMutableArray *dataSets;
	NSMutableArray *annotations;
	
	int width;
	int height;
}

@property(assign) VideoProperties* video;
@property int width;
@property int height;

- (void)addDataSet:(TimeSeriesData*)data;

- (void)exportDataToProtoVisFile:(NSString*)file;

@end
