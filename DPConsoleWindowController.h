//
//  DPConsoleWindowController.h
//  DataPrism
//
//  Created by Adam Fouse on 6/23/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DPConsoleWindowController : NSWindowController {

	IBOutlet NSTextView* textView;
	
}

- (void)updateText:(id)sender;

@end
