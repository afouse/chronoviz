//
//  MovieControllerView.h
//  Annotation
//
//  Created by Adam Fouse on 10/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import "AppController.h"

@interface MovieControllerView : NSView {
	
	IBOutlet AFMovieView *mMovieView;
	IBOutlet AppController *mAppController;
	
}

@end
