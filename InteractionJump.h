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
	QTTime fromTime;
	QTTime toTime;
}

- (id)initWithFromMovieTime:(QTTime)fromMovieTime toMovieTime:(QTTime)toMovieTime andSessionTime:(double)theSessionTime;
- (NSString *)description;

- (QTTime)fromMovieTime;
- (QTTime)toMovieTime;

@end
