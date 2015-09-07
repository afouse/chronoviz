//
//  EthnographerNotesView.h
//  ChronoViz
//
//  Created by Adam Fouse on 3/16/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "AnnotationView.h"
#import "DPStateRecording.h"
@class AnotoNotesData;
@class DPMaskedSelectionView;
@class EthnographerTemplate;

@interface EthnographerNotesView : NSView <AnnotationView,DPStateRecording>  {
	
	NSMutableArray *notesData;
	NSMutableDictionary *sessionLayers;
	EthnographerTemplate *backgroundTemplate;
	
	float scaleConversionFactor;
	float scaleFactor;
	float scaleValue;
	
	NSMutableDictionary *pages;
	NSMutableDictionary *pageOffsets;
	NSMutableDictionary *pageScaleCorrections;
	NSMutableArray *pageOrder;
	
	CGPDFDocumentRef backgroundPDF;
	
	BOOL showPen;
	CALayer *clickLayer;
	
	BOOL selectionMode;
	DPMaskedSelectionView *selectionView;
	NSMutableArray *selectedTraces;
	
	BOOL tail;
	NSTimeInterval tailTime;
	
	QTTime currentTime;
	NSString* currentPage;
    
    NSString* title;
	
}

@property NSTimeInterval tailTime;
@property BOOL showPen;
@property(copy) NSString* title;
@property(readonly) float scaleConversionFactor;

-(void)setData:(AnotoNotesData*)source;
-(void)addData:(TimeCodedData*)source;
-(void)removeData:(TimeCodedData*)source;
-(void)updateData:(AnotoNotesData*)source;

-(void)redrawAllTraces;

-(void)showPage:(NSString*)pageId;
-(QTTime)timeForNotePoint:(NSPoint)point onPage:(NSString*)pageId;
-(QTTime)timeForViewPoint:(NSPoint)point onPage:(NSString*)pageId;
-(CALayer*)traceLayerForViewPoint:(NSPoint)point onPage:(NSString*)pageId;

- (IBAction)nextPage:(id)sender;
- (IBAction)previousPage:(id)sender;

- (IBAction)rotateCW:(id)sender;
- (IBAction)rotateCCW:(id)sender;
-(void)setRotation:(int)rotationLevel;
-(void)setRotation:(int)rotationLevel forPage:(NSString*)pageNumber;
-(int)currentRotation;

- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (void)setZoom:(CGFloat)zoomLevel;

- (IBAction)toggleSelectionMode:(id)sender;
- (NSArray*)selectedTraces;

- (NSArray*)pages;

@end
