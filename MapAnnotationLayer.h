//
//  MapAnnotationLayer.h
//  Annotation
//
//  Created by Adam Fouse on 10/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
@class Annotation;
@class MapView;

@interface MapAnnotationLayer : NSObject {
	MapView *mapView;
	
	CALayer *annotationLayer;
	CALayer *indicatorLayer;
	
	Annotation *annotation;
	
	NSBezierPath *annotationPath;

}

@property(retain) CALayer* annotationLayer;
@property(retain) CALayer* indicatorLayer;
@property(retain) NSBezierPath* annotationPath;
@property(assign) MapView* mapView;

-(id)initWithAnnotation:(Annotation*)theAnnotation;

-(void)update;

-(Annotation*)annotation;

@end
