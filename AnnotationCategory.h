//
//  AnnotationCategory.h
//  Annotation
//
//  Created by Adam Fouse on 7/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class Annotation;

extern NSString * const DPAltColon;
extern NSString * const DPCategoryChangeNotification;

@interface AnnotationCategory : NSObject <NSCoding> {

	NSString *name;
	NSColor *color;
	NSString *keyEquivalent;
	
	Annotation *annotation;
	AnnotationCategory *category;
	
	NSMutableArray *values;
	
	BOOL temporary;
}

@property(retain) NSString* name;
@property(retain) NSColor* color;
@property(retain) NSString* keyEquivalent;
@property(retain) Annotation* annotation;
@property(assign) AnnotationCategory* category;
@property BOOL temporary;

- (NSMutableArray*)values;
- (void)addValue:(AnnotationCategory*)value;
- (void)addValue:(AnnotationCategory*)value atIndex:(NSInteger)index;
- (void)moveValue:(AnnotationCategory*)value toIndex:(NSInteger)index;
- (void)removeValue:(AnnotationCategory*)value;
- (AnnotationCategory*)valueForName:(NSString*)theName;

- (NSColor*)autoColor;
- (void)colorValuesByCategoryColor;
- (void)setValuesColor:(NSColor*)theColor;
- (void)colorValuesByGradient:(NSGradient*)gradient;

- (NSString*)fullName;

- (BOOL)matchesCategory:(AnnotationCategory*)anotherCategory;

@end
