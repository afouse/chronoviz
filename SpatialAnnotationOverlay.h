//
//  SpatialAnnotationOverlay.h
//  DataPrism
//
//  Created by Adam Fouse on 8/21/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
#import "AnnotationView.h"

@interface SpatialAnnotationOverlay : NSView {

	CALayer *overlayLayer;
	CALayer *toolLayer;
	CALayer *selectionLayer;
	
	
	NSView<AnnotationView> * annotationView;
	
	NSPoint selectionStart;
	NSRect selection;

}

-(id)initForView:(NSView<AnnotationView>*)view;
-(void)showOverlay;
-(void)hideOverlay;

@end
