//
//  InteractionJump.h
//  Annotation
//
//  Created by Adam Fouse on 1/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Interaction.h"

@interface InteractionJump : Interaction {
	CMTime fromTime;
	CMTime toTime;
}

- (id)initWithFromMovieTime:(CMTime)fromMovieTime toMovieTime:(CMTime)toMovieTime andSessionTime:(double)theSessionTime;
- (NSString *)description;

- (CMTime)fromMovieTime;
- (CMTime)toMovieTime;

@end
