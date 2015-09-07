//
//  VideoFeedback.h
//  DataPrism
//
//  Created by Adam Fouse on 10/4/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@interface FeedbackController : NSWindowController {

	IBOutlet QTCaptureView *captureView;
	
	IBOutlet NSButton *recordButton;
	
	QTCaptureSession           *captureSession;
	QTCaptureMovieFileOutput   *captureMovieFileOutput;
	QTCaptureDeviceInput       *captureDeviceInput;
	
	BOOL recording;
	
	NSString* videoFile;
}

- (IBAction)toggleRecording:(id)sender;

@end
