//
//  ElanDataSource.h
//  DataPrism
//
//  Created by Adam Fouse on 5/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DataSource.h"
@class AnnotationSet;
@class AnnotationCategory;
@class Annotation;

@interface ElanDataSource : DataSource <NSXMLParserDelegate> {

	NSMutableArray *tiers;
	
	BOOL separateCategories;
	
	NSXMLParser* elanParser;
	NSMutableDictionary* timeSlots;
	NSMutableDictionary* linguisticTypes;
	NSMutableDictionary* tierCategories;
	
	NSMutableString* currentStringValue;
	AnnotationSet* currentTier;
	AnnotationCategory* currentTierCategory;
	Annotation* currentAnnotation;
	
	double timeScale;
	
}

@property BOOL separateCategories;

@end
