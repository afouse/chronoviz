//
//  AnnotationSet.h
//  DataPrism
//
//  Created by Adam Fouse on 3/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TimeCodedData.h"
@class Annotation;
@class AnnotationCategory;

@interface AnnotationSet : TimeCodedData {

	NSMutableArray *annotations;
	AnnotationCategory *category;
	
	BOOL useNameAsCategory;
}

@property(retain) AnnotationCategory* category;
@property BOOL useNameAsCategory;

- (NSArray*)annotations;
- (void)addAnnotation:(Annotation*)annotation;
- (void)removeAnnotation:(Annotation*)annotation;

@end
