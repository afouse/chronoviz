//
//  AnnotationCategoryFilter.h
//  Annotation
//
//  Created by Adam Fouse on 12/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationFilter.h"
@class AnnotationCategory;

extern NSString * const AnnotationCategoryFilterAND;
extern NSString * const AnnotationCategoryFilterOR;
extern NSString * const AnnotationCategoryFilterNOT;

@interface AnnotationCategoryFilter : AnnotationFilter {

	NSMutableArray* visibleCategories;
	
	NSString *predicateBoolean;
	NSString *predicateNegation;
}

@property(retain) NSString* predicateBoolean;
@property(retain) NSString* predicateNegation;

+ (AnnotationCategoryFilter*)filterForCategory:(AnnotationCategory*)category;

// A filter that shows everything
- (id)init;
// A filter that hides everything
- (id)initForNone;
// A filter that shows specified categories
- (id)initForCategories:(NSArray*)categories;

- (NSArray*)visibleCategories;

- (void)showCategory:(AnnotationCategory*)category;
- (void)hideCategory:(AnnotationCategory*)category;

- (BOOL)includesCategory:(AnnotationCategory*)category;

- (void)generatePredicate;

@end
