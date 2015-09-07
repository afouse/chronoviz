//
//  AnnotationCategory.m
//  Annotation
//
//  Created by Adam Fouse on 7/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationCategory.h"
#import "Annotation.h"

NSString * const DPAltColon = @"\\u0x2236"; // Unicode "ratio" character

NSString * const DPCategoryChangeNotification = @"CategoryChangeNotification";

@interface AnnotationCategory (ChangeListening)

- (void)processValueChange:(id)sender;

@end

@implementation AnnotationCategory

@synthesize annotation;
@synthesize category;
@synthesize keyEquivalent;
@synthesize temporary;

static NSColorList *annotationCategoryColors = nil;
static int annotationCategoryColorIndex = 0;

+(void) initialize
{
    if (! annotationCategoryColors)
	{
		NSString* colorListFile = [[NSBundle mainBundle] pathForResource:@"DataPrism" ofType:@"clr"];
		annotationCategoryColors = [[NSColorList alloc] initWithName:@"DataPrism Colors" fromFile:colorListFile];
	}
        
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		color = nil;
		name = nil;
		annotation = nil;
		values = nil;
		[self setKeyEquivalent:@""];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[name release];
	[color release];
	[keyEquivalent release];
	[annotation release];
	[values release];
	[super dealloc];
}

- (NSColor*)autoColor
{
	NSArray *colorKeys = [annotationCategoryColors allKeys];
	NSColor *newColor = [annotationCategoryColors colorWithKey:[colorKeys objectAtIndex:annotationCategoryColorIndex]];
	annotationCategoryColorIndex++;
	if(annotationCategoryColorIndex >= [colorKeys count])
	{
		annotationCategoryColorIndex = 0;
	}
	[self setColor:newColor];
	return newColor;
}

-(NSColor*)color
{
	if(annotation)
	{
		return [annotation colorObject];
	}
	else if(category && !color)
	{
		return [category color];
	}
	else
	{
		return color;
	}
}

-(void)setColor:(NSColor*)theColor
{
	if(theColor != color)
	{
		[self willChangeValueForKey:@"color"];
		
		[theColor retain];
		[color release];
		color = theColor;
		
		[self didChangeValueForKey:@"color"];
		
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:DPCategoryChangeNotification object:self];
	}
}

-(NSString*)name
{
	if(annotation)
	{
		return [annotation title];
	}
	else
	{
		return name;
	}
}

-(void)setName:(NSString*)theName
{
	theName = [theName stringByReplacingOccurrencesOfString:DPAltColon withString:@":"];
	[theName retain];
	[name release];
	name = theName;
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:DPCategoryChangeNotification object:self];
}

- (NSMutableArray*)values
{
	return values;
}

- (void)processValueChange:(id)sender
{
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:DPCategoryChangeNotification object:self];
}

- (void)addValue:(AnnotationCategory*)value
{
	[self addValue:value atIndex:[values count]];
}

- (void)addValue:(AnnotationCategory*)value atIndex:(NSInteger)index
{
	if(index <= [values count])
	{
		if(values == nil)
		{
			values = [[NSMutableArray alloc] init];
		}
		[value setCategory:self];
		
		[values insertObject:value atIndex:index];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(processValueChange:)
													 name:DPCategoryChangeNotification
												   object:value];
		
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:DPCategoryChangeNotification object:self];
	}
}

- (void)moveValue:(AnnotationCategory*)value toIndex:(NSInteger)index
{
	if(value 
	   && [values containsObject:value]
	   && (index <= [values count]))
	{
		if(index > [values indexOfObject:value])
		{
			index--;
		}
		
		[values removeObject:value];
		
		[values insertObject:value atIndex:index];
		
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:DPCategoryChangeNotification object:self];
	}
}

- (void)removeValue:(AnnotationCategory*)value
{
	[value setCategory:nil];
	[values removeObject:value];
	if([values count] == 0)
	{
		[values release];
		values = nil;
	}
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:DPCategoryChangeNotification object:self];
}

- (AnnotationCategory*)valueForName:(NSString*)theName
{
	// First see if it already exists
	for(AnnotationCategory* value in values)
	{
		if([theName isEqualToString:[value name]])
		{
			return value;
		}
	}
	
	// Otherwise, make a new category value
	AnnotationCategory *newValue = [[AnnotationCategory alloc] init];
	[newValue setName:theName];
	[newValue setColor:[self color]];
	[self addValue:newValue];
	[newValue release];
	
	return newValue;
	
}

- (void)colorValuesByCategoryColor
{
	for(AnnotationCategory* value in values)
	{
		[value setColor:nil];
	}
}

- (void)setValuesColor:(NSColor*)theColor
{
	for(AnnotationCategory* value in values)
	{
		[value setColor:theColor];
	}
}

- (void)colorValuesByGradient:(NSGradient*)gradient
{
	CGFloat location = 0;
	CGFloat increment = 1.0/[values count];
	
	for(AnnotationCategory* value in values)
	{
		[value setColor:[gradient interpolatedColorAtLocation:location]];
		location += increment;
	}
	
}

- (NSString*)fullName
{
    if(self.category)
    {
        return [NSString stringWithFormat:@"%@: %@",self.category.name, self.name];
    }
    else
    {
        return self.name;
    }
}

- (BOOL)matchesCategory:(AnnotationCategory*)anotherCategory
{
	return ((self == anotherCategory) || ([self category] == anotherCategory));
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
	BOOL automatic = NO;
	
    if ([theKey isEqualToString:@"color"] ) {
        automatic=NO;
    } else {
        automatic=[super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}

#pragma mark File Coding

- (void)encodeWithCoder:(NSCoder *)coder
{	
	[coder encodeObject:name forKey:@"AnnotationCategoryName"];
	[coder encodeObject:color forKey:@"AnnotationCategoryColor"];
	[coder encodeObject:values forKey:@"AnnotationCategoryValues"];
	[coder encodeObject:[self keyEquivalent] forKey:@"AnnotationCategoryKeyEquivalent"];
	[coder encodeBool:temporary forKey:@"AnnotationCategoryTemporary"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
		name = [[coder decodeObjectForKey:@"AnnotationCategoryName"] retain];
		color = [[coder decodeObjectForKey:@"AnnotationCategoryColor"] retain];
		values = [[coder decodeObjectForKey:@"AnnotationCategoryValues"] retain];
		[self setKeyEquivalent:[coder decodeObjectForKey:@"AnnotationCategoryKeyEquivalent"]];
		temporary = [coder decodeBoolForKey:@"AnnotationCategoryTemporary"];
		for(AnnotationCategory* value in values)
		{
			[value setCategory:self];
		}
	}
    return self;
}

@end
