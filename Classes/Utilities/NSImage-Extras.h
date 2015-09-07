//
//  NSImage-Extras.h
//
//  Created by Scott Stevenson on 9/28/07.
//  Released under a BSD-style license. See License.txt

#import <Cocoa/Cocoa.h>

CGImageRef CreateCGImageFromData(NSData* data);

@interface NSImage (Extras)

// creates a copy of the current image while maintaining
// proportions. also centers image, if necessary

- (NSSize)proportionalSizeForTargetSize:(NSSize)aSize;

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)aSize;

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize
                                       flipped:(BOOL)isFlipped;

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize
                                       flipped:(BOOL)isFlipped
                                      addFrame:(BOOL)shouldAddFrame
                                     addShadow:(BOOL)shouldAddShadow;

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize
                                       flipped:(BOOL)isFlipped
                                      addFrame:(BOOL)shouldAddFrame
                                     addShadow:(BOOL)shouldAddShadow
                                      addSheen:(BOOL)shouldAddSheen;

- (CGImageRef) cgImage;

- (CGImageRef) cgImageWithSize:(NSSize)theSize;

- (CGImageRef) createCgImage;

@end
