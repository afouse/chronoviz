//
//  SenseCamImport.h
//  Annotation
//
//  Created by Adam Fouse on 11/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import "DataSource.h"

extern NSString * const SenseCamVersionData;
extern NSString * const SenseCamFilenameData;
extern NSString * const SenseCamSystemData;
extern NSString * const SenseCamClockData;
extern NSString * const SenseCamAccelerationData;
extern NSString * const SenseCamTemperatureData;
extern NSString * const SenseCamWhiteLightData;
extern NSString * const SenseCamIRData;
extern NSString * const SenseCamBatteryData;
extern NSString * const SenseCamCameraData;

extern NSString * const SenseCamDataDateColumn;
extern NSString * const SenseCamDataXAccelerationColumn;
extern NSString * const SenseCamDataYAccelerationColumn;
extern NSString * const SenseCamDataZAccelerationColumn;
extern NSString * const SenseCamDataTemperatureColumn;
extern NSString * const SenseCamDataVisibleLightColumn;
extern NSString * const SenseCamDataIRColumn;
extern NSString * const SenseCamDataBatteryColumn;
extern NSString * const SenseCamDataImageFileColumn;
extern NSString * const SenseCamDataImageReasonColumn;

@interface SenseCamDataSource : DataSource {

	NSDate *startDate;
    
    NSUInteger version;
	
}

- (NSArray*)imageFiles;

@end
