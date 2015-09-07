//
//  DPViewFactory.h
//  DataPrism
//
//  Created by Adam Fouse on 6/17/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TimeCodedData;
@class AppController;
@class AnnotationDocument;
@class VideoProperties; 
@class AFMovieView;

@interface DPViewManager : NSObject <NSOutlineViewDelegate,NSOutlineViewDataSource>{

	AppController *controller;
	
	NSMutableArray *timelineOptions;
	
	NSMutableDictionary *viewClasses;
    NSMutableDictionary *controllerClasses;
    NSMutableDictionary *dataTypeNames;
}

- (id)initForController:(AppController*)appController;

- (void)update;

- (void)registerDataClass:(Class)dataClass withViewClass:(Class)viewClass controllerClass:(Class)controllerClass viewMenuName:(NSString*)menuName;
- (Class)controllerClassForViewClass:(Class)viewClass;

- (void)showData:(TimeCodedData*)dataSet;
- (void)showData:(TimeCodedData*)dataSet ifRepeat:(BOOL)repeat;
- (void)showDataInMainView:(TimeCodedData*)dataSet;
- (NSArray*)showDataSets:(NSArray*)dataSets ifRepeats:(BOOL)repeats;
- (NSArray*)viewsForData:(TimeCodedData*)dataSet;

- (void)showDataInMainViewAction:(id)sender;

- (void)removeData:(TimeCodedData*)dataSet;

- (void)zoomInVideo:(VideoProperties*)video;
- (void)zoomOutVideo:(VideoProperties*)video;
- (AFMovieView*)viewForVideo:(VideoProperties*)video;
- (void)closeVideo:(VideoProperties*)video;

- (void)createAudioTimeline:(VideoProperties*)movie;

- (NSArray*)viewMenuItems;

@end
