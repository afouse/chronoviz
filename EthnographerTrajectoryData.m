//
//  EthnographerTrajectoryData.m
//  ChronoViz
//
//  Created by Adam Fouse on 6/14/12.
//  Copyright (c) 2012 University of California, San Diego. All rights reserved.
//

#import "EthnographerTrajectoryData.h"
#import "AnotoNotesData.h"
#import "DataSource.h"

@implementation EthnographerTrajectoryData

@synthesize trajectorySource;

- (void)dealloc
{
    [annotationSessionId release];
    self.annotationSession = nil;
    self.trajectorySource = nil;
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:annotationSessionId forKey:@"AnnotationDataSetAnotoSessionID"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
    {
        annotationSessionId = [[coder decodeObjectForKey:@"AnnotationDataSetAnotoSessionID"] retain];
        annotationSession = nil;
	}
    return self;
}

- (NSString*)displayName
{
    if(self.annotationSession)
    {
        return [self.name stringByAppendingFormat:@" (%@)",[self.annotationSession name]];
    }
    else
    {
        return self.name;
    }
}

- (AnotoNotesData*)annotationSession
{
    if(!annotationSession)
    {
        for(NSObject *data in [[self source] dataSets])
        {
            if([data isKindOfClass:[AnotoNotesData class]]
               && [[(AnotoNotesData*)data uuid] isEqualToString:annotationSessionId])
            {
                [self setAnnotationSession:(AnotoNotesData*)data];
            }
        }
    }
    return annotationSession;
}

- (void)setAnnotationSession:(AnotoNotesData *)theAnnotationSession
{
    [theAnnotationSession retain];
    [annotationSession release];
    annotationSession = theAnnotationSession;
    
    [annotationSessionId release];
    annotationSessionId = [[annotationSession uuid] retain];
}

@end
