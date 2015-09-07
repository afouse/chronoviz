//
//  AnnotationSearchFilter.m
//  DataPrism
//
//  Created by Adam Fouse on 5/23/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "AnnotationSearchFilter.h"


@implementation AnnotationSearchFilter

@synthesize searchTerm;

- (id) init
{
	return [self initWithString:nil];
}


- (id)initWithString:(NSString*)theString
{
	self = [super init];
	if (self != nil) {
		searchTerm = [theString retain];
		
		categories = YES;
		annotation = YES;
		title = YES;
		
		NSMutableString *predicateFormat = [NSMutableString string];
		if((theString == nil) || ([theString length] == 0))
		{
			[predicate release];
			predicate = [[NSPredicate predicateWithValue:YES] retain];
		}
		else
		{		
			
			[predicateFormat appendString:@"(annotation contains[cd] %@)"];
			[predicateFormat appendString:@"OR (title contains[cd] %@)"];
			[predicateFormat appendString:@"OR (ANY keywords contains[cd] %@)"];
			[predicateFormat appendString:@"OR (ANY categories.name contains[cd] %@)"];
			
			NSArray *stringList = [NSArray arrayWithObjects:searchTerm,searchTerm,searchTerm,searchTerm,nil];
			
			[predicate release];
			predicate = [[NSPredicate predicateWithFormat:predicateFormat argumentArray:stringList] retain];
		}
	}
	return self;
	
}


- (void) dealloc
{
	[searchTerm release];
	[super dealloc];
}


- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:searchTerm forKey:@"AnnotationSearchFilterString"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		searchTerm = [[coder decodeObjectForKey:@"AnnotationSearchFilterString"] retain];
	}
    return self;
}


@end
