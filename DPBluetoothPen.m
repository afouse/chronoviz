//
//  DPBluetoothPen.m
//  DataPrism
//
//  Created by Adam Fouse on 6/21/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "DPBluetoothPen.h"
#import "NSStringFileManagement.h"
#import "DPConsole.h"
#import "DPApplicationSupport.h"
#import "EthnographerPlugin.h"
#import <IOBluetooth/IOBluetooth.h>

@interface DPBluetoothPen (Setup)

- (BOOL)setup;
- (NSString*)clientDirectory;
- (NSWindow*)progressWindow;
- (void)installClient;
- (void)upzipClient;
- (void)cancelDownload:(id)sender;

- (void)sendLoadPagesURL:(NSSet*)toLoad;

- (IBAction)openBluetoothPrefs:(id)sender;

- (void)receivedApplicationTerminated:(NSNotification*)notification;
- (void)receivedApplicationStarted:(NSNotification*)notification;

@end

@implementation DPBluetoothPen

@synthesize penMenuItem;

static DPBluetoothPen* defaultPenClient = nil;
static NSString * const mappingsFileKey = @"mappingsFile";
static NSString * const serverXmlFileKey = @"serverXmlFile";
static NSString * const penBrowserBundleIdentifier = @"edu.ucsd.hci.Penbrowser";

+(DPBluetoothPen*)penClient
{
	if(!defaultPenClient)
	{
		defaultPenClient = [[DPBluetoothPen alloc] init];
	}
	return defaultPenClient;
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		progressWindow = nil;
		progressIndicator = nil;
		cancelButton = nil;
		progressTextField = nil;
		
		penBrowserRunning = NO;
		penBrowserPSN.lowLongOfPSN = 0;
		penBrowserPSN.highLongOfPSN = kNoProcess;
				
		clientDirectory = nil;
		
		loadedPages = [[NSMutableSet alloc] init];
		
		if(!defaultPenClient)
		{
			defaultPenClient = self;
		}
	}
	return self;
}

- (void) dealloc
{
	[progressWindow release];
	[progressIndicator release];
	[progressTextField release];
	[cancelButton release];
		
	[clientDirectory release];
	
	[loadedPages release];
	
	[super dealloc];
}

-(void)reset
{
	[self stopListening:self];
}

-(IBAction)startListening:(id)sender
{
	[self setup];
}

-(IBAction)stopListening:(id)sender
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[loadedPages removeAllObjects];
	
	if([progressWindow isVisible])
	{
		[progressIndicator stopAnimation:self];
		[progressWindow close];
	}
	
	[penMenuItem setEnabled:YES];
	
	if([sender isKindOfClass:[NSMenuItem class]])
	{
		[(NSMenuItem*)sender setTitle:@"Start Bluetooth Pen Connection"];
		[(NSMenuItem*)sender setAction:@selector(startListening:)];
	}
	
	if(penBrowserRunning)
	{
		AppleEvent tAppleEvent;
		AppleEvent tReply;
		AEBuildError tAEBuildError;
		OSStatus result;
		
		result = AEBuildAppleEvent( kCoreEventClass, kAEQuitApplication, typeProcessSerialNumber, &penBrowserPSN,
								   sizeof(ProcessSerialNumber), kAutoGenerateReturnID, kAnyTransactionID, &tAppleEvent, &tAEBuildError,"");
		result = AESendMessage( &tAppleEvent, &tReply, kAEAlwaysInteract+kAENoReply, kNoTimeOut);
		
	}
	
}

-(void)loadPages:(NSArray*)pages
{
	if(penBrowserRunning)
	{
		NSMutableSet *toLoad = [NSMutableSet set];
		
		for(NSString *page in pages)
		{
			if(![loadedPages containsObject:page])
			{
				[toLoad addObject:page];
			}
		}
		
		[self sendLoadPagesURL:toLoad];	
	}
}

		
- (void)sendLoadPagesURL:(NSSet*)toLoad
{
	if(penBrowserRunning && ([toLoad count] > 0))
	{
		NSMutableString *url = [NSMutableString stringWithString:@"penbrowser://database?action=addpages&pages="];
		BOOL first = YES;
		for(NSString *page in toLoad)
		{
			if(!first)
			{
				[url appendString:@","];
			}
			[url appendString:page];
			first = NO;
		}
                
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];

		[loadedPages addObjectsFromArray:[toLoad allObjects]];
	}
}
		 
- (NSString*)clientDirectory
{
	if(!clientDirectory)
	{
		//clientDirectory = [[applicationSupportFolder stringByAppendingPathComponent:@"Devices/BTPenClient"] retain];
		clientDirectory = [[[DPApplicationSupport userSupportFolder] stringByAppendingPathComponent:@"Devices/PenBrowser.app"] retain];
	}
	
	return clientDirectory;
}

- (IBAction)openBluetoothPrefs:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Bluetooth.prefPane"];
}

#pragma clang diagnostic push

#pragma clang diagnostic ignored "-Wdeprecated"

- (BOOL)setup
{
	// If it's already running, 
	if(penBrowserRunning)
	{
		return YES;	
	}
	
	BluetoothHCIPowerState powerState;
	IOBluetoothLocalDeviceGetPowerState(&powerState);
	if(!IOBluetoothLocalDeviceAvailable() || (powerState == kBluetoothHCIPowerStateOFF)) {
		NSAlert *bluetoothAlert = [[NSAlert alloc] init];
		[bluetoothAlert setMessageText:@"Bluetooth is currently disabled."];
		[bluetoothAlert setInformativeText:@"Please enable Bluetooth and try to start the pen connection again. You can enable Bluetooth in System Preferences."];
		[bluetoothAlert addButtonWithTitle:@"OK"];
		[bluetoothAlert addButtonWithTitle:@"Open System Preferences"];
		
		NSInteger result = [bluetoothAlert runModal];
		if(result == NSAlertSecondButtonReturn)
		{
			[self openBluetoothPrefs:self];
		}
		[bluetoothAlert release];
		return NO;
    }
	
	[penMenuItem setEnabled:NO];
	
	NSString *clientPath = [self clientDirectory];
	
	if(clientPath && [clientPath fileExists])
	{
		
		[[self progressWindow] makeKeyAndOrderFront:self];
		[progressTextField setStringValue:@"Starting Bluetooth Pen Connection…"];
		[progressIndicator setIndeterminate:YES];
		[progressIndicator setUsesThreadedAnimation:YES];
		[progressIndicator startAnimation:self];
		
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(receivedApplicationStarted:)
																   name:NSWorkspaceDidLaunchApplicationNotification
																 object:nil];
		
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(receivedApplicationTerminated:)
																   name:NSWorkspaceDidTerminateApplicationNotification
																 object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(stopListening:)
													 name:NSApplicationWillTerminateNotification
												   object:nil];
		
		[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:penBrowserBundleIdentifier
															 options:(NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync) 
									  additionalEventParamDescriptor:nil
													launchIdentifier:NULL];
		
		return YES;
	}
	else
	{
		[[self progressWindow] makeKeyAndOrderFront:self];
		
		NSAlert *downloadAlert = [[NSAlert alloc] init];
		[downloadAlert setMessageText:@"The bluetooth pen connection software needs to be downloaded. Would you like to download it now?"];
		[downloadAlert addButtonWithTitle:@"Download Now"];
		[downloadAlert addButtonWithTitle:@"Cancel"];
		
		[downloadAlert beginSheetModalForWindow:[self progressWindow]
								  modalDelegate:self
								 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
									contextInfo:nil];
		
	}
	return NO;
		
}

#pragma clang diagnostic pop

- (void)readFromTask:(NSNotification*)notification
{
	NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	//NSLog(@"Pen Client Read: %@",string);
	
	if([string length] > 0)
	{
		[DPConsole defaultConsoleEntry:string];
		
		if([string rangeOfString:@"Setup OK"].location != NSNotFound)
		{
			[self penBrowserStarted:self];
		}
		else if([string rangeOfString:@"Connected"].location != NSNotFound)
		{
			[self penBrowserConnected:self];
		}
		else
		{
			//NSLog(@"continue reading");
		}
	}
	
	[(NSFileHandle*)[notification object] readInBackgroundAndNotify];
	
	[string release];
}

#pragma mark PenBrowser Events

- (IBAction)penBrowserStarting:(id)sender
{
	
}

- (IBAction)penBrowserStarted:(id)sender
{
	NSLog(@"Pen Startup Complete");
	
	[self loadPages:[[EthnographerPlugin defaultPlugin] currentAnotoPages]];
	
	[progressTextField setStringValue:@"Please tap the pen to start the connection…"];
	[NSApp activateIgnoringOtherApps:YES];
	[progressWindow makeKeyAndOrderFront:self];
}

- (IBAction)penBrowserConnected:(id)sender
{
	[progressIndicator stopAnimation:self];
	[progressWindow close];
	
	[penMenuItem setTitle:@"Stop Bluetooth Pen Connection"];
	[penMenuItem setAction:@selector(stopListening:)];
	[penMenuItem setEnabled:YES];
}

- (void)receivedApplicationTerminated:(NSNotification*)notification
{
	NSDictionary *userInfo = [notification userInfo];
	
	if([[userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:penBrowserBundleIdentifier])
	{
		penBrowserRunning = NO;
		penBrowserPSN.lowLongOfPSN = 0;
		penBrowserPSN.highLongOfPSN = kNoProcess;
	}
}

- (void)receivedApplicationStarted:(NSNotification*)notification
{
	NSDictionary *userInfo = [notification userInfo];
	
	NSLog(@"App Started %@",[userInfo objectForKey:@"NSApplicationBundleIdentifier"]);
	
	if([[userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:penBrowserBundleIdentifier])
	{
		penBrowserPSN.lowLongOfPSN = [[userInfo objectForKey:@"NSApplicationProcessSerialNumberLow"] unsignedLongValue];
		penBrowserPSN.highLongOfPSN = [[userInfo objectForKey:@"NSApplicationProcessSerialNumberHigh"] unsignedLongValue];
		penBrowserRunning = YES;
	}
}



#pragma mark Downloading

/*

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertFirstButtonReturn) 
	{
		//NSLog(@"Install client");
		[self installClient];
    }
	else
	{
		[penMenuItem setEnabled:YES];
		[[self progressWindow] close];
	}
}

- (void)installClient
{
	NSError *err = nil;
	
	NSString *clientFolder = [[DPApplicationSupport userSupportFolder] stringByAppendingPathComponent:@"Devices"];
	if(![[NSFileManager defaultManager] fileExistsAtPath:clientFolder])
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:clientFolder withIntermediateDirectories:YES attributes:nil error:&err];
	}	
	
	if([[self clientDirectory] fileExists])
	{
		[[NSFileManager defaultManager] removeItemAtPath:[self clientDirectory] error:&err];
	}
	
	clientDownloadFile = [[NSString alloc] initWithFormat:@"PenBrowser_%@.zip",DPBluetoothPenRequiredVersion];
	
	NSString *clientURL = [NSString stringWithFormat:@"http://chronoviz.com/penbrowser/%@",clientDownloadFile];
	
	NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:clientURL]
												cachePolicy:NSURLRequestUseProtocolCachePolicy
											timeoutInterval:60.0];
	
	NSURLDownload  *theDownload = [[NSURLDownload alloc] initWithRequest:theRequest
																delegate:self];
    if (theDownload) {
		
		clientDownload = theDownload;
		
        [theDownload setDestination:[clientFolder stringByAppendingPathComponent:clientDownloadFile] allowOverwrite:YES];
		
		[self progressWindow];
		[progressTextField setStringValue:@"Downloading Bluetooth Pen Connection software…"];
		[[self progressWindow] makeKeyAndOrderFront:self];
		[progressIndicator setIndeterminate:NO];
		[progressIndicator setUsesThreadedAnimation:YES];
		[progressIndicator startAnimation:self];
		[progressIndicator setMaxValue:100];
		[progressIndicator setMinValue:0];
		[progressIndicator setDoubleValue:1];
		
		[cancelButton setAction:@selector(cancelDownload:)];
		[cancelButton setTarget:self];
		
    } else {
		// error
    }
}

- (void)unzipClient
{
	NSString *zipFile = [[[DPApplicationSupport userSupportFolder] stringByAppendingPathComponent:@"Devices"] stringByAppendingPathComponent:clientDownloadFile];
	if([[NSFileManager defaultManager] fileExistsAtPath:zipFile])
	{
		NSError *err = nil;
		NSTask *task = [[NSTask alloc] init];
		[task setCurrentDirectoryPath:[zipFile stringByDeletingLastPathComponent]];
		[task setLaunchPath:@"/usr/bin/unzip"];
		[task setArguments:[NSArray arrayWithObject:clientDownloadFile]];
		[task launch];
		[task waitUntilExit];
		
		[[NSFileManager defaultManager] removeItemAtPath:zipFile error:&err];
		
		if([task terminationStatus] == 0)
		{
			[self setup];
		}
		
//		if([task terminationStatus] == 0)
//		{
//			NSTask *chmod = [[NSTask alloc] init];
//			[chmod setCurrentDirectoryPath:[[zipFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"BTPenClient"]];
//			[chmod setLaunchPath:@"/bin/chmod"];
//			[chmod setArguments:[NSArray arrayWithObjects:@"a+x",@"start.sh",@"bin/run.sh",nil]];
//			[chmod launch];
//			[chmod waitUntilExit];
//			
//			if([chmod terminationStatus] == 0)
//			{
//				[self setup];
//			}
//			
//			[chmod release];
//		}
		
		[task release];	
	}		
}

- (void)cancelDownload:(id)sender
{
	[clientDownload cancel];
	[clientDownload release];
	
	[penMenuItem setEnabled:YES];
	[[self progressWindow] close];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    // Release the connection.
    [download release];
	
    // Inform the user.
    NSLog(@"Download failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    // Release the connection.
    [download release];
	[downloadResponse release];
	downloadResponse = nil;
	
	[cancelButton setAction:@selector(stopListening:)];
	[cancelButton setTarget:self];
	
	[self unzipClient];
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
*/	 
		 
- (NSWindow*)progressWindow
{
	if(!progressWindow)
	{
		progressWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(200,400,480,120)
													   styleMask:NSTitledWindowMask
														 backing:NSBackingStoreBuffered
														   defer:NO];
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
	}
	return progressWindow;
}
	

@end
