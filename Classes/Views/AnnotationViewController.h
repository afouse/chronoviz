//
//  AnnotationViewController.h
//  ChronoViz
//
//  Created by Adam Fouse on 8/30/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationView.h"

@protocol AnnotationViewController

- (id<AnnotationView>)annotationView;

@end
