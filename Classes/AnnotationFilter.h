//
//  AnnotationFilter.h
//  Annotation
//
//  Created by Adam Fouse on 12/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class Annotation;

@interface AnnotationFilter : NSObject <NSCoding> {

	NSPredicate* predicate;
	
}

- (id) initWithPredicate:(NSPredicate*)thePredicate;
-(NSPredicate*)predicate;

- (BOOL)shouldShowAnnotation:(Annotation*)annotation;

@end
