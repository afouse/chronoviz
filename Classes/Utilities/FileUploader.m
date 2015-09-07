//
//  FileUploader.m
//  DataPrism
//
//  Created by Adam Fouse on 10/5/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "FileUploader.h"


@implementation FileUploader

static FileUploader* standardUploader = nil;

+(FileUploader*)standardFileUploader
{
	if(!standardUploader)
	{
		standardUploader = [[FileUploader alloc] initForHost:@"adamfouse.com" username:@"annotation" password:@"dcoghcilab"];
	}
	return standardUploader;
}

-(id)initForHost:(NSString*)hostname username:(NSString*)username password:(NSString*)password
{
	self = [super init];
	if (self != nil) {
		
		myHost = [[CKHost alloc] init];
			
		[myHost setHost:hostname];
		[myHost setUsername:username];
		[myHost setPassword:password];
		//[myHost setConnectionType:@"sftp"];
	}
	return self;
}

- (void)dealloc
{
	[myConnection release];
	[myHost release];
	
	[super dealloc];
}

-(void)setDelegate:(NSObject*)theDelegate
{
	delegate = theDelegate;
}


-(NSObject*)delegate
{
	return delegate;
}

-(void)uploadFile:(NSString*)file
{
	lastUploadSuccess = NO;
	
	myConnection = [[myHost connection] retain];
	[myConnection setDelegate:self];
	[myConnection connect];
	
//	[KTLogger setLogToConsole:NO];
//	[KTLogger setLoggingLevel:KTLogOff forDomain:KTLogWildcardDomain];
	
	NSLog(@"file: %@",file);
	
	NSDate* start = [NSDate date];
	
	while(![myConnection isConnected])
	{
		if([[NSDate date] timeIntervalSinceDate:start] > 3)
		{
			NSLog(@"Not connected!");
			[self cancelUpload:self];
			return;
		}
	}
	
	NSLog(@"Connected!");

	isUploading = YES;
	
	record = [myConnection recursivelyUpload:file to:[myHost initialPath]];
	
	[myConnection disconnect];
}

-(void)uploadFile:(NSString*)file withProgressSheetForWindow:(NSWindow*)window
{
	if(!statusField)
	{
		[NSBundle loadNibNamed:@"FileUploadSheet" owner:self];
	}
	
	[progressBar setIndeterminate:YES];
	[progressBar setUsesThreadedAnimation:YES];
	[statusField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Connecting to %@", @"connection string"), [myHost host]]];
	[progressBar startAnimation:self];
	
	[NSApp beginSheet:progressSheet
	   modalForWindow:window
		modalDelegate:nil
	   didEndSelector:NULL
		  contextInfo:nil];
	
	[self uploadFile:file];
}

-(void)uploadFile:(NSString*)file withProgressIndicator:(NSProgressIndicator*)indicator
{
	progressBar = indicator;
	
	[self uploadFile:file];
}

-(IBAction)cancelUpload:(id)sender
{
	NSLog(@"End upload");
	if([myConnection isConnected])
	{
			[myConnection cancelTransfer];
	}
	
	isUploading = NO;
	
	if(lastUploadSuccess)
	{		
		if(delegate && [delegate respondsToSelector:@selector(uploadFinished)])
		{
			[delegate uploadFinished];
		}
	}
	else
	{
		if(delegate && [delegate respondsToSelector:@selector(uploadCanceled)])
		{
			[delegate uploadCanceled];
		}
	}
	
	if(progressSheet)
	{
		[NSApp endSheet:progressSheet];
		[progressSheet orderOut:self];
	}

}

-(BOOL)isUploading
{
	return isUploading;
}

-(BOOL)fileUploaded
{
	return lastUploadSuccess;
}

#pragma mark Connection Delegate Methods

//- (void)connection:(id <CKConnection>)connection appendString:(NSString *)string toTranscript:(CKTranscriptType)transcript
//{
//	NSLog(@"transcript: %@",string);
//}

- (NSString *)connection:(id <CKConnection>)con needsAccountForUsername:(NSString *)username
{
	//NSLog(@"Needs account");
	return username;
}

- (void)connection:(id <CKConnection>)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	//NSLog(@"authentication challenge");
	
	NSURLCredential *credential = [challenge proposedCredential];
	
	if ([credential user] && [credential hasPassword])
	{
		[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
	}
	else
	{
		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	}
	
}

- (void)connection:(id <CKConnection>)con didConnectToHost:(NSString *)host
{
	//NSLog(@"Connected to %@",[myHost host]);
	
	[statusField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Connected to %@", @"connected message"), [myHost host]]];
	
	[progressBar setIndeterminate:NO];
	[progressBar setMinValue:0];
	[progressBar setMaxValue:1.0];
	[progressBar setDoubleValue:0.0];
}

- (void)connection:(id <CKConnection>)con didDisconnectFromHost:(NSString *)host
{
	//NSLog(@"Disconnected from %@",[myHost host]);
	
	[statusField setStringValue:NSLocalizedString(@"Disconnected", @"status")];
	
	[self cancelUpload:self];
}

- (void)connection:(id <CKConnection>)con didReceiveError:(NSError *)error
{
	//NSLog(@"Connection error: %@", error);
	if ([[error userInfo] objectForKey:ConnectionDirectoryExistsKey]) 
	{
		return;
	}
	//NSAlert *a = [NSAlert alertWithError:error];
	//[a runModal];
}

- (void)connection:(id <CKConnection>)con upload:(NSString *)remotePath progressedTo:(NSNumber *)aPercent
{
	//NSLog(@"Percent %f",[aPercent floatValue]);

	[progressBar setDoubleValue:[aPercent doubleValue]];
	[statusField setStringValue:[NSString stringWithFormat:@"Uploading: %.2f complete",[aPercent floatValue]]];
	
	if([aPercent floatValue] == 100.0)
	{
		lastUploadSuccess = YES;
	}
}

- (void)connection:(id <CKConnection>)con uploadDidBegin:(NSString *)remotePath
{
	NSLog(@"Upload did begin");
	[statusField setStringValue:[NSString stringWithFormat:@"Uploading to %@",remotePath]];
	
	[progressBar setIndeterminate:NO];
	[progressBar setMinValue:0];
	[progressBar setMaxValue:100.0];
	[progressBar setDoubleValue:0.0];
}

- (void)connection:(id <CKConnection>)con uploadDidFinish:(NSString *)remotePath
{
	NSLog(@"Upload did finish");
	
	lastUploadSuccess = YES;
	
	[self cancelUpload:self];
}

@end
