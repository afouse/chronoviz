//
//  DPSpatialDataImageBase.m
//  ChronoViz
//
//  Created by Adam Fouse on 10/11/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPSpatialDataImageBase.h"
#import <QuartzCore/CoreAnimation.h>
#import "NSImage-Extras.h"
#import "DPConstants.h"
#import "NSStringFileManagement.h"
#import "AnnotationDocument.h"
#import "TiledPDFDelegate.h"

@interface DPSpatialDataImageBase (Interal)

- (void)setupWithBackgroundFile:(NSString*)imageFile;

@end

@implementation DPSpatialDataImageBase

@synthesize imageFilePath;

- (id)initWithBackgroundFile:(NSString*)imageFile;
{
    self = [super init];
    if (self) {
        backgroundDelegate = nil;
        self.imageFilePath = imageFile;
        self.coordinateSpace = CGRectZero;
        //[self setupWithBackgroundFile:imageFile];
    }
    
    return self;
}

- (CALayer*)backgroundLayer
{
    if(!backgroundLayer)
    {
        if(self.imageFilePath)
        {
            [self setupWithBackgroundFile:self.imageFilePath];
        }
        else
        {
            NSLog(@"Warning: No background image for spatial data");
            return [super backgroundLayer];
        }
    }
    return backgroundLayer;
}

- (void)setupWithBackgroundFile:(NSString *)imageFile
{
    self.imageFilePath = imageFile;
    
    self.xCenterOffset = 0;
    self.yCenterOffset = 0;
    
    if(backgroundLayer)
    {
        [backgroundLayer removeFromSuperlayer];
        [backgroundLayer release];
    }
    
    NSLog(@"Creating background layer for: %@",imageFile);
    
    if([[imageFile pathExtension] caseInsensitiveCompare:@"pdf"] == NSOrderedSame)
    {
		CATiledLayer *tiledLayer = [CATiledLayer layer];
		TiledPDFDelegate *delegate = [[TiledPDFDelegate alloc] initWithFile:imageFile];
        delegate.verticalMirror = NO;
		tiledLayer.delegate = delegate;
		
		// get tiledLayer size
		CGRect pageRect = CGPDFPageGetBoxRect([delegate page], kCGPDFCropBox);
		int w = pageRect.size.width;
		int h = pageRect.size.height;
		
        self.aspectRatio = pageRect.size.width/pageRect.size.height;
        
        if(CGRectEqualToRect(self.coordinateSpace,CGRectZero))
        {
            self.coordinateSpace = CGRectMake(0, 0, pageRect.size.width,pageRect.size.height);
        }
        
		// get level count
		int levels = 1;
		while (w > 1 && h > 1) {
			levels++;
			w = w >> 1;
			h = h >> 1;
		}
		
		// set the levels of detail
		tiledLayer.levelsOfDetail = levels;
		// set the bias for how many 'zoom in' levels there are
		tiledLayer.levelsOfDetailBias = 5;
		// setup the size and position of the tiled layer
		
		tiledLayer.tileSize = CGSizeMake(256, 256);
		
        
//		tiledLayer.bounds = CGRectMake(0.0f, 0.0f,
//									   CGRectGetWidth(pageRect), 
//									   CGRectGetHeight(pageRect));
//        
//		tiledLayer.anchorPoint = CGPointMake(0.0, 0.0);
//		tiledLayer.position = CGPointZero;
		
        [tiledLayer setFrame:self.coordinateSpace];
        //tiledLayer.contentsGravity = kCAGravityResizeAspect;//  kCAGravityTopLeft;
        //tiledLayer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
        
        [tiledLayer setBackgroundColor:CGColorCreateGenericGray(1.0, 1.0)];
        
        //self.layer = tiledLayer;
        
        [tiledLayer setNeedsDisplayOnBoundsChange:YES];
        
        CALayer *baseLayer = [CALayer layer];
        [baseLayer addSublayer:tiledLayer];
        [baseLayer setFrame:self.coordinateSpace];
        baseLayer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
        [baseLayer setDelegate:self];
        [baseLayer setNeedsDisplayOnBoundsChange:YES];
        backgroundLayer = [baseLayer retain];
        
        
		[tiledLayer setNeedsDisplay];
        
        [backgroundDelegate release];
        backgroundDelegate = delegate;
   
    }
    else
    {
        NSImage *backgroundImage = [[NSImage alloc] initWithContentsOfFile:imageFile];
        
        BOOL foundSize = NO;
        NSSize imageSize;
        for(NSImageRep* rep in [backgroundImage representations])
        {
            foundSize = YES;
            imageSize = NSMakeSize([rep pixelsWide], [rep pixelsHigh]);
        }
        
        if(!foundSize)
            imageSize = [backgroundImage size];
        
        NSLog(@"Background image size: w:%f h:%f",imageSize.width,imageSize.height);
        
        if(CGRectEqualToRect(self.coordinateSpace,CGRectZero))
        {
            self.aspectRatio = imageSize.width/imageSize.height;
            self.coordinateSpace = CGRectMake(0, 0, imageSize.width, imageSize.height);
        }
        
        CGImageRef cgbackground = [backgroundImage createCgImage];
        
        backgroundLayer = [[CATiledLayer layer] retain];
        [(CATiledLayer*)backgroundLayer setTileSize:CGSizeMake(512, 512)];
        [backgroundLayer setFrame:self.coordinateSpace];
        backgroundLayer.contentsGravity = kCAGravityResizeAspect;//  kCAGravityTopLeft;
        backgroundLayer.autoresizingMask = (kCALayerWidthSizable | kCALayerHeightSizable);
        backgroundLayer.contents = (id)cgbackground;
        
        CGImageRelease(cgbackground);
        [backgroundImage release];
        
    }
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CGSize layersize = [layer bounds].size;
    
    CGRect pdfFrame = CGRectMake(0, 0, layersize.width, layersize.height);
    
    if((layersize.width/layersize.height) > aspectRatio)
    {
        pdfFrame.size.width = self.aspectRatio * pdfFrame.size.height;
        pdfFrame.origin.x = (layersize.width - (layersize.height * aspectRatio)) / 2.0;
    }
    else
    {
        pdfFrame.size.height = pdfFrame.size.width/self.aspectRatio;
        pdfFrame.origin.y = (layersize.height - (layersize.width / aspectRatio)) / 2.0;
    }
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    CALayer *pdfLayer = [[layer sublayers] lastObject];
    [pdfLayer setBounds:CGRectMake(0, 0, pdfFrame.size.width, pdfFrame.size.height)];
    [pdfLayer setFrame:pdfFrame];
    //[pdfLayer setNeedsDisplay];
    [CATransaction commit];
}

- (void)dealloc {
    [backgroundDelegate release];
    self.imageFilePath = nil;
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	//NSString *altColon = @"⁚";
	[super encodeWithCoder:coder];
    
    [coder encodeObject:self.imageFilePath forKey:@"BackgroundImageFile"];
    
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
        backgroundDelegate = nil;
        imageFilePath = [(NSString*)[coder decodeObjectForKey:@"BackgroundImageFile"] retain];
	}
    return self;
}

- (void)load
{
    if(!loaded)
    {
        [super load];
        
        CGRect coordinateTemp = self.coordinateSpace;
        
        NSString *newFile = [[AnnotationDocument currentDocument] resolveFile:imageFilePath];
        
        if(!newFile)
        {
            newFile = [imageFilePath stringByAskingForReplacement];
        }
        
        [self setupWithBackgroundFile:newFile];
        self.coordinateSpace = coordinateTemp;
    }
    
}

- (BOOL)compatibleWithBase:(DPSpatialDataBase*)otherBase
{
    if([otherBase isKindOfClass:[DPSpatialDataImageBase class]])
    {
        return [self.imageFilePath isEqualToString:[(DPSpatialDataImageBase*)otherBase imageFilePath]];
    }
    else
    {
        return NO;
    }
}


- (id)copyWithZone:(NSZone *)zone
{
    DPSpatialDataImageBase* copy = [super copyWithZone:zone];
    copy.imageFilePath = self.imageFilePath;
    //copy.layer.delegate = copy;
    return copy;
}

@end
