//
//  DPComponentInstaller.h
//  ChronoViz
//
//  Created by Adam Fouse on 8/28/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DPComponentInstaller : NSObject {

	NSMutableArray *remoteFileLocations;
	NSMutableArray *destinations;
	NSMutableArray *localFileLocations;
	NSMutableArray *fileDescriptions;
	
	SEL callbackSelector;
	id callbackTarget;
	
	NSUInteger currentDownloadIndex;
	
	NSWindow *progressWindow;
	NSProgressIndicator *progressIndicator;
	NSButton *cancelButton;
	NSTextField *progressTextField;
	
	NSURLDownload *clientDownload;
	NSURLResponse *downloadResponse;
	long long bytesReceived;
    
    NSWindow *baseWindow;
	
}

@property(assign) NSWindow* baseWindow;

- (void)startDownload;

- (void)setRemoteFiles:(NSArray*)remoteFiles localFiles:(NSArray*)localFiles descriptions:(NSArray*)descriptions;
- (void)setCallback:(SEL)selector andTarget:(id)target;

@end
