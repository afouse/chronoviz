//
//  InteractionAnnotaitonEdit.h
//  Annotation
//
//  Created by Adam Fouse on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Interaction.h"
@class Annotation;

@interface InteractionAnnotationEdit : Interaction {

	NSString *annotationTitle;
	CMTime annotationTime;
	
	NSString *attribute;
	NSObject *value;
	
}

- (id)initWithAnnotation:(Annotation*)theAnnotation 
			forAttribute:(NSString*)theAttribute 
			   withValue:(NSObject*)theValue
		  andSessionTime:(double)theSessionTime;

- (id)initWithAnnotationTitle:(NSString*)theAnnotationTitle
                    startTime:(CMTime)startTime
                 forAttribute:(NSString*)theAttribute 
                    withValue:(NSObject*)theValue
               andSessionTime:(double)theSessionTime;

-(CMTime)annotationTime;

@end
