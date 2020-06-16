//
//  AnnotationView.h
//  Annotation
//
//  Created by Adam Fouse on 10/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
@class Annotation;
@class AnnotationFilter;
@class TimeCodedData;

@protocol AnnotationView

@required
-(void)addAnnotation:(Annotation*)annotation;
-(void)addAnnotations:(NSArray*)array;
-(void)removeAnnotation:(Annotation*)annotation;
-(void)updateAnnotation:(Annotation*)annotation;

-(void)setAnnotationFilter:(AnnotationFilter*)filter;
-(AnnotationFilter*)annotationFilter;

-(NSArray*)dataSets;

-(void)update;

@optional

- (void)addData:(TimeCodedData*)data;
- (BOOL)removeData:(TimeCodedData*)data;

@end
