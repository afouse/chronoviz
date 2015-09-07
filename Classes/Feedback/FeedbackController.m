//
//  VideoFeedback.m
//  DataPrism
//
//  Created by Adam Fouse on 10/4/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "FeedbackController.h"
#import "DPApplicationSupport.h"
#import "FileUploader.h"

@implementation FeedbackController

- (id)init
{
	if(![super initWithWindowNibName:@"FeedbackWindow"])
		return nil;
	
	recording = NO;
	
	captureSession = nil;
    captureDeviceInput = nil;
    captureMovieFileOutput = nil;
	
	videoFile = nil;
	
	return self;
}

- (void)dealloc
{
    [captureSession release];
    [captureDeviceInput release];
    [captureMovieFileOutput release];
	[videoFile release];
	
    [super dealloc];
}

- (void)windowDidLoad
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	[[captureView layer] setAnchorPoint:CGPointMake(0.5, 0.5)];
	[[captureView layer] setTransform:CATransform3DMakeScale(-1.0f, 1.0f, 1.0f)];
	[[captureView layer] setPosition:CGPointMake(160,120)];
	
	[CATransaction commit];
	
	captureSession = [[QTCaptureSession alloc] init];
	
	BOOL success = NO;
    NSError *error;
	
	QTCaptureDevice *device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
    if (device) {
        success = [device open:&error];
        if (!success) {
        }
        captureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
        success = [captureSession addInput:captureDeviceInput error:&error];
        if (!success) {
            // Handle error
        }
		
		captureMovieFileOutput = [[QTCaptureMovieFileOutput alloc] init];
		success = [captureSession addOutput:captureMovieFileOutput error:&error];
		if (!success) {
		}
		[captureMovieFileOutput setDelegate:self];
		
		NSEnumerator *connectionEnumerator = [[captureMovieFileOutput connections] objectEnumerator];
        QTCaptureConnection *connection;
		
        while ((connection = [connectionEnumerator nextObject])) {
            NSString *mediaType = [connection mediaType];
            QTCompressionOptions *compressionOptions = nil;
            if ([mediaType isEqualToString:QTMediaTypeVideo]) {
                compressionOptions = [QTCompressionOptions compressionOptionsWithIdentifier:@"QTCompressionOptions240SizeH264Video"];
            } else if ([mediaType isEqualToString:QTMediaTypeSound]) {
                compressionOptions = [QTCompressionOptions compressionOptionsWithIdentifier:@"QTCompressionOptionsHighQualityAACAudio"];
            }
			
            [captureMovieFileOutput setCompressionOptions:compressionOptions forConnection:connection];
			
			[captureView setCaptureSession:captureSession];
		}
		
		[captureSession startRunning];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
    [captureSession stopRunning];
    [[captureDeviceInput device] close];
}

- (IBAction)toggleRecording:(id)sender
{
	if(recording)
	{
		[captureMovieFileOutput recordToOutputFileURL:nil];
		[recordButton setTitle:@"Record"];
		recording = NO;
		
		NSAlert *uploadAlert = [[NSAlert alloc] init];
		[uploadAlert setMessageText:@"Would you like to upload the video now?"];
		[uploadAlert addButtonWithTitle:@"Upload Now"];
		[uploadAlert addButtonWithTitle:@"Upload Later"];
		[uploadAlert addButtonWithTitle:@"Delete Video"];
		
		[uploadAlert beginSheetModalForWindow:[self window]
								  modalDelegate:self
								 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
									contextInfo:nil];
		
	}
	else
	{
		NSString *folder = [[DPApplicationSupport userSupportFolder] stringByAppendingPathComponent:@"Feedback"];
		NSString *format = @"%Y-%m-%d-%H-%M-%S.mov";
		[videoFile release];
		videoFile = [[folder stringByAppendingPathComponent:[[NSDate date] descriptionWithCalendarFormat:format timeZone:nil locale:nil]] retain];
		
		[captureMovieFileOutput recordToOutputFileURL:[NSURL fileURLWithPath:videoFile]];
		[recordButton setTitle:@"Stop"];
		recording = YES;
	}
	
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertFirstButtonReturn) 
	{
		NSLog(@"Upload Now");
		
		//FileUploader *uploader = [[FileUploader alloc] initForHost:@"adamfouse.com" username:@"annotation" password:@"dcoghcilab"];
		
		[[alert window] close];
		
		[[FileUploader standardFileUploader] uploadFile:videoFile withProgressSheetForWindow:[self window]];
		
		
		
    }
	else if (returnCode == NSAlertSecondButtonReturn) 
	{
		NSLog(@"Upload later");
		//[penMenuItem setEnabled:YES];
		//[[self progressWindow] close];
	}
}

@end
