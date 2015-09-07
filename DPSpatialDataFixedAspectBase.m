//
//  DPSpatialDataFixedAspectBase.m
//  ChronoViz
//
//  Created by Adam Fouse on 11/30/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPSpatialDataFixedAspectBase.h"

@implementation DPSpatialDataFixedAspectBase

@synthesize aspectRatio,xCenterOffset,yCenterOffset;

- (void)update
{
    CGSize layersize = self.displayBounds.size;
    
    
    if((layersize.width/layersize.height) > aspectRatio)
    {
        // Extra space in width
        yDataToPixel = layersize.height/coordinateSpace.size.height;
        xDataToPixel = yDataToPixel;
        
        xCenterOffset = (layersize.width - (layersize.height * aspectRatio)) / 2.0;
        yCenterOffset = 0;
    }
    else
    {
        // Extra space in height
        xDataToPixel = layersize.width/coordinateSpace.size.width;
        yDataToPixel = xDataToPixel;
        yCenterOffset = (layersize.height - (layersize.width / aspectRatio)) / 2.0;
        xCenterOffset = 0;
    }
    
//    NSLog(@"Layer Size: %f %f",layersize.width,layersize.height);
//    NSLog(@"xDataToPixel: %f, yDataToPixel: %f",xDataToPixel,yDataToPixel);
//    NSLog(@"xCenterOffset: %f, yCenterOffset: %f",xCenterOffset,yCenterOffset);
//    NSLog(@"Coordinate Space: %f %f %f %f",coordinateSpace.origin.x,coordinateSpace.origin.y,coordinateSpace.size.width,coordinateSpace.size.height);
}

- (CGPoint)viewPointForDataX:(CGFloat)dataX andY:(CGFloat)dataY withOffsets:(CGPoint)offsets
{
    return CGPointMake(xCenterOffset + ((dataX + offsets.x - coordinateSpace.origin.x) * xDataToPixel),
                       self.displayBounds.size.height - yCenterOffset - ((dataY + offsets.y - coordinateSpace.origin.y) * yDataToPixel));
    
}

- (CGPoint)dataPointForViewPoint:(CGPoint)viewPoint withOffsets:(CGPoint)offsets
{
    CGFloat dataX = ((viewPoint.x - xCenterOffset)/xDataToPixel) + coordinateSpace.origin.x - offsets.x;
    CGFloat dataY = ((self.displayBounds.size.height - yCenterOffset - viewPoint.y)/yDataToPixel) + coordinateSpace.origin.y - offsets.y;
    
    return CGPointMake(dataX, dataY);
}

- (BOOL)compatibleWithBase:(DPSpatialDataBase*)otherBase
{
    if([otherBase isKindOfClass:[DPSpatialDataFixedAspectBase class]])
    {
        return ((self.aspectRatio == ((DPSpatialDataFixedAspectBase*)otherBase).aspectRatio) && [super compatibleWithBase:otherBase]);
    }
    else
    {
        return NO;
    }
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	//NSString *altColon = @"⁚";
	[super encodeWithCoder:coder];
    
    [coder encodeDouble:self.aspectRatio forKey:@"AspectRatio"];
    [coder encodeDouble:self.xCenterOffset forKey:@"XCenterOffset"];
    [coder encodeDouble:self.yCenterOffset forKey:@"YCenterOffset"];

}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
        self.aspectRatio = [coder decodeDoubleForKey:@"AspectRatio"];
        self.xCenterOffset = [coder decodeDoubleForKey:@"XCenterOffset"];
        self.yCenterOffset = [coder decodeDoubleForKey:@"YCenterOffset"];
	}
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    DPSpatialDataFixedAspectBase* copy = [super copyWithZone:zone];
    copy.aspectRatio = self.aspectRatio;
    copy.xCenterOffset = self.xCenterOffset;
    copy.yCenterOffset = self.yCenterOffset;
    return copy;
}

@end
