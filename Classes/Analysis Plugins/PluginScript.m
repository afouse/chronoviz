//
//  PluginScript.m
//  Annotation
//
//  Created by Adam Fouse on 11/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PluginScript.h"

@implementation PluginScript

@synthesize name;
@synthesize fileName;

- (id) init
{
	self = [super init];
	if (self != nil) {
		pluginConfigurations = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[pluginConfigurations release];
	[super dealloc];
}

- (NSMutableArray*)pluginConfigurations
{
	return pluginConfigurations;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:name forKey:@"AnnotationScriptName"];
	[coder encodeObject:pluginConfigurations forKey:@"AnnotationScriptConfigurations"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
		[self setName:[coder decodeObjectForKey:@"AnnotationScriptName"]];
		pluginConfigurations = [[coder decodeObjectForKey:@"AnnotationScriptConfigurations"] retain];
	}
    return self;
}

@end
