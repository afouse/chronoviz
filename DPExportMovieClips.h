//
//  DPExportMovieClips.h
//  DataPrism
//
//  Created by Adam Fouse on 3/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DPExport.h"
@class Annotation;
@class VideoProperties; 

@interface DPExportMovieClips : DPExport {

	Annotation *annotation;
	VideoProperties* video;
}

@property(assign) Annotation* annotation;
@property(assign) VideoProperties* video;

@end
