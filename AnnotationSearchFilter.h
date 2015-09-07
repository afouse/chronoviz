//
//  AnnotationSearchFilter.h
//  DataPrism
//
//  Created by Adam Fouse on 5/23/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationFilter.h"

@interface AnnotationSearchFilter : AnnotationFilter {

	NSString* searchTerm;
	
	
	BOOL annotation;
	BOOL categories;
	BOOL title;
	
}

@property(readonly) NSString* searchTerm;

- (id)initWithString:(NSString*)theString;

@end
