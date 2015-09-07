//
//  TranscriptViewController.h
//  DataPrism
//
//  Created by Adam Fouse on 5/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationViewController.h"
@class TranscriptView;

@interface TranscriptViewController : NSWindowController <AnnotationViewController> {

	IBOutlet TranscriptView* transcriptView;
	IBOutlet NSView* findPanelView;
	IBOutlet NSSearchField* searchField;
	
}

- (TranscriptView*)transcriptView;
- (void)performFindPanelAction:(id)sender;
- (IBAction)closeFindPanelAction:(id)sender;

@end
