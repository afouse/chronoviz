//
//  AnnotationXMLParser.h
//  Annotation
//
//  Created by Adam Fouse on 6/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class Annotation;
@class AnnotationDocument;

@interface AnnotationXMLParser : NSObject {

	NSXMLDocument *xmlDoc;
    NSXMLNode *annotationsRoot;
	AnnotationDocument *annotationDoc;
    
    NSOperationQueue *xmlOperationsQueue;
	
	NSDateFormatter *dateFormatter;
	NSDateFormatter *altDateFormatter;
	
	NSMutableArray *annotations;
	
	BOOL updateAnnotations;
}

@property BOOL updateAnnotations;

- (id)init;
-(id)initForDocument:(AnnotationDocument*)doc;
- (id)initWithFile:(NSString *)file forDocument:(AnnotationDocument*)doc;

- (void)addAnnotation:(Annotation *)annotation;
- (void)removeAnnotation:(Annotation *)annotation;
- (void)updateAnnotation:(Annotation *)annotation;
- (NSArray*)annotations;

- (NSXMLElement*)createAnnotationElement:(Annotation *)annotation;

- (void)setup;
- (NSDateFormatter*)dateFormatter;
- (void)writeToFile:(NSString *)fileName;
- (void)writeToFile:(NSString *)filename waitUntilDone:(BOOL)wait;

@end
