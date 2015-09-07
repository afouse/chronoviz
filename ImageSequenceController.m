//
//  ImageSequenceController.m
//  Annotation
//
//  Created by Adam Fouse on 11/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ImageSequenceController.h"
#import "ImageSequenceView.h"
#import "AppController.h"

@implementation ImageSequenceController

- (id)init
{
	if(![super initWithWindowNibName:@"ImageSequence"])
		return nil;
	
	return self;
}


-(ImageSequenceView*)imageSequenceView
{
	[self window];
	return imageSequenceView;
}

- (id<AnnotationView>)annotationView
{
    return [self imageSequenceView];
}

@end
