//
//  CIImageWrapper.m
//  Annotation
//
//  Created by Adam Fouse on 7/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CGImageWrapper.h"


@implementation CGImageWrapper

- (id) init
{
	return [self initWithImage:nil];
}


-(id)initWithImage:(CGImageRef)img
{
	self = [super init];
	if (self != nil) {
		if(img)
		{
			CGImageRetain(img);
			image = img;	
		}
		else
		{
			image = nil;
		}
	}
	return self;
}

- (void) dealloc
{
	if(image)
		CGImageRelease(image);
	[super dealloc];
}


-(CGImageRef)image
{
	return image;
}

- (void)encodeWithCoder:(NSCoder *)coder
{	
	[coder encodeDataObject:[self imageData]];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
		NSData *data = [coder decodeDataObject];
		if(data)
		{
			CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)data,  NULL);
			image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
            if(imageSource)
            {
                CFRelease(imageSource);
            }
            
		}		
	}
    return self;
}

- (NSData *) imageData
{
	NSMutableData				*imgData			= [NSMutableData dataWithCapacity:1024];
	
	CGImageDestinationRef		destRef				= CGImageDestinationCreateWithData((CFMutableDataRef) imgData, kUTTypeTIFF, 1, NULL);
	
	// convert img to a tiff
	CGImageDestinationAddImage(destRef, image, NULL);
	CGImageDestinationFinalize(destRef);
	CFRelease(destRef);
	
	return imgData;
}

@end
