//
//  ImageSequenceView.h
//  Annotation
//
//  Created by Adam Fouse on 11/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "AnnotationPlaybackControllerView.h"
#import "DPStateRecording.h"
@class TimeCodedString;
@class TimeCodedImageFiles;
@class Annotation;

@interface ImageSequenceView : AnnotationPlaybackControllerView <DPStateRecording> {

	NSArray* imageSequence;
    TimeCodedImageFiles* imageFiles;
	TimeCodedString* currentPictureFile;
	NSImage* currentImage;
	NSUInteger currentIndex;
	
    Annotation *lastAddedAnnotation;
    
	NSMutableDictionary* imageCache;
	int maxItems;
	
}

//-(void)setImageSequence:(NSArray*)sequence;
-(void)setTimeCodedImageFiles:(TimeCodedImageFiles*)files;

-(void)update;

-(NSUInteger)showPictureAtIndex:(NSUInteger)index;

-(NSImage*)imageAtTime:(QTTime)time;
-(CGImageRef)cgImageAtTime:(QTTime)time;

@end
