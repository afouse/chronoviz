//
//  DPExportFrameImages.h
//  ChronoViz
//
//  Created by Adam Fouse on 5/3/12.
//  Copyright (c) 2012 University of California, San Diego. All rights reserved.
//

#import "DPExport.h"
@class Annotation;
@class VideoProperties; 

@interface DPExportFrameImages : DPExport{
    
	Annotation *annotation;
	VideoProperties* video;
}

@property(assign) Annotation* annotation;
@property(assign) VideoProperties* video;

@end
