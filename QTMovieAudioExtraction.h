//
//  QTMovieAudioExtraction.h
//  Annotation
//
//  Created by Adam Fouse on 12/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "DPConstants.h"
@class AudioVisualizer;

@interface QTMovie (AudioExtraction)

- (NSArray*) getAudioSubset:(NSInteger)subsetSize withCallback:(AudioVisualizer*)viz usingSubsetMethod:(DPSubsetMethod)subsetMethod;
- (NSArray*) getAudioSubset:(NSInteger)subsetSize withCallback:(AudioVisualizer*)viz;
- (NSArray*) getAudioSubset:(NSInteger)subsetSize;

@end
