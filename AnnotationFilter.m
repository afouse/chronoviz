//
//  AnnotationFilter.m
//  Annotation
//
//  Created by Adam Fouse on 12/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationFilter.h"


@implementation AnnotationFilter

- (id) initWithPredicate:(NSPredicate*)thePredicate;
{
	self = [super init];
	if (self != nil) {
		predicate = [thePredicate retain];
	}
	return self;
}

- (void) dealloc
{
	[predicate release];
	[super dealloc];
}


-(NSPredicate*)predicate
{
	return predicate;
}

- (BOOL)shouldShowAnnotation:(Annotation*)annotation
{
	return [predicate evaluateWithObject:annotation];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:predicate forKey:@"AnnotationFilterPredicate"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
		predicate = [[coder decodeObjectForKey:@"AnnotationFilterPredicate"] retain];
	}
    return self;
}

@end
