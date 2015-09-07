//
//  AnnotationCategoryFilter.m
//  Annotation
//
//  Created by Adam Fouse on 12/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationCategoryFilter.h"
#import "AnnotationCategory.h"
#import "AppController.h"
#import "VideoProperties.h"
#import "AnnotationDocument.h"

NSString * const AnnotationCategoryFilterAND = @"AND";
NSString * const AnnotationCategoryFilterOR = @"OR";
NSString * const AnnotationCategoryFilterNOT = @"NOT";

@implementation AnnotationCategoryFilter

+ (AnnotationCategoryFilter*)filterForCategory:(AnnotationCategory*)category
{
	AnnotationCategoryFilter* filter = [[AnnotationCategoryFilter alloc] initForNone];
	[filter showCategory:category];
	return [filter autorelease];
}

- (id) init
{
//	self = [super initWithPredicate:nil];
//	if (self != nil) {
//		visibleCategories = nil;
//	}
//	return self;
	return [self initForCategories:[[AppController currentDoc] categories]];
}

- (id)initForNone
{
	return [self initForCategories:nil]; 
}

- (id)initForCategories:(NSArray*)categories
{
	self = [super initWithPredicate:nil];
	if (self != nil) {
		predicate = nil;
		if(categories)
		{
			visibleCategories = [categories mutableCopy];
		}
		else
		{
			visibleCategories = [[NSMutableArray alloc] init];
		}
		[self setPredicateBoolean:AnnotationCategoryFilterOR];
		predicateNegation = nil;
	}
	return self;
}

- (void) dealloc
{
	[visibleCategories release];
	[super dealloc];
}

- (NSString*)predicateBoolean
{
	return predicateBoolean;
}

- (void)setPredicateBoolean:(NSString *)theBool
{
	[theBool retain];
	[predicateBoolean release];
	predicateBoolean = theBool;
	[self generatePredicate];
}

- (NSString*)predicateNegation
{
	return predicateNegation;
}

- (void)setPredicateNegation:(NSString *)theBool
{
	if([theBool length] == 0)
	{
		theBool = nil;
	}
	[theBool retain];
	[predicateNegation release];
	predicateNegation = theBool;
	[self generatePredicate];
}

- (NSArray*)visibleCategories
{
	if(visibleCategories)
	{
		return visibleCategories;	
	}
	else
	{
		return [[AppController currentDoc] categories];
	}

}

- (void)showCategory:(AnnotationCategory*)category
{
    if(!category)
    {
        return;
    }
	if(visibleCategories)
	{
		if(![visibleCategories containsObject:category])
		{
			[visibleCategories addObject:category];
		}
		if([[category values] count] > 0)
		{
			for(AnnotationCategory* value in [category values])
			{
				if([visibleCategories containsObject:value])
				{
					[visibleCategories removeObject:value];
				}
			}
		} else if ([category category])
		{
			BOOL total = YES;
			for(AnnotationCategory *value in [[category category] values])
			{
				total = total && [visibleCategories containsObject:value];
			}
			if(total)
			{
				[self showCategory:[category category]];
			}
		}
	}
	else
	{
		visibleCategories = [[NSMutableArray alloc] initWithObjects:category,nil];
	}
	[self generatePredicate];
}

- (void)hideCategory:(AnnotationCategory*)category
{
	if(visibleCategories)
	{
		if([visibleCategories containsObject:category])
		{
			[visibleCategories removeObject:category];
		}
	}
	else
	{
		visibleCategories = [[NSMutableArray alloc] initWithArray:[[[AppController currentDoc] videoProperties] categories]];
		if(![category category])
			[visibleCategories removeObject:category];
	}
	
	for(AnnotationCategory *value in [category values])
	{
		if([visibleCategories containsObject:value])
		{
			[visibleCategories removeObject:value];
		}
	}
	
	if([category category] && [visibleCategories containsObject:[category category]])
	{
		[visibleCategories removeObject:[category category]];
		for(AnnotationCategory *value in [[category category] values])
		{
			if(value != category)
			{
				[visibleCategories addObject:value];
			}
		}
	}
	[self generatePredicate];
}

- (BOOL)includesCategory:(AnnotationCategory*)category
{
	if([category category])
	{
		return ([visibleCategories containsObject:category] || [visibleCategories containsObject:[category category]]);
	}
	else
	{
		return [visibleCategories containsObject:category];
	}
}

- (void)generatePredicate
{
	//[self setAnnotationFilter:[NSPredicate predicateWithFormat:@"category == %@",category]];
	NSMutableString *predicateFormat = [NSMutableString string];
	if([visibleCategories isEqualToArray:[[AppController currentDoc] categories]])
	{
		[predicate release];
		predicate = [[NSPredicate predicateWithValue:YES] retain];
	}
	else if([visibleCategories count] > 0)
	{
		NSMutableArray* categoriesList = [NSMutableArray array];
		for(AnnotationCategory* category in visibleCategories)
		{
			if([predicateFormat length] == 0)
			{
				//[predicateFormat appendString:@"(category == %@)"];
				if(predicateNegation)
				{
					[predicateFormat appendString:@"(NOT (%@ in categories))"];
				}
				else
				{
					[predicateFormat appendString:@"(%@ in categories)"];
				}
				
			}
			else
			{
				if(predicateNegation)
				{
					[predicateFormat appendString:[predicateBoolean stringByAppendingString:@" (NOT (%@ in categories))"]];
				}
				else
				{
					[predicateFormat appendString:[predicateBoolean stringByAppendingString:@" (%@ in categories)"]];
				}
			}
			[categoriesList addObject:category];
			for(AnnotationCategory* value in [category values])
			{
				if(predicateNegation)
				{
					[predicateFormat appendString:[predicateBoolean stringByAppendingString:@" (NOT (%@ in categories))"]];
				}
				else
				{
					[predicateFormat appendString:[predicateBoolean stringByAppendingString:@" (%@ in categories)"]];
				}
				[categoriesList addObject:value];
			}
		}
		[predicate release];
		predicate = [[NSPredicate predicateWithFormat:predicateFormat argumentArray:categoriesList] retain];
	}
	else
	{
		[predicate release];
		predicate = [[NSPredicate predicateWithValue:NO] retain];
	}
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	NSMutableArray *categoryNames = [NSMutableArray arrayWithCapacity:[visibleCategories count]];
	for(AnnotationCategory *category in visibleCategories)
	{
		[categoryNames addObject:[[AnnotationDocument currentDocument] identifierForCategory: category]];
	}
	
	[coder encodeObject:categoryNames forKey:@"AnnotationCategoryFilterCategories"];
	[coder encodeObject:predicateBoolean forKey:@"AnnotationCategoryFilterBoolean"];
	[coder encodeObject:predicateNegation forKey:@"AnnotationCategoryFilterNegation"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
		predicate = nil;
		visibleCategories = [[NSMutableArray alloc] init];
		
		predicateBoolean = [coder decodeObjectForKey:@"AnnotationCategoryFilterBoolean"];
		if([predicateBoolean isEqualToString:AnnotationCategoryFilterAND])
		{
			predicateBoolean = AnnotationCategoryFilterAND;
		}
		else 
		{
			predicateBoolean = AnnotationCategoryFilterOR;
		}
		
		predicateNegation = [coder decodeObjectForKey:@"AnnotationCategoryFilterNegation"];
		if(predicateNegation)
		{
			predicateNegation = AnnotationCategoryFilterNOT;
		}

		
		[self setPredicateBoolean:AnnotationCategoryFilterOR];
		NSArray* categoryIdentifiers = [[coder decodeObjectForKey:@"AnnotationCategoryFilterCategories"] retain];
		for(NSString *identifier in categoryIdentifiers)
		{
			AnnotationCategory* category = [[AnnotationDocument currentDocument] categoryForIdentifier:identifier];
			if(category)
			{
				[visibleCategories addObject:category];
			}
		}
		[self generatePredicate];
	}
    return self;
}

@end
