//
//  KinectSpatialDataSource.m
//  ChronoViz
//
//  Created by Adam Fouse on 9/7/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "KinectSpatialDataSource.h"

@implementation KinectSpatialDataSource

+(NSString*)dataTypeName
{
	return @"Kinect Movement Data";
}


+(BOOL)validateFileName:(NSString*)fileName
{
	return (([[fileName pathExtension] caseInsensitiveCompare:@"csv"] == NSOrderedSame)
            && ([fileName rangeOfString:@"_bodyTracking"].location != NSNotFound));
}

-(id)initWithPath:(NSString*)theFile
{
	self = [super initWithPath:theFile];
	if (self != nil) {
		[self setPredefinedTimeCode:YES];
		[self setTimeCoded:YES];
		timeColumn = 0;
	}
	return self;
}

-(NSArray*)possibleDataTypes
{
	return [NSArray arrayWithObjects:
			DataTypeSpatialX,
            DataTypeSpatialY,
			nil];
}

@end
