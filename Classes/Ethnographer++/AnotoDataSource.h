//
//  AnotoDataSource.h
//  DataPrism
//
//  Created by Adam Fouse on 2/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DataSource.h"

@interface AnotoDataSource : DataSource {

	NSMutableArray *traces;
	NSMutableArray *audio;
	NSMutableArray *annotations;
	NSMutableSet *pages;
	NSMutableDictionary *backgrounds;
	NSMutableDictionary *backgroundOffsets;
	NSMutableDictionary *backgroundScaleCorrection;
	
	NSTimeInterval startTime;
	
	BOOL createAnnotations;
	
	NSString* metadataDirectory;
	NSString* serverFile;
	NSString* postscriptFile;
}

@property BOOL createAnnotations;

-(NSArray*)traces;
-(NSArray*)audio;
-(NSArray*)annotations;
-(NSSet*)pages;
-(NSDictionary*)backgrounds;
-(NSDictionary*)backgroundOffsets;
-(NSDictionary*)backgroundScaleCorrection;

-(NSString*)postscriptFile;

-(void)addAnnotation:(Annotation*)annotation;

-(NSArray*)tracesFromFile:(NSString *)file;
-(Annotation*)createAnnotationFromTraces:(NSArray*)currentTraces;
-(Annotation*)createAnnotationFromTraces:(NSArray*)currentTraces saveImage:(BOOL)saveImage;

-(void)setBackgroundFile:(NSString*)imageFile forPage:(NSString*)pageID;
-(void)setBackgroundXoffset:(CGFloat)xOff andYoffset:(CGFloat)yOff forPage:(NSString*)pageID;
-(void)setBackgroundScaleCorrection:(CGFloat)sc forPage:(NSString*)pageID;

@end
