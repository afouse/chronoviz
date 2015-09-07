//
//  InteractionAddSegment.h
//  Annotation
//
//  Created by Adam Fouse on 11/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "Interaction.h"

@interface InteractionAddSegment : Interaction {
}

- (id)initWithMovieTime:(QTTime)theMovieTime andSessionTime:(double)theSessionTime;
- (NSString *)description;

@end
