//
//  DPSpatialAnnotationWindowController.h
//  
//
//  Created by Adam Fouse on 10/18/15.
//
//

#import <Cocoa/Cocoa.h>
#import "AnnotationViewController.h"
@class DPSpatialDataView;
@class TimelineView;
@class Annotation;
@class AnnotationCategory;
@class DPDataSelectionPanel;
@class SpatialTimeSeriesData;
@class VideoProperties;

@interface DPSpatialAnnotationWindowController : NSWindowController <AnnotationViewController>

@property(retain) Annotation* currentAnnotation;
@property(retain) VideoProperties* videoProperties;

@end
