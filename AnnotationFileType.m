//
//  FileType.m
//  Annotation
//
//  Created by Adam Fouse on 6/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationFileType.h"


@implementation AnnotationFileType

@synthesize extension;
@synthesize description;

static AnnotationFileType *xmlFileType = nil;
static AnnotationFileType *csvFileType = nil;
static AnnotationFileType *annotationFileType = nil;

+ (AnnotationFileType*)xmlFileType
{
	if(xmlFileType == nil)
	{
		xmlFileType = [[AnnotationFileType alloc] init];
		[xmlFileType setExtension:@"xml"];
		[xmlFileType setDescription:@"Simile XML"];
	}
	return xmlFileType;
}

+ (AnnotationFileType*)csvFileType
{
	if(csvFileType == nil)
	{
		csvFileType = [[AnnotationFileType alloc] init];
		[csvFileType setExtension:@"csv"];
		[csvFileType setDescription:@"CSV"];
	}
	return csvFileType;
}

+ (AnnotationFileType*)annotationFileType
{
	if(annotationFileType == nil)
	{
		annotationFileType = [[AnnotationFileType alloc] init];
		[annotationFileType setExtension:@"annotation"];
		[annotationFileType setDescription:@"Annotation File"];
	}
	return annotationFileType;
}

+ (void)releaseAllTypes
{
	[xmlFileType release];
	xmlFileType = nil;
	[csvFileType release];
	csvFileType = nil;
	[annotationFileType release];
	annotationFileType = nil;
}

@end
