//
//  EthnographerPlugin.h
//  ChronoViz
//
//  Created by Adam Fouse on 3/28/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import "DPAppPlugin.h"
@class AnotoViewController;
@class EthnographerDataSource;
@class EthnographerNotesView;
@class EthnographerProject;
@class EthnographerTemplate;
@class EthnographerTemplateManagementController;
@class EthnographerPrinter;
@class EthnographerInstaller;
@class EthnographerTrajectory;
@class AppController;
@class DPBluetoothPen;
@class DPSpatialDataView;

extern NSString * const AFAllowPenAnnotationsKey;
extern NSString * const AFEthnographerProjectsDirectoryKey;
extern NSString * const AFEthnographerKeepTempAnnotationFiles;

extern NSString* const DPBluetoothPenRequiredVersion;

@interface EthnographerPlugin : NSObject <DPAppPlugin> {

	id theApp;
	
    BOOL installedAndSetup;
    
	NSString *projectsDirectory;
	NSMutableArray *projectNames;
	
    NSMutableDictionary *controlFiles;
    
	NSString *penClientPath;
    NSString *penPrintingPath;
	NSString *printingClientPath;
    NSString *penDataClientPath;
    NSString *ethnographerTransferPath;
    NSString *ethnographerPenletPath;
    NSString *ethnographerPenletControlsPath;
    NSString *projectsFolderTemplatePath;
    NSString *controlsPath;
	
	NSMenuItem *installMenuItem;
	
    BOOL transferToolRunning;
	ProcessSerialNumber transferToolPSN;
    
	EthnographerProject *currentProject;
	
	CMTime annotationStartTime;
	NSString *annotationPage;
	EthnographerNotesView *annotationViewController;
	EthnographerDataSource *annotationDataSource;
    NSMutableDictionary *noteFileAnnotations;
    
    NSString *lastLivescribePage;
    EthnographerNotesView *lastNotesView;
	EthnographerDataSource *lastDataSource;
    
	NSDate *lastAnnotation;
	
	EthnographerTemplateManagementController *templatesController;
	DPBluetoothPen *bluetoothPen;
	NSMutableSet *loadedPages;
	
	NSWindow* projectSelectionWindow;
	IBOutlet NSTableView *projectTable;
	
	EthnographerPrinter *printer;
    EthnographerInstaller *installer;
    
    NSMutableDictionary *noteFiles;
    EthnographerTrajectory *currentTrajectory;
    NSMutableDictionary *trajectories;
    DPSpatialDataView *trajectoryView;
    NSString *currentTrajectoryControl;
    NSMenuItem *trajectoriesMenuItem;
    NSMutableArray *trajectoriesInspectors;
}

@property(retain) EthnographerProject *currentProject;
@property(nonatomic,retain) IBOutlet NSWindow* projectSelectionWindow;
@property(retain) EthnographerTrajectory *currentTrajectory;
@property(copy) NSString *lastLivescribePage;
@property(readonly) NSString *penClientPath;
@property(readonly) NSString *penPrintingPath;
@property(readonly) NSString *printingClientPath;
@property(readonly) NSString *penDataClientPath;
@property(readonly) NSString *ethnographerTransferPath;
@property(readonly) NSString *ethnographerPenletPath;
@property(readonly) NSString *ethnographerPenletControlsPath;
@property(readonly) NSString *projectsFolderTemplatePath;
@property(assign) EthnographerDataSource *annotationDataSource;


+ (EthnographerPlugin*)defaultPlugin;

- (void) setup;
- (void) reset;
- (void) resetTrajectories;

- (IBAction)installEthnographer:(id)sender;
- (IBAction)updateEthnographer:(id)sender;
- (IBAction)installPenlet:(id)sender;

- (IBAction)requestProjectSelection:(id)sender;
- (IBAction)cancelProjectSelection:(id)sender;
- (IBAction)showTemplatesWindow:(id)sender;
- (IBAction)requestNewProjectName:(id)sender;
- (void)requestNewProjectNameInWindow:(NSWindow*)theWindow withCallback:(SEL)callbackSel andTarget:(id)target;

- (IBAction)showDataTransferWindow:(id)sender;

- (IBAction)showEthnographerHelp:(id)sender;

- (NSArray*)projectNames;
- (BOOL)hasCurrentProject;
- (EthnographerProject*)currentProject;
- (EthnographerProject*)projectForName:(NSString*)projectName;
- (EthnographerProject*)createNewProject:(NSString*)projectName;

- (void)loadSession:(NSString*)sessionFile;
- (void)deleteSession:(NSString*)sessionFile;
- (void)moveSession:(NSString*)sessionFile toProject:(EthnographerProject*)project;

- (NSDictionary*)controlFiles;

- (void)registerDataSource:(EthnographerDataSource*)source;
- (NSArray*)currentAnotoPages;

- (EthnographerPrinter*) printer;
- (DPBluetoothPen*) bluetoothPen;

- (BOOL)checkLivescribeDesktop;

- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent;

@end
