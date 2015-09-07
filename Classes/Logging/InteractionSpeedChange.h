//
//  InteractionSpeedChange.h
//  Annotation
//
//  Created by Adam Fouse on 11/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "Interaction.h"

@interface InteractionSpeedChange : Interaction {
	float speed;
}

- (float)speed;

- (id)initWithSpeed:(float)theSpeed andMovieTime:(QTTime)theMovieTime atTime:(double)theSessionTime;
- (NSString *)description;

@end
