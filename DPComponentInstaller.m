//
//  DPComponentInstaller.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/28/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPComponentInstaller.h"
#import "NSStringFileManagement.h"

@interface DPComponentInstaller (Internal)

- (void)downloadFiles;

- (void)downloadFile:(NSUInteger)index;

- (void)processFiles;

- (BOOL)unzipFile:(NSString*)zipFile;

- (void)cancelDownload:(id)sender;

- (NSWindow*)progressWindow;
- (void)bringToFront;
- (void)closeProgressWindow;

@end


@implementation DPComponentInstaller

@synthesize baseWindow;

- (id) init
{
	self = [super init];
	if (self != nil) {
		remoteFileLocations = [[NSMutableArray alloc] init];
		localFileLocations = [[NSMutableArray alloc] init];
		destinations = [[NSMutableArray alloc] init];
		fileDescriptions = [[NSMutableArray alloc] init];
		
		callbackTarget = 0;
        self.baseWindow = nil;
	}
	return self;
}

- (void) dealloc
{
	[remoteFileLocations release];
	[localFileLocations release];
	[fileDescriptions release];
	[destinations release];
	[super dealloc];
}

- (void)startDownload
{
	if(([remoteFileLocations count] > 0) &&
	   ([remoteFileLocations count] == [localFileLocations count]))
	{
		if([fileDescriptions count] != [remoteFileLocations count])
		{
			[fileDescriptions removeAllObjects];
		}
		
		[self downloadFiles];
	}
}

- (void)setRemoteFiles:(NSArray*)remoteFiles localFiles:(NSArray*)localFiles descriptions:(NSArray*)descriptions
{
	if([remoteFileLocations count] != [localFileLocations count])
	{
		return;
	}
	
	[remoteFileLocations addObjectsFromArray:remoteFiles];
	[localFileLocations addObjectsFromArray:localFiles];
	[fileDescriptions addObjectsFromArray:descriptions];
	
	int index;
	for(index = 0; index < [remoteFileLocations count]; index++)
	{
		NSString *remoteFileLocation = [remoteFileLocations objectAtIndex:index];
		NSString *localFileLocation = [localFileLocations objectAtIndex:index];
		
		if([[remoteFileLocation lastPathComponent] isEqualToString:[localFileLocation lastPathComponent]])
		{
			[destinations addObject:localFileLocation];
		}
		else
		{
			[destinations addObject:[[localFileLocation stringByDeletingLastPathComponent] stringByAppendingPathComponent:[remoteFileLocation lastPathComponent]]]; 
		}
	}
}

- (void)setCallback:(SEL)selector andTarget:(id)target
{
	callbackSelector = selector;
	callbackTarget = target;
}

- (void)downloadFiles;
{
	NSError *err = nil;
	
	for(NSString *localFile in localFileLocations)
	{
		if(![[NSFileManager defaultManager] fileExistsAtPath:[localFile stringByDeletingLastPathComponent]])
		{
			[[NSFileManager defaultManager] createDirectoryAtPath:[localFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&err];
		}
		
		if([localFile fileExists])
		{
			[[NSFileManager defaultManager] removeItemAtPath:localFile error:&err];
		}
	}
	
	currentDownloadIndex = 0;
	
	[self downloadFile:currentDownloadIndex];
}

- (void)downloadFile:(NSUInteger)index
{
	NSString *remotePath = [remoteFileLocations objectAtIndex:index];
	
	NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:remotePath]
												cachePolicy:NSURLRequestUseProtocolCachePolicy
											timeoutInterval:60.0];
	
	NSURLDownload  *theDownload = [[NSURLDownload alloc] initWithRequest:theRequest
																delegate:self];
    if (theDownload) {
		
		clientDownload = theDownload;
		
        [theDownload setDestination:[destinations objectAtIndex:index] allowOverwrite:YES];
		
		[self progressWindow];
		
		if([fileDescriptions count] > 0)
		{
			[progressTextField setStringValue:[NSString stringWithFormat:@"Downloading %@ (%i/%i)…",[fileDescriptions objectAtIndex:index],index + 1,[remoteFileLocations count]]];
		}
		else
		{
			[progressTextField setStringValue:[NSString stringWithFormat:@"Downloading %@ (%i/%i)…",[[[theRequest URL] path] lastPathComponent],index + 1,[remoteFileLocations count]]];
		}
		

		[self bringToFront];
		[progressIndicator setIndeterminate:NO];
		[progressIndicator setUsesThreadedAnimation:YES];
		[progressIndicator startAnimation:self];
		[progressIndicator setMaxValue:100];
		[progressIndicator setMinValue:0];
		[progressIndicator setDoubleValue:1];
		
		[cancelButton setAction:@selector(cancelDownload:)];
		[cancelButton setTarget:self];
		
    } else {
		NSLog(@"Error starting download");
    }
}

- (void)processFiles
{
	int index;
	for(index = 0; index < [destinations count]; index++)
	{
		NSString *file = [destinations objectAtIndex:index];
		if([[file pathExtension] caseInsensitiveCompare:@"zip"] == NSOrderedSame)
		{
			BOOL result = [self unzipFile:file];
			if(!result)
			{
				NSLog(@"Error expanding file: %@",file);
			}
		}
	}
	
	if(callbackTarget)
	{
		[callbackTarget performSelector:callbackSelector];
	}
	
	[self bringToFront];
    
    if(self.baseWindow)
    {
        [self closeProgressWindow];
    }
    else
    {
        [progressTextField setStringValue:@"Install Complete!"];
        [progressIndicator setHidden:YES];
        [cancelButton setTitle:@"OK"];
        [cancelButton setAction:@selector(closeProgressWindow)];
        [cancelButton setTarget:self];
    }

}

- (BOOL)unzipFile:(NSString*)zipFile
{
	BOOL result = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:zipFile] 
       && [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/unzip"])
	{
		[self bringToFront];
		[progressTextField setStringValue:@"Installing Components…"];
		[progressIndicator setIndeterminate:YES];
		[progressIndicator setUsesThreadedAnimation:YES];
		[progressIndicator startAnimation:self];
		[progressIndicator setMaxValue:100];
		[progressIndicator setMinValue:0];
		[progressIndicator setDoubleValue:100];
		
		NSError *err = nil;
		NSTask *task = [[NSTask alloc] init];
		[task setCurrentDirectoryPath:[zipFile stringByDeletingLastPathComponent]];
		[task setLaunchPath:@"/usr/bin/unzip"];
		[task setArguments:[NSArray arrayWithObject:[zipFile lastPathComponent]]];
		[task launch];
		[task waitUntilExit];
		
		[[NSFileManager defaultManager] removeItemAtPath:zipFile error:&err];
		
		if([task terminationStatus] == 0)
		{
			result = YES;
		}
		
		[task release];	
	}		
	return result;
}

- (void)cancelDownload:(id)sender
{
	[clientDownload cancel];
	[clientDownload release];
	
	[self closeProgressWindow];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    // Release the connection.
    [download release];
	
    // Inform the user.
    NSLog(@"Download failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    // Release the connection.
    [download release];
	[downloadResponse release];
	downloadResponse = nil;
	
	if(currentDownloadIndex < ([remoteFileLocations count] - 1))
	{
		currentDownloadIndex++;
		[self downloadFile:currentDownloadIndex];
	}
	else
	{
		[self processFiles];
	}

}

- (void)setDownloadResponse:(NSURLResponse *)aDownloadResponse
{
    [aDownloadResponse retain];
	
    // downloadResponse is an instance variable defined elsewhere.
    [downloadResponse release];
    downloadResponse = aDownloadResponse;
}


- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
    // Reset the progress, this might be called multiple times.
    // bytesReceived is an instance variable defined elsewhere.
    bytesReceived = 0;
	
    // Retain the response to use later.
    [self setDownloadResponse:response];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length
{
    long long expectedLength = [downloadResponse expectedContentLength];
	
    bytesReceived = bytesReceived + length;
	
    if (expectedLength != NSURLResponseUnknownLength) {
        // If the expected content length is
        // available, display percent complete.
        float percentComplete = (bytesReceived/(float)expectedLength)*100.0;
		[progressIndicator setDoubleValue:percentComplete];
    }
}


- (NSWindow*)progressWindow
{
	if(!progressWindow)
	{
		progressWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(200,400,480,120)
													 styleMask:NSTitledWindowMask
													   backing:NSBackingStoreBuffered
														 defer:NO];
		[progressWindow center];
		[progressWindow setLevel:NSStatusWindowLevel];
		[progressWindow setReleasedWhenClosed:NO];
		
		progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(18, 56, 444, 20)];
		
		cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(370,12,96,32)];
		[cancelButton setBezelStyle:NSRoundedBezelStyle];
		[cancelButton setTitle:@"Cancel"];
		[cancelButton setAction:@selector(stopListening:)];
		[cancelButton setTarget:self];
		
		progressTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(17, 84, 444, 17)];
		[progressTextField setStringValue:@"Starting Bluetooth Pen Connection…"];
		[progressTextField setEditable:NO];
		[progressTextField setDrawsBackground:NO];
		[progressTextField setBordered:NO];
		[progressTextField setAlignment:NSLeftTextAlignment];
		
		[[progressWindow contentView] addSubview:progressIndicator];
		[[progressWindow contentView] addSubview:cancelButton];
		[[progressWindow contentView] addSubview:progressTextField];
        
        if(self.baseWindow)
        {
            [NSApp beginSheet:progressWindow
               modalForWindow:self.baseWindow
                modalDelegate:nil
               didEndSelector:NULL
                  contextInfo:nil];
        }
    }
    



	return progressWindow;
}

- (void)bringToFront
{
    if(self.baseWindow)
    {
        [self.baseWindow makeKeyAndOrderFront:self];
    }
    else
    {
        [self bringToFront];
    }
}

- (void)closeProgressWindow
{
    if(self.baseWindow)
    {
        [NSApp endSheet:progressWindow];
        [progressWindow orderOut:self];
    }
    else
    {
        [[self progressWindow] close];
    }
}

@end
