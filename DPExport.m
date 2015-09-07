//
//  DPExport.m
//  DataPrism
//
//  Created by Adam Fouse on 3/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DPExport.h"
#import "AnnotationDocument.h"

@implementation DPExport

-(NSString*)name
{
	return @"Export";
}

-(BOOL)export:(AnnotationDocument*)doc
{
	return NO;
}

@end
