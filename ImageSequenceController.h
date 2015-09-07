//
//  ImageSequenceController.h
//  Annotation
//
//  Created by Adam Fouse on 11/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationViewController.h"
@class ImageSequenceView;

@interface ImageSequenceController : NSWindowController <AnnotationViewController> {

	IBOutlet ImageSequenceView* imageSequenceView;
	
}

-(ImageSequenceView*)imageSequenceView;

@end
