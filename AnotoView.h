//
//  AnotoView.h
//  DataPrism
//
//  Created by Adam Fouse on 2/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "AnnotationView.h"
#import "DPStateRecording.h"
@class AnotoNotesData;

__attribute__((deprecated))
@interface AnotoView : NSView <AnnotationView,DPStateRecording> {

	AnotoNotesData *data;
	
	float scaleConversionFactor;
	float scaleFactor;
	float scaleValue;
	
	NSMutableArray *traceLayers;
	NSMutableDictionary *pages;
	NSMutableDictionary *pageOffsets;
	NSMutableDictionary *pageScaleCorrections;
	NSMutableArray *pageOrder;
	
	CALayer *clickLayer;
	
	QTTime currentTime;
	NSString* currentPage;
}

-(void)setData:(AnotoNotesData*)source;
-(void)showPage:(NSString*)pageId;
-(QTTime)timeForNotePoint:(NSPoint)point onPage:(NSString*)pageId;
-(QTTime)timeForViewPoint:(NSPoint)point onPage:(NSString*)pageId;

- (IBAction)nextPage:(id)sender;
- (IBAction)previousPage:(id)sender;

- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (void)setZoom:(CGFloat)zoomLevel;

- (NSArray*)pages;

- (CGRect)updatePathForTraceLayer:(CALayer*)traceLayer;

@end
