//
//  FileUploader.h
//  DataPrism
//
//  Created by Adam Fouse on 10/5/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Connection/Connection.h>

@interface FileUploader : NSObject {

	CKHost *myHost;
	id <CKConnection>myConnection;
	
	IBOutlet NSWindow* progressSheet;
	IBOutlet NSProgressIndicator *progressBar;
	IBOutlet NSTextField *statusField;
	
	CKTransferRecord *record;
	
	BOOL isUploading;
	BOOL lastUploadSuccess;
	
	NSObject* delegate;
}

+(FileUploader*)standardFileUploader;

-(id)initForHost:(NSString*)hostname username:(NSString*)username password:(NSString*)password;

-(void)setDelegate:(NSObject*)theDelegate;
-(NSObject*)delegate;

-(void)uploadFile:(NSString*)file;

-(void)uploadFile:(NSString*)file withProgressSheetForWindow:(NSWindow*)window;
-(void)uploadFile:(NSString*)file withProgressIndicator:(NSProgressIndicator*)indicator;

-(IBAction)cancelUpload:(id)sender;

-(BOOL)isUploading;
-(BOOL)fileUploaded;

@end

#pragma mark Delegate Methods

@interface NSObject (DPFileUploadDelegate)

-(void)uploadFinished;
-(void)uploadCanceled;

@end
