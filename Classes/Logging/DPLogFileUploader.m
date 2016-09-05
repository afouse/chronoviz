//
//  DPLogFileUploader.m
//  ChronoViz
//
//  Created by Adam Fouse on 12/9/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "DPLogFileUploader.h"
#import "DataPrismLog.h"
#import "DPConstants.h"
#import <SystemConfiguration/SystemConfiguration.h>


@implementation DPLogFileUploader

static DPLogFileUploader* defaultLogFileUploader = nil;

+ (DPLogFileUploader*)defaultLogFileUploader
{
	if(!defaultLogFileUploader)
	{
		defaultLogFileUploader = [[DPLogFileUploader alloc] init];
	}
	return defaultLogFileUploader;
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		if(!defaultLogFileUploader)
		{
			defaultLogFileUploader = self;
		}
		
		uploadFile = nil;
		argumentList = nil;
		logsDirectory = nil;
	}
	return self;
}

- (void) dealloc
{
	[uploadFile release];
	[argumentList release];
	[super dealloc];
}


- (IBAction)uploadLogFiles:(id)sender
{
	[self uploadLogFilesWithCallbackTarget:nil selector:NULL];
}

- (BOOL)uploadLogFilesWithCallbackTarget:(id)target selector:(SEL)selector
{
	
    return YES;
}

- (IBAction)cancelUpload:(id)sender
{

	
}

- (void)finishUploadAttempt
{
	[uploadFile release];
	[argumentList release];
	[logsDirectory release];
	
	uploadFile = nil;
	argumentList = nil;
	logsDirectory = nil;
	
	[uploadWindow close];
	
	if(callbackTarget)
	{
		[callbackTarget performSelector:callbackSelector];
	}
}

- (void)uploadFinished
{
	NSError *err = nil;
	NSFileManager *mgr = [NSFileManager defaultManager];
	for(NSString *arg in argumentList)
	{
		if([[arg pathExtension] isEqualToString:@"txt"] || [[arg pathExtension] isEqualToString:@"xml"])
		{
			if ([mgr fileExistsAtPath:[logsDirectory stringByAppendingPathComponent:@"Uploaded"]] == NO)
			{
				[mgr createDirectoryAtPath:[logsDirectory stringByAppendingPathComponent:@"Uploaded"] withIntermediateDirectories:YES attributes:nil error:&err];
			}
			
			[mgr moveItemAtPath:[logsDirectory stringByAppendingPathComponent:arg] 
						 toPath:[[logsDirectory stringByAppendingPathComponent:@"Uploaded"] stringByAppendingPathComponent:arg]
						  error:&err];
		}
	}
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:AFLastUploadKey];
	
	[self uploadCanceled];
}

- (void)uploadCanceled
{
	NSError *err = nil;
	[[NSFileManager defaultManager] removeItemAtPath:[logsDirectory stringByAppendingPathComponent:[uploadFile stringByAppendingPathExtension:@"zip"]] error:&err];
	
	[self finishUploadAttempt];
}

@end
