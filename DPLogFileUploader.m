//
//  DPLogFileUploader.m
//  ChronoViz
//
//  Created by Adam Fouse on 12/9/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "DPLogFileUploader.h"
#import "FileUploader.h"
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
	callbackTarget = target;
	callbackSelector = selector;
	
	BOOL connected = YES;
	SCNetworkReachabilityRef googleTarget;
	googleTarget = SCNetworkReachabilityCreateWithName(NULL,"adamfouse.com");
	if (googleTarget != NULL) {
		SCNetworkConnectionFlags flags;
		
		SCNetworkReachabilityGetFlags(googleTarget, &flags);
		
		if(flags & kSCNetworkFlagsConnectionRequired)
		{
			connected = NO;
		}
		
		CFRelease(googleTarget);
		
		if(!connected)
		{
			return NO;
		}
	}
	
	
	
	NSError *err = nil;
	
	cancelUpload = NO;
	[uploadFile release];
	[argumentList release];
	[logsDirectory release];
	
	NSFileManager *mgr = [NSFileManager defaultManager];
	logsDirectory = [[DataPrismLog defaultLogsDirectory] retain];
	
	NSTask *task = [[NSTask alloc] init];
	[task setCurrentDirectoryPath:logsDirectory];
	[task setLaunchPath:@"/usr/bin/zip"];
	NSString *format = @"%m-%d-%H-%M-%S";
	NSString *date = [[NSDate date] descriptionWithCalendarFormat:format timeZone:nil locale:nil];
	argumentList = [[NSMutableArray array] retain];
	uploadFile = [[NSString stringWithFormat:@"Upload-%@",date] retain];
	[argumentList addObject:uploadFile];
	NSArray *files = [mgr contentsOfDirectoryAtPath:logsDirectory error:&err];
	BOOL filesToUpload = NO;
	for(NSString *file in files)
	{
		if([[file pathExtension] isEqualToString:@"txt"] || [[file pathExtension] isEqualToString:@"xml"] )
		{
			[argumentList addObject:file];
			filesToUpload = YES;
		}
	}
	if(filesToUpload)
	{
		[task setArguments:argumentList];
		NSLog(@"Uploading files at: %@",[task currentDirectoryPath]);
		
		[uploadProgress setUsesThreadedAnimation:YES];
		[uploadProgress setIndeterminate:YES];
		[uploadWindow makeKeyAndOrderFront:self];
		[uploadProgress startAnimation:self];
		
		[task launch];
		[task waitUntilExit];
		if([task terminationStatus] == 0)
		{
			FileUploader *uploader = [FileUploader standardFileUploader];
			[uploader setDelegate:self];
			
			NSString *file = [logsDirectory stringByAppendingPathComponent:[uploadFile stringByAppendingPathExtension:@"zip"]];
			
			[uploader uploadFile:file withProgressIndicator:uploadProgress];
		}
		else
		{
			[self finishUploadAttempt];	
		}
		
		
	}
	
	[task release];
	
    return YES;
}

- (IBAction)cancelUpload:(id)sender
{
	[[FileUploader standardFileUploader] cancelUpload:self];
	
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
