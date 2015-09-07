//
//  DPExportCategories.m
//  ChronoViz
//
//  Created by Adam Fouse on 2/10/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPExportCategories.h"
#import "AnnotationDocument.h"

@implementation DPExportCategories

-(NSString*)name
{
	return @"Categories";
}

-(BOOL)export:(AnnotationDocument*)doc
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	[savePanel setCanCreateDirectories:YES];
	[savePanel setTitle:@"Categories Export"];
	[savePanel setPrompt:@"Export"];
	[savePanel setRequiredFileType:@"xml"];
	[savePanel setExtensionHidden:NO];
	[savePanel setCanSelectHiddenExtension:YES];
	
	if([savePanel runModal] == NSOKButton) {
		
		NSArray *categories = [doc categories];
				
		NSData *categoriesData = [NSKeyedArchiver archivedDataWithRootObject:categories];
		
		[categoriesData writeToFile:[savePanel filename] atomically:NO];
		
		return YES;
	}
	else
	{
		return NO;
	}
}


@end
