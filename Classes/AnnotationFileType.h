//
//  FileType.h
//  Annotation
//
//  Created by Adam Fouse on 6/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AnnotationFileType : NSObject {
	NSString *extension;
	NSString *description;
}

@property(retain) NSString* extension;
@property(retain) NSString* description;

+ (AnnotationFileType*)annotationFileType;
+ (AnnotationFileType*)xmlFileType;
+ (AnnotationFileType*)csvFileType;

+ (void)releaseAllTypes;

@end
