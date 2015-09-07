//
//  EthnographerInstaller.h
//  ChronoViz
//
//  Created by Adam Fouse on 12/7/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
#import <WebKit/WebKit.h>
@class DPComponentInstaller;
@class EthnographerPlugin;

@interface EthnographerInstaller : NSWindowController {
    NSView *currentView;
    
    NSView *instructionsView;
    NSView *projectsSetupView;
    NSMatrix *projectsOptionsButtons;
    NSButton *nextButton;
    NSButton *cancelButton;
    WebView *instructionsWebView;
    NSTextField *existingFolderLocationField;
    NSTextField *emailSignupField;
    NSTextField *dropboxLocationLabel;
    NSTextField *documentsLocationLabel;
    NSView *updateView;
    
    CATransition *transition;
    
    DPComponentInstaller *installer;
    
    EthnographerPlugin *plugin;
    NSView *existingProjectsView;
    
    NSString *defaultProjectsFolderName;
    
    NSString *dropboxDirectory;
    NSString *defaultDropboxLocation;
    NSString *defaultDocumentsLocation;
    NSString *existingProjectsFolder;
    NSString *selectedProjectsFolder;
    
    NSView *penletInstallView;
    
    BOOL update;
    NSView *completeView;
    NSView *updateCompleteView;
}

@property BOOL update;
@property(retain) NSString* defaultDropboxLocation;
@property(retain) NSString* defaultDocumentsLocation;
@property(retain) NSString* selectedProjectsFolder;
@property(retain) NSString* existingProjectsFolder;

@property (assign) IBOutlet NSTextField *dropboxLocationLabel;
@property (assign) IBOutlet NSTextField *documentsLocationLabel;
@property (assign) IBOutlet NSView *penletInstallView;
@property (assign) IBOutlet NSView *completeView;
@property (assign) IBOutlet NSView *existingProjectsView;
@property (assign) IBOutlet NSView *instructionsView;
@property (assign) IBOutlet NSView *projectsSetupView;
@property (assign) IBOutlet NSView *updateView;
@property (assign) IBOutlet NSView *updateCompleteView;
@property (assign) IBOutlet NSMatrix *projectsOptionsButtons;
@property (assign) IBOutlet NSButton *nextButton;
@property (assign) IBOutlet NSButton *cancelButton;
@property (assign) IBOutlet WebView *instructionsWebView;
@property (assign) IBOutlet NSTextField *existingFolderLocationField;
@property (assign) IBOutlet NSTextField *emailSignupField;

- (id)initWithPlugin:(EthnographerPlugin*)ethnoPlugin;

- (IBAction)cancel:(id)sender;
- (IBAction)printWebViewContents:(id)sender;
- (IBAction)startDownload:(id)sender;
- (IBAction)selectProjectsLocation:(id)sender;
- (IBAction)createFolder:(id)sender;
- (IBAction)selectExistingFolder:(id)sender;
- (IBAction)useExistingFolder:(id)sender;
- (IBAction)beginPenletInstallation:(id)sender;
- (IBAction)confirmPenletInstallation:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)openTemplatesWindow:(id)sender;
- (IBAction)changeSelectedProjectsFolder:(id)sender;

@end
