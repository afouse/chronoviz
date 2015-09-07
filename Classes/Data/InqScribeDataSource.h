//
//  InqScribeDataSource.h
//  DataPrism
//
//  Created by Adam Fouse on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DataSource.h"
@class AnnotationSet;

@interface InqScribeDataSource : DataSource {

	NSMutableArray *transcriptStrings;
	AnnotationSet *annotationSet;
	
	float transcriptFPS;
	
	BOOL interpolate;
}

@property BOOL interpolate;

- (AnnotationSet*)annotations;

@end
