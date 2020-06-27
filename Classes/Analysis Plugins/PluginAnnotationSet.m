//
//  PluginAnnotationSet.m
//  ChronoViz
//
//  Created by Adam Fouse on 6/27/20.
//

#import "PluginAnnotationSet.h"

@implementation PluginAnnotationSet

@synthesize annotationSetName;
@synthesize annotationFilter;
@synthesize annotations;

- (void) dealloc
{
    [annotationSetName release];
    [annotationFilter release];
    [annotations release];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:annotationSetName forKey:@"AnnotationPluginAnnotationSetName"];
    [coder encodeObject:annotationFilter forKey:@"AnnotationPluginAnnotationSetFilter"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
    {
        [self setAnnotationSetName:[coder decodeObjectForKey:@"AnnotationPluginAnnotationSetName"]];
        [self setAnnotationFilter:[coder decodeObjectForKey:@"AnnotationPluginAnnotationSetFilter"]];
    }
    return self;
}

@end
