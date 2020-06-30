//
//  AppController.h
//  Annotation
//
//  Created by Adam Fouse on 10/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
#import <AVFoundation/AVFoundation.h>
#import "DPConstants.h"
#import "DPStateRecording.h"
#import "AnnotationView.h"
@class PreferenceController;
@class MultiTimelineView;
@class TimelineView;
@class TimelineMarker;
@class Annotation;
@class AnnotationCategory;
@class AnnotationXMLParser;
@class AnnotationInspector;
@class VideoProperties;
@class VideoPropertiesController;
@class VideoFrameLoader;
@class AnnotationHover;
@class TimeSeriesData;
@class MapController;
@class AnnotationDocument;
//@class ImageSequenceController;
//@class ImageSequenceView;
@class AnnotationTableController;
@class PluginScriptController;
@class AnnotationFiltersController;
@class MediaWindowController;
@class LinkedFilesController;
@class CategoriesWindowController;
@class TimeCodedImageFiles;
@class OverviewTimelineView;
@class AnnotationQuickEntry;
@class TranscriptViewController;
@class AFMovieView;
@class DPViewManager;
@class DPConsoleWindowController;
@class FeedbackController;
@class DPURLHandler;
@class DPDocumentVariablesController;
@class DPPluginManager;

//extern int const DataPrismSelectTool;
//extern int const DataPrismZoomTool;
//
//extern NSString * const DataPrismLogState;

@interface AppController : NSObject <DPStateRecording,NSWindowDelegate,NSOpenSavePanelDelegate,NSAnimationDelegate> {

	IBOutlet NSWindow *mMovieWindow;
	IBOutlet AFMovieView *mMovieView;
	IBOutlet NSView *movieControllerView;
	IBOutlet NSView *movieControlsBox;
	IBOutlet NSSplitView *splitView;
	NSView *mainView;
	
	IBOutlet NSWindow *newDocumentWindow;
	float newDocumentDuration;
	
    NSWindow *documentLoadingWindow;
    
	// Movie controls
	IBOutlet NSButton *playButton;
	IBOutlet NSButton *movieTimeButton;
	
	IBOutlet NSPanel *timelineSelectionPanel;
	IBOutlet NSOutlineView *timelineSelectionView;
	IBOutlet NSScrollView *timelineScrollView;
	IBOutlet MultiTimelineView *timelineView;
	IBOutlet OverviewTimelineView *overviewTimelineView;
	
	NSMutableArray *annotationViews;
	NSMutableArray *dataWindowControllers;
	
	// Annotations
	IBOutlet AnnotationInspector *inspector;
	IBOutlet AnnotationHover *annotationHover;
	IBOutlet AnnotationQuickEntry *quickEntry;
	IBOutlet NSView *saveAsView;
	IBOutlet NSPopUpButton *saveFileTypesButton;
	BOOL pauseWhileAnnotating;
	BOOL popUpAnnotations;
	NSSavePanel *annotationsSavePanel;
	BOOL forceKeyframeUpdate;
	
	BOOL tempAnnotationDoc;
	NSString *backupAnnotationFile;
	AnnotationDocument *annotationDoc;
	Annotation *selectedAnnotation;
	CMTimeRange currentSelection;
	
	IBOutlet NSMenu *fileMenu;
	IBOutlet NSMenu *exportMenu;
	IBOutlet NSMenu *analysisMenu;
	IBOutlet NSMenu *viewMenu;
    IBOutlet NSMenu *savedStatesMenu;
	
	AVPlayer *mMovie;
    VideoProperties *mainVideo;
	NSString *movieFileName;
	BOOL loadingMovie;
	
	NSMutableArray *activeMovies;
	NSLock *rateLock;
	float mRate;
	float stepSize;
	float playbackRate;
	BOOL playing;
	BOOL paused;
	BOOL fullScreen;
    BOOL visibleOverviewTimeline;
	float zoomFactor;
	BOOL autoZoom;
	BOOL hideMouse;
	BOOL ignoreRateInput;
	BOOL autoSave;
	BOOL openVideosHalfSize;
	BOOL animating;
	BOOL loopPlayback;
	BOOL annotationPlayback;
	BOOL absoluteTime;
	
	int currentTool;
	IBOutlet NSSegmentedControl* toolControl;
	
	NSTimer *timer;
	NSTimer *timeDisplayTimer;
	BOOL uploadInteractions;
	
	NSUndoManager *undoManager;
	
	PreferenceController *prefController;
	
	DPViewManager *viewManager;
    
    DPPluginManager *appPluginManager;
	
	DPURLHandler *urlHandler;
		
	VideoPropertiesController *videoPropertiesController;
	
	VideoFrameLoader *frameLoader;
	
	MapController *mapController;
	
//	ImageSequenceController *imageSequenceController;
//	ImageSequenceView *imageSequenceView;
	
	AnnotationTableController *annotationTableController;
	
	PluginScriptController *pluginScriptController;
	
	AnnotationFiltersController *annotationFiltersController;
	
	MediaWindowController *mediaWindowController;
	LinkedFilesController *linkedFilesController;
	DPDocumentVariablesController *documentVariablesController;
	
	CategoriesWindowController *categoriesWindowController;
	
	DPConsoleWindowController *consoleWindowController;
	
	FeedbackController *feedbackController;

}

@property(readonly) AnnotationDocument *document; 
@property(readonly) AVPlayer* mMovie;
@property(readonly) AVPlayerItem* playerItem;
@property(readonly) VideoFrameLoader *frameLoader;
@property(readonly) NSUndoManager *undoManager;
@property(readonly) LinkedFilesController *linkedFilesController;
@property(readonly) DPDocumentVariablesController *documentVariablesController;
@property BOOL hideMouse;
@property BOOL autoSave;
@property BOOL saveInteractions;
@property BOOL uploadInteractions;
@property BOOL pauseWhileAnnotating;
@property BOOL popUpAnnotations;
@property BOOL openVideosHalfSize;
@property BOOL animating;
@property BOOL absoluteTime;
@property(retain) NSString* movieFileName;
@property(retain) Annotation* selectedAnnotation;
@property float stepSize;
@property float playbackRate;
@property float newDocumentDuration;
@property int currentTool;
@property (assign) IBOutlet NSPopUpButton *selectedCategoryPopupButton;
@property(retain) id boundaryListener;

+ (AppController*)currentApp;
+ (AnnotationDocument*)currentDoc;

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;
- (void)bringVideoToFront;
- (void)continueTermination;

- (void)setMainVideo:(VideoProperties *)video;
- (AVPlayer *)movie;
- (AVPlayer *)mMovie;
- (CMTime)currentTime;
- (CMTimeRange)currentSelection;
//- (ImageSequenceView *)imageSequenceView;
- (NSWindow *)window;
- (AnnotationDocument *)document;
- (DPViewManager*)viewManager;
- (DPURLHandler*)urlHandler;
- (NSArray*) annotationViews;
- (NSArray*) dataWindowControllers;
- (NSView*)mainView;
- (void)addAnnotation:(Annotation*)annotation;

- (MultiTimelineView *)timelineView;
- (void)resizeTimelineView;

- (void)replaceMainView:(NSView*)view;
- (void)addAnnotationView:(id <AnnotationView>)view;
- (void)removeAnnotationView:(id <AnnotationView>)view;
- (void)addDataWindow:(NSWindowController*)dataWindow;
- (void)removeDataWindow:(NSWindowController*)dataWindow;
- (AnnotationFiltersController*)annotationFiltersController;

- (IBAction)showSpatialOverlay:(id)sender;
- (IBAction)showConsole:(id)sender;
- (IBAction)showMap:(id)sender;
- (IBAction)showAnnotationTable:(id)sender;
//- (void)showImageSequence:(TimeCodedImageFiles*)sequence inMainWindow:(BOOL)mainWindow;

- (void)updateDisplay:(NSTimer *)aTimer;

- (IBAction)saveCurrentState:(id)sender;
- (IBAction)restoreSavedState:(id)sender;

- (void)zoom:(float)factor;
- (IBAction)doubleSize:(id)sender;
- (IBAction)normalSize:(id)sender;
- (IBAction)tripleSize:(id)sender;

- (IBAction)createNewAnnotationDocument:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)revertToBackup:(id)sender;
- (void)setAnnotationDocument:(AnnotationDocument*)doc;
- (void)showDocumentLoading:(id)sender;
- (void)endDocumentLoading:(id)sender;

- (void)moveToTime:(CMTime)time fromSender:(id)sender;
- (void)setRate:(float)rate fromSender:(id)source;
- (void)resumePlaying;

- (IBAction)changeTimeFormat:(id)sender;
- (IBAction)timeButtonClicked:(id)sender;
- (IBAction)playbackModeButtonClicked:(id)sender;
- (IBAction)togglePlay:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)stepForward:(id)sender;
- (IBAction)stepOneFrameForward:(id)sender;
- (IBAction)stepOneFrameBackward:(id)sender;
- (IBAction)stepBack:(id)sender;
- (IBAction)fastForward:(id)sender;
- (IBAction)rewind:(id)sender;

- (IBAction)openPluginsFolder:(id)sender;
- (IBAction)showPluginScripts:(id)sender;
- (IBAction)reloadPlugins:(id)sender;

- (IBAction)openQuickStartGuide:(id)sender;
- (IBAction)sendFeedback:(id)sender;

- (IBAction)addTimeline:(id)sender;
- (IBAction)cancelAddTimeline:(id)sender;
- (IBAction)showMediaWindow:(id)sender;
- (IBAction)showLinkedFilesWindow:(id)sender;
- (IBAction)showDocumentVariablesWindow:(id)sender;
- (void)registerMedia:(VideoProperties*)videoProperties andDisplay:(BOOL)show;
- (void)showMedia:(VideoProperties*)videoProperties;
- (IBAction)showMediaFromObject:(id)sender;
- (void)removeMedia:(VideoProperties*)videoProperties;
- (IBAction)showCategoriesWindow:(id)sender;
- (IBAction)showDataAction:(id)sender;
- (IBAction)showAnnotationInspector:(id)sender;
- (IBAction)showAnnotationQuickEntry:(id)sender;
- (void)showAnnotationQuickEntryForCategory:(AnnotationCategory*)category;
- (IBAction)newAnnotation:(id)sender;
- (IBAction)loadXMLAnnotations:(id)sender;
- (IBAction)importData:(id)sender;
//- (IBAction)importMedia:(id)sender;
- (IBAction)export:(id)sender;
- (IBAction)exportAnnotations:(id)sender;
- (IBAction)saveAnnotationsAs:(id)sender;
- (IBAction)changeSaveFileType:(id)sender;
- (IBAction)removeCurrentAnnotation:(id)sender;
- (IBAction)showVideoProperties:(id)sender;
- (IBAction)updateAllKeyframes:(id)sender;
- (void)loadAnnotations:(NSString*)filename;
- (BOOL)deleteKeyframeFile:(Annotation*)annotation;
- (void)updateAnnotationKeyframe:(Annotation*)annotation;
- (void)loadAnnotationKeyframeImage:(Annotation*)annotation;
- (void)removeAnnotation:(Annotation*)annotation;
- (void)updateAnnotation:(Annotation*)annotation;
- (void)saveXMLAnnotationsToFile:(NSString*)filename;
- (void)saveCSVAnnotationsToFile:(NSString*)filename;
- (void)displayHoverForTimelineMarker:(TimelineMarker*)marker;
- (void)closeHoverForMarker:(TimelineMarker*)marker;
- (void)selectTimelineMarker:(TimelineMarker*)marker;

- (void)addMenuItem:(NSMenuItem*)menuItem toMenuNamed:(NSString*)menuName;
- (void)updateViewMenu;

- (void)setTool:(int)toolID;
- (IBAction)selectTool:(id)sender;
- (IBAction)zoomButtonClicked:(id)sender;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (void)zoomToTimeRange:(CMTimeRange)timeRange;
- (void)zoomInToTime:(CMTime)time;
- (void)setOverviewVisible:(BOOL)isVisible;

- (IBAction)outputLog:(id)sender;

- (IBAction)showPreferencePanel:(id)sender;
- (IBAction)showVisualization:(id)sender;
- (IBAction)updateVisualization:(id)sender;
- (IBAction)exportVisualization:(id)sender;

- (IBAction)goFullScreen:(id)sender; // toggle full screen
- (IBAction)exitFullScreen:(id)sender;

@end
