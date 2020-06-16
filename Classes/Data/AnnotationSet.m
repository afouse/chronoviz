//
//  AnnotationSet.m
//  DataPrism
//
//  Created by Adam Fouse on 3/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AnnotationSet.h"
#import "Annotation.h"
#import "AnnotationCategory.h"

@implementation AnnotationSet

@synthesize category;
@synthesize useNameAsCategory;

- (id) init
{
	self = [super init];
	if (self != nil) {
		annotations = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		annotations = [[NSMutableArray alloc] init];
	}
    return self;
}

- (void) dealloc
{
	[annotations release];
	[super dealloc];
}

- (NSArray*)annotations
{
	return annotations;
}

- (void)addAnnotation:(Annotation*)annotation
{
	[annotations addObject:annotation];
    if([self source])
    {
        [annotation setSource:[[self source] uuid]];
    }
	range = CMTimeRangeGetUnion([annotation range], range);
}

- (void)removeAnnotation:(Annotation*)annotation
{
	[annotations removeObject:annotation];
	
	range.time.timeValue = 0;
	range.duration.value = 0;
	for(Annotation* remaining in annotations)
	{
		range = CMTimeRangeGetUnion([remaining range], range);
	}
	
}

@end
