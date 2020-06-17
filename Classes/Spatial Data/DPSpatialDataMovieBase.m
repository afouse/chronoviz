//
//  DPSpatialDataMovieBase.m
//  ChronoViz
//
//  Created by Adam Fouse on 11/30/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPSpatialDataMovieBase.h"
#import "VideoProperties.h"
#import "AnnotationDocument.h"
#import <AVKit/AVKit.h>

@interface DPSpatialDataMovieBase (Internal)

- (void)setVideoProperties:(VideoProperties*)properties;

@end

@implementation DPSpatialDataMovieBase

@synthesize video;

- (id)initWithVideo:(VideoProperties*)videoProperties
{
    self = [super init];
    if (self) {
        videoID = nil;
        [self setVideoProperties:videoProperties];
        //[self setupWithVideo:videoProperties];
    }
    
    return self;
}


- (CALayer*)backgroundLayer
{
    if(!backgroundLayer)
    {
        if(!video)
        {
            NSLog(@"Warning: No background movie for spatial data");
            return [super backgroundLayer];
        }
        else
        {
            [video setEnabled:YES];
            
            self.xCenterOffset = 0;
            self.yCenterOffset = 0;
            
            AVPlayer *movie = [video movie];
            
            NSSize contentSize = (NSSize)[[[movie tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
            self.aspectRatio = contentSize.width/contentSize.height;
            self.coordinateSpace = CGRectMake(0, 0, contentSize.width, contentSize.height);
            
            backgroundLayer = [[AVPlayerLayer layer] retain];
            [backgroundLayer setFrame:self.coordinateSpace];
            backgroundLayer.contentsGravity = kCAGravityResizeAspect;//  kCAGravityTopLeft;
            backgroundLayer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
            ((AVPlayerLayer*)backgroundLayer).player = movie;
        }
    }
    return backgroundLayer;
    
}

- (void)dealloc {
    [video setEnabled:NO];
    [video release];
    [videoID release];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	//NSString *altColon = @"⁚";
	[super encodeWithCoder:coder];
    
    [coder encodeObject:[video uuid] forKey:@"VideoPropertiesID"];
    
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
        videoID = [[coder decodeObjectForKey:@"VideoPropertiesID"] retain];
	}
    return self;
}

- (void)load
{
    if(!loaded)
    {
        [super load];
        for(VideoProperties *properties in [[AnnotationDocument currentDocument] allMediaProperties])
        {
            if([videoID isEqualToString:[properties uuid]])
            {
                [videoID release];
                videoID = nil;
                [self setVideoProperties:properties];
                return;
            }
        }
    }
}

- (BOOL)compatibleWithBase:(DPSpatialDataBase*)otherBase
{
    if([otherBase isKindOfClass:[DPSpatialDataMovieBase class]])
    {
        return [[video videoFile] isEqualToString:[[(DPSpatialDataMovieBase*)otherBase video] videoFile]];
    }
    else
    {
        return NO;
    }
}

- (void)setVideoProperties:(VideoProperties *)properties
{
    video = [properties retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    DPSpatialDataMovieBase* copy = [super copyWithZone:zone];
    [copy setVideoProperties:video];
    return copy;
}

@end
