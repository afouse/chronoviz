//
//  DPLogFileUploader.h
//  ChronoViz
//
//  Created by Adam Fouse on 12/9/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DPLogFileUploader : NSObject {

	IBOutlet NSWindow *uploadWindow;
	IBOutlet NSProgressIndicator *uploadProgress;
	IBOutlet NSButton *cancelButton;
	
	NSString *logsDirectory;
	NSString *uploadFile;
	NSMutableArray *argumentList;
	
	BOOL cancelUpload;
	
	id callbackTarget;
	SEL callbackSelector;
}

+ (DPLogFileUploader*)defaultLogFileUploader;

- (IBAction)uploadLogFiles:(id)sender;
- (IBAction)cancelUpload:(id)sender;
- (BOOL)uploadLogFilesWithCallbackTarget:(id)target selector:(SEL)selector;
- (void)finishUploadAttempt;

- (void)uploadFinished;
- (void)uploadCanceled;

@end
