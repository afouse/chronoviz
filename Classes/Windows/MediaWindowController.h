//
//  MediaWindowController.h
//  Annotation
//
//  Created by Adam Fouse on 12/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class VideoPropertiesController;

@interface MediaWindowController : NSWindowController {

	IBOutlet NSTextField *mainVideoField;
	
	IBOutlet NSButton *addMediaButton;
	IBOutlet NSButton *removeMediaButton;
	IBOutlet NSButton *editMediaButton;
	
	IBOutlet NSTableView *mediaTableView;
	
	VideoPropertiesController *videoPropertiesController;
}

-(IBAction)addMedia:(id)sender;
-(IBAction)removeMedia:(id)sender;
-(IBAction)editMedia:(id)sender;

-(IBAction)reloadMediaListing:(id)sender;

@end
