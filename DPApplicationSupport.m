//
//  DPApplicationSupport.m
//  ChronoViz
//
//  Created by Adam Fouse on 5/24/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPApplicationSupport.h"
#import "NSStringFileManagement.h"

@implementation DPApplicationSupport

+ (NSString*)userSupportFolder
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSArray *libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *oldSupportDir = [[libraryPath lastObject] stringByAppendingPathComponent:@"Application Support/DataPrism"];
	NSString *supportDir = [[libraryPath lastObject] stringByAppendingPathComponent:@"Application Support/ChronoViz"];
	
	
	if([fileManager fileExistsAtPath:oldSupportDir])
	{
		NSError *err = nil;
		BOOL result = [fileManager moveItemAtPath:oldSupportDir toPath:supportDir error:&err];
		if(!result)
		{
			NSAlert *alert = [NSAlert alertWithError:err];
			[alert runModal];			
		}
	}
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:supportDir])
	{
		NSError *err;
		[[NSFileManager defaultManager] createDirectoryAtPath:supportDir withIntermediateDirectories:YES attributes:nil error:&err];
	}
	
	return supportDir;
}

@end
