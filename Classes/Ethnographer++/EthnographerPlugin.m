//
//  EthnographerPlugin.m
//  ChronoViz
//
//  Created by Adam Fouse on 3/28/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "EthnographerPlugin.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "LinkedFilesController.h"
#import "DPViewManager.h"
#import "DPURLHandler.h"
#import "NSString+URIQuery.h"
#import "AnotoNotesData.h"
#import "AnotoTrace.h"
#import "EthnographerViewController.h"
#import "EthnographerDataSource.h"
#import "EthnographerNotesView.h"
#import "EthnographerProject.h"
#import "EthnographerTemplate.h"
#import "EthnographerPrinter.h"
#import "EthnographerInstaller.h"
#import "DPBluetoothPen.h"
#import "DPApplicationSupport.h"
#import "DPComponentInstaller.h"
#import "NSStringFileManagement.h"
#import "EthnographerTemplateManagementController.h"
#import "EthnographerTrajectory.h"
#import "DPPath.h"
#import "DPPathSegment.h"
#import "DPSpatialDataView.h"
#import "DPSpatialDataWindowController.h"
#import "DPSpatialDataBase.h"
#import "DPSpatialDataImageBase.h"
#import "OrientedSpatialTimeSeriesData.h"
#import "EthnographerTrajectoryData.h"
#import "Annotation.h"
#import "AnnotationSet.h"
#import "AnnotationCategory.h"
#import "EthnographerTrajectoryInspectorWindowController.h"

NSString* const DPBluetoothPenRequiredVersion = @"1.3";

static const NSUInteger DP_NOTES_FILE_CACHE_MAX = 500;

NSString * const AFAllowPenAnnotationsKey = @"AllowPenAnnotations";
NSString * const AFEthnographerProjectsDirectoryKey = @"EthnographerProjectsDirectory";
NSString * const AFEthnographerDocumentProjectKey = @"Ethnographer++ Project";
NSString * const AFEthnographerKeepTempAnnotationFiles = @"EthnographerKeepTempAnnotationFiles";

static EthnographerPlugin* defaultEthnographerPlugin;

static NSString * const transferToolBundleIdentifier = @"edu.ucsd.hci.TransferTool";

@interface EthnographerPlugin (Internal)

- (NSString*)defaultProjectDirectory;
- (BOOL)checkInstallationStatus;
- (void)createProjectsDirectory;

- (void)endAnnotationMode:(id)sender;

- (void)trajectoryWindowClosed:(NSNotification*)notification;

@end

@implementation EthnographerPlugin

@synthesize projectSelectionWindow,currentTrajectory,lastLivescribePage;
@synthesize penClientPath,penPrintingPath,printingClientPath,penDataClientPath,ethnographerTransferPath,ethnographerPenletPath,ethnographerPenletControlsPath,projectsFolderTemplatePath,annotationDataSource;

+ (EthnographerPlugin*)defaultPlugin
{
	return defaultEthnographerPlugin;
}

- (id) initWithAppProxy:(DPAppProxy *)appProxy
{
	self = [super init];
	if (self != nil) {
        
		theApp = [AppController currentApp];
		
        installedAndSetup = NO;
        
		self.currentProject = nil;
		self.projectSelectionWindow = nil;
        self.currentTrajectory = nil;
        currentTrajectoryControl = nil;
		printer = nil;
        
        controlFiles = [[NSMutableDictionary alloc] init];
		
		penClientPath = [[[DPApplicationSupport userSupportFolder] stringByAppendingPathComponent:@"Devices/PenBrowser.app"] retain];
        penPrintingPath = [[[DPApplicationSupport userSupportFolder] stringByAppendingPathComponent:@"PenPrinting"] retain];
        penDataClientPath = [[penPrintingPath stringByAppendingPathComponent:@"TransferTool.app"] retain];
        printingClientPath = [[penDataClientPath stringByAppendingPathComponent:@"Contents/Resources/AnotoPrinter.jar"] retain];
        ethnographerTransferPath = [[penDataClientPath stringByAppendingPathComponent:@"Contents/Resources/ethnographerpp_transfer/ethnographerPPtransfer"] retain];
        ethnographerPenletPath = [[penDataClientPath stringByAppendingPathComponent:@"Contents/Resources/ethnographerpp/Ethnographer++.jar"] retain];
        ethnographerPenletControlsPath = [[penDataClientPath stringByAppendingPathComponent:@"Contents/Resources/ethnographerpp/ControlPanel_pen.afd"] retain];
        projectsFolderTemplatePath = [[penPrintingPath stringByAppendingPathComponent:@"/resources/projects.zip"] retain];
        controlsPath = [[penPrintingPath stringByAppendingPathComponent:@"/resources/controls"] retain];
		
        
        [LinkedFilesController registerDataSourceClass:[EthnographerDataSource class]];
        
        [[theApp viewManager] registerDataClass:[AnotoNotesData class]
                                  withViewClass:[EthnographerNotesView class]
                                controllerClass:[EthnographerViewController class]
                                   viewMenuName:@"Notes"];
        
		[self setup];
		
		if(!defaultEthnographerPlugin)
		{
			defaultEthnographerPlugin = self;
		}
	}
	return self;
}

- (void) dealloc
{
	self.currentProject = nil;
	self.projectSelectionWindow = nil;
    self.currentTrajectory = nil;
    self.lastLivescribePage = nil;
	
    [trajectoriesInspectors release];
    [trajectoriesMenuItem release];
    
    [currentTrajectoryControl release];
    [controlFiles release];
    [penPrintingPath release];
    [penDataClientPath release];
    [ethnographerTransferPath release];
    [ethnographerPenletPath release];
    [ethnographerPenletControlsPath release];
    [projectsFolderTemplatePath release];
	[penClientPath release];
	[printingClientPath release];
    [controlsPath release];
	[annotationPage release];
	[printer release];
	[templatesController release];
	[bluetoothPen release];
	[projectNames release];
	[projectsDirectory release];
	[lastAnnotation release];
    [noteFiles release];
    [noteFileAnnotations release];
    [trajectories release];
	[super dealloc];
}

- (void) reset
{
	self.currentProject = nil;
	self.projectSelectionWindow = nil;
	
	[installer release];
	
	[templatesController close];
	[templatesController release];
	templatesController = nil;
	
	[annotationPage release];
	annotationPage = nil;
	
    [noteFiles removeAllObjects];
    [noteFileAnnotations removeAllObjects];
    
    self.currentTrajectory = nil;
//    [trajectories release];
//    trajectories = nil;
    
    lastNotesView = nil;
    lastDataSource = nil;
    self.lastLivescribePage = nil;
    
	[bluetoothPen reset];
}

- (void)setup
{
    if(installedAndSetup)
    {
        return;
    }
    
    [installer release];
    installer = nil;
    
    [projectsDirectory release];
    projectsDirectory = [[[NSUserDefaults standardUserDefaults] stringForKey:AFEthnographerProjectsDirectoryKey] retain];
    
    BOOL installed = [self checkInstallationStatus];
    
	if(installed)
	{
		NSDictionary *infodict = [[NSDictionary alloc] initWithContentsOfFile:[penClientPath stringByAppendingPathComponent:@"Contents/Info.plist"]];
		NSString *clientVersion = [[infodict objectForKey:(NSString*)kCFBundleVersionKey] copy];
		[infodict release];
		
		NSLog(@"Client version: %@",clientVersion);
		if([clientVersion compare:(NSString*)DPBluetoothPenRequiredVersion options:NSNumericSearch] == NSOrderedAscending)
		{
            installed = NO;
            installMenuItem = [[NSMenuItem alloc] initWithTitle:@"Update Digital Pen Components…"
                                                         action:@selector(updateEthnographer:)
                                                  keyEquivalent:@""];
            [installMenuItem setTarget:self];
            [theApp addMenuItem:installMenuItem toMenuNamed:@"File"];
		}
		[clientVersion release];
	}
	else
	{
        installMenuItem = [[NSMenuItem alloc] initWithTitle:@"Setup Digital Pen Components…"
													 action:@selector(installEthnographer:)
											  keyEquivalent:@""];
		[installMenuItem setTarget:self];
		[theApp addMenuItem:installMenuItem toMenuNamed:@"File"];
	}
	
    if(installed)
	{	
		if(installMenuItem)
		{
			[[installMenuItem menu] removeItem:installMenuItem];
			[installMenuItem release];
			installMenuItem = nil;
		}
		
        // Check for if the bluetooth connection helper is still running
        for(NSDictionary *appDict in [[NSWorkspace sharedWorkspace] launchedApplications])
        {
            if([[appDict objectForKey:@"NSApplicationBundleIdentifier"] caseInsensitiveCompare:@"edu.ucsd.hci.Penbrowser"] == NSOrderedSame)
            {
                NSNumber *lowPSN = [appDict objectForKey:@"NSApplicationProcessSerialNumberLow"];
                NSNumber *highPSN = [appDict objectForKey:@"NSApplicationProcessSerialNumberHigh"];
                ProcessSerialNumber penBrowserPSN;
                penBrowserPSN.lowLongOfPSN = [lowPSN longValue];
                penBrowserPSN.highLongOfPSN = [highPSN longValue];
                
                AppleEvent tAppleEvent;
                AppleEvent tReply;
                AEBuildError tAEBuildError;
                OSStatus result;
                
                result = AEBuildAppleEvent( kCoreEventClass, kAEQuitApplication, typeProcessSerialNumber, &penBrowserPSN,
                                           sizeof(ProcessSerialNumber), kAutoGenerateReturnID, kAnyTransactionID, &tAppleEvent, &tAEBuildError,"");
                result = AESendMessage( &tAppleEvent, &tReply, kAEAlwaysInteract+kAENoReply, kNoTimeOut);
            }
        }
                
		[[theApp urlHandler] registerHandler:self forCommand:@"note"];
		[[theApp urlHandler] registerHandler:self forCommand:@"penbrowser"];
		[[theApp urlHandler] registerHandler:self forCommand:@"anotoprinter"];
		[[theApp urlHandler] registerHandler:self forCommand:@"trajectory"];
        [[theApp urlHandler] registerHandler:self forCommand:@"changestatus"];
        
		if([[NSUserDefaults standardUserDefaults] boolForKey:AFAllowPenAnnotationsKey])
		{
			[[theApp urlHandler] registerHandler:self forCommand:@"start_annotation"];
			[[theApp urlHandler] registerHandler:self forCommand:@"end_annotation"];	
		}
		
        // Set up templates menu item (with lazy intialization)
		templatesController = nil;
		NSMenuItem *showTemplatesItem = [[NSMenuItem alloc] initWithTitle:@"Digital Notes Manager…"
																   action:@selector(showTemplatesWindow:)
															keyEquivalent:@""];
		[showTemplatesItem setTarget:self];
		
		[theApp addMenuItem:showTemplatesItem toMenuNamed:@"File"];
		[showTemplatesItem release];
        
        // Set up Livescribe menu item
        NSMenuItem *transferDataItem = [[NSMenuItem alloc] initWithTitle:@"Transfer Livescribe Data…"
                                                                  action:@selector(showDataTransferWindow:)
                                                           keyEquivalent:@""];
		[transferDataItem setTarget:self];
		
		[theApp addMenuItem:transferDataItem toMenuNamed:@"File"];
		[transferDataItem release];
        
		// Set up Bluetooth menu item
		bluetoothPen = [[DPBluetoothPen alloc] init];
		NSMenuItem *showBluetoothItem = [[NSMenuItem alloc] initWithTitle:@"Start Bluetooth Pen Connection"
																   action:@selector(startListening:)
															keyEquivalent:@""];
		bluetoothPen.penMenuItem = showBluetoothItem;
		[showBluetoothItem setTarget:bluetoothPen];
		
		[theApp addMenuItem:showBluetoothItem toMenuNamed:@"File"];
		[showBluetoothItem release];
        
        // Set up Help menu item
		NSMenuItem *showEthnographerHelpItem = [[NSMenuItem alloc] initWithTitle:@"Digital Pen and Paper Instructions"
																   action:@selector(showEthnographerHelp:)
															keyEquivalent:@""];
		[showEthnographerHelpItem setTarget:self];
		
		[theApp addMenuItem:showEthnographerHelpItem toMenuNamed:@"Help"];
		[showEthnographerHelpItem release];
        
        
//		NSMenuItem *installPenletItem = [[NSMenuItem alloc] initWithTitle:@"Install Livescribe Penlet"
//																   action:@selector(installPenlet:)
//															keyEquivalent:@""];
//		[installPenletItem setTarget:self];
//		
//		[theApp addFileMenuItem:installPenletItem];
//		[installPenletItem release];
    
		
		if(!projectsDirectory)
		{
			NSLog(@"No projects directory");
		}
		
		projectNames = [[NSMutableArray alloc] init];
		NSError *err = nil;
		NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:projectsDirectory
																			 error:&err];
		for(NSString *file in files)
		{
			if([file characterAtIndex:0] != '.')
			{
				NSString *fullPath = [projectsDirectory stringByAppendingPathComponent:file];
				if([fullPath isDirectory] && [[fullPath stringByAppendingPathComponent:@".mappings.xml"] fileExists])
				{
					[projectNames addObject:file];
				}	
			}
		}
		
        [controlFiles removeAllObjects];
        NSArray *controls = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:controlsPath
																			 error:&err];
		for(NSString *file in controls)
		{
			if([file characterAtIndex:0] != '.')
			{
				NSString *fullPath = [controlsPath stringByAppendingPathComponent:file];
				if([fullPath isDirectory])
				{
                    NSArray *controldata = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath
                                                                                            error:&err];
                    for(NSString *item in controldata)
                    {
                        if([[item pathExtension] caseInsensitiveCompare:@"pdf"] == NSOrderedSame)
                        {
                            NSString *controlPDF = [fullPath stringByAppendingPathComponent:item];
                            [controlFiles setObject:controlPDF forKey:file];
                            break;
                        }
                    }
                
				}	
			}
		}
        
		lastAnnotation = [[NSDate alloc] init];
		annotationPage = nil;
        
        noteFileAnnotations = [[NSMutableDictionary alloc] init];
        noteFiles = [[NSMutableDictionary alloc] init];
        trajectories = [[NSMutableDictionary alloc] init];
//        for(int i = 0; i < 11; i++)
//        {
//            EthnographerTrajectory *trajectory = [[EthnographerTrajectory alloc] init];
//            [trajectories addObject:trajectory];
//            [trajectory release];
//        }
        
        installedAndSetup = YES;
	}
	
}

#pragma mark Installation


- (BOOL)checkInstallationStatus
{
    return (penClientPath && printingClientPath && projectsDirectory
           && [penClientPath fileExists] && [printingClientPath fileExists] && [projectsDirectory fileExists]);
}

- (IBAction)installEthnographer:(id)sender
{
    [installer release];
    installer = [[EthnographerInstaller alloc] initWithPlugin:self];
    [installer showWindow:self];
}

- (IBAction)updateEthnographer:(id)sender
{
    [installer release];
    installer = [[EthnographerInstaller alloc] initWithPlugin:self];
    installer.update = YES;
    [installer showWindow:self];
}

- (IBAction)installPenlet:(id)sender
{
    BOOL desktopInstalled = [self checkLivescribeDesktop];
    
    if(desktopInstalled)
    {
        [installer release];
        installer = [[EthnographerInstaller alloc] initWithPlugin:self];
        [installer beginPenletInstallation:self];
        [installer showWindow:self];  
    }

}

- (BOOL)checkLivescribeDesktop
{
    NSString *lspath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.livescribe.LivescribeDesktop"];
    
    if(lspath)
    {    
        return YES;
    }
    else
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Livescribe Desktop can't be found."];
        [alert setInformativeText:@"Livescribe Desktop needs to be installed on this computer before the Livescribe pen software can be installed on the pen.\nYou can download the installer from livescribe.com"];
        [alert addButtonWithTitle:@"Cancel Install"];
        [alert addButtonWithTitle:@"Go To Livescribe.com"];
        NSInteger result = [alert runModal];
        if(result == NSAlertSecondButtonReturn)
        {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.livescribe.com/starthere"]];
        }
        
        [alert release];
        return NO;
    }
}


- (IBAction)showDataTransferWindow:(id)sender
{
    BOOL desktopInstalled = [self checkLivescribeDesktop];
    
    if(desktopInstalled)
    {
        [[self printer] showDataTransferWindow:sender];
    }
}

- (IBAction)showEthnographerHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://chronoviz.com/penInstructions.html"]];
}    
      
#pragma mark Project Management

- (NSArray*)projectNames
{
	return projectNames;
}

- (BOOL)hasCurrentProject
{
	return (currentProject != nil);
}

- (EthnographerProject*)currentProject
{
	if(!currentProject)
	{
		NSString *currentProjectName = [[[AppController currentDoc] documentVariables] objectForKey:AFEthnographerDocumentProjectKey];
		if(!currentProjectName)
		{
			[self requestProjectSelection:self];
		}
		else
		{
			self.currentProject = [self projectForName:currentProjectName];
		}
	}
	return currentProject;
}

- (void)setCurrentProject:(EthnographerProject*)project
{
	[project retain];
	[currentProject release];
	currentProject = project;
	
	if(currentProject != nil)
		[[[AppController currentDoc] documentVariables] setObject:[currentProject projectName] forKey:AFEthnographerDocumentProjectKey];
}

- (EthnographerProject*)projectForName:(NSString*)projectName
{
	if([projectNames containsObject:projectName])
	{
		NSString *mappingsFile = [[projectsDirectory stringByAppendingPathComponent:projectName] stringByAppendingPathComponent:@".mappings.xml"];
		if(![mappingsFile fileExists])
		{
			NSLog(@"Error: Mappings file doesn't exist for project %@",projectName);
		}
		else
		{
			EthnographerProject *project = [[[EthnographerProject alloc] initWithMappingsFile:mappingsFile] autorelease];
			return project;
			
		}
	}
	return nil;
}

- (EthnographerProject*)createNewProject:(NSString*)projectName
{
	NSString *projectDirectory = [projectsDirectory stringByAppendingPathComponent:projectName];
	
	if([projectDirectory isDirectory])
	{
		return nil;
	}
	else
	{
		NSError *err = nil;
		BOOL success = [[NSFileManager defaultManager]copyItemAtPath:[self defaultProjectDirectory]
															  toPath:projectDirectory
															   error:&err];
		
		if(!success)
		{
			NSLog(@"Error creating project directory: %@",[err localizedDescription]);
			return nil;
		}
		else
		{
			NSString *mappingsFile = [projectDirectory stringByAppendingPathComponent:@".mappings.xml"];
			EthnographerProject *project = [[[EthnographerProject alloc] initWithMappingsFile:mappingsFile] autorelease];
			return project;
		}
	}
	
	return nil;
	
}

#pragma mark Session Management

- (void)loadSession:(NSString*)sessionFile
{
    [[[AppController currentApp] linkedFilesController] openDataFile:sessionFile asType:[EthnographerDataSource class]];
}

- (void)deleteSession:(NSString*)sessionFile
{
    [[self printer] deleteNoteSession:[sessionFile stringByDeletingLastPathComponent] fromProject:currentProject];
    
    [currentProject reload];
    
    for(NSObject *dataSource in [[AnnotationDocument currentDocument] dataSources])
    {
        if([dataSource isKindOfClass:[EthnographerDataSource class]])
        {
            if([[(EthnographerDataSource*)dataSource dataFile] isEqualToString:sessionFile])
            {
                [[AnnotationDocument currentDocument] removeDataSource:(EthnographerDataSource*)dataSource];
            }
        }
    }
    
}

//TODO: Implement
- (void)moveSession:(NSString*)sessionFile toProject:(EthnographerProject*)project
{
    
}

#pragma mark Controls

- (NSDictionary*)controlFiles
{
    return controlFiles;
}

#pragma mark Anoto Pages

- (void)registerDataSource:(EthnographerDataSource*)source
{
	[bluetoothPen loadPages:[source anotoPages]];
}

- (NSArray*)currentAnotoPages
{
	NSMutableSet *pages = [NSMutableSet set];
	for(DataSource *source in [[AnnotationDocument currentDocument] dataSources])
	{
		if([source isKindOfClass:[EthnographerDataSource class]])
		{
			[pages addObjectsFromArray:[(EthnographerDataSource*)source anotoPages]];
		}
	}
	
	return [pages allObjects];
}

- (DPBluetoothPen*) bluetoothPen
{
	return bluetoothPen;
}

- (EthnographerPrinter*) printer
{
	if(!printer)
	{
		printer = [[EthnographerPrinter alloc] initWithPlugin:self];
	}
	return printer;
}

#pragma mark Paths


- (NSString*)defaultProjectDirectory
{
	return [projectsDirectory stringByAppendingPathComponent:@".default"];
}

#pragma mark Trajectories

- (void)editTrajectories:(id)sender
{
    if(!trajectoriesInspectors)
    {
        trajectoriesInspectors = [[NSMutableArray alloc] init];
    }
    
    EthnographerTrajectory *trajectory = [sender representedObject];
    EthnographerTrajectoryInspectorWindowController *trajectoryInspectory = nil;
    for(EthnographerTrajectoryInspectorWindowController *inspector in trajectoriesInspectors)
    {
        if([inspector trajectory] == trajectory)
        {
            trajectoryInspectory = inspector;
        }
    }
    
    if(!trajectoryInspectory)
    {
        trajectoryInspectory = [[EthnographerTrajectoryInspectorWindowController alloc] initForTrajectory:trajectory];
        [trajectoriesInspectors addObject:trajectoryInspectory];
        [trajectoryInspectory release];
    }
    
    [trajectoryInspectory showWindow:self];
    [[trajectoryInspectory window] makeKeyAndOrderFront:nil];
}

- (void)resetTrajectories
{
    currentTrajectory = nil;
    [trajectories removeAllObjects];
}

- (void)trajectoryWindowClosed:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowWillCloseNotification
                                                  object:[trajectoryView window]];
    trajectoryView = nil;
}

#pragma mark Pen URL Events


- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
	
    NSString *errorMsg = nil;
    
	NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSURL* url = [NSURL URLWithString:urlString];

	NSLog(@"Pen URL: %@",urlString);
	
	NSString *command = [url host];
	
	NSDictionary *params = [[url query] queryDictionaryUsingEncoding:NSUTF8StringEncoding];
	
	if([command isEqualToString:@"note"])
	{
		if([lastAnnotation timeIntervalSinceNow] > -1)
		{
			return;
		}
		
		NSString *error = [params objectForKey:@"error"];
		if(error)
		{
			NSLog(@"%@",error);
			return;
		}
		
		NSString *anotopage = [params objectForKey:@"page"];
		NSString *x = [params objectForKey:@"x"];
		NSString *y = [params objectForKey:@"y"];
		
		if(anotopage && x && y)
		{
			for(NSWindowController *controller in [[AppController currentApp] dataWindowControllers])
			{
				if([controller isKindOfClass:[EthnographerViewController class]])
				{
					EthnographerNotesView *notesView = [(EthnographerViewController*)controller anotoView];
					
					EthnographerDataSource *dataSource = (EthnographerDataSource*)[(AnotoNotesData*)[[notesView dataSets] objectAtIndex:0] source];
										
					NSString *page = [dataSource livescribePageForAnotoPage:anotopage];
					
					if(page && [[notesView pages] containsObject:page])
					{
						[[notesView window] orderFront:self];
						CMTime time = [notesView timeForNotePoint:NSMakePoint([x doubleValue], [y doubleValue]) onPage:page];
						if(!QTTimeIsIndefinite(time))
						{
							[[AppController currentApp] moveToTime:time fromSender:urlString];
						}
                        
                        lastNotesView = notesView;
                        lastDataSource = dataSource;
                        self.lastLivescribePage = page;
                        
						return;
					}
				}
			}
		}
		else 
		{
			NSLog(@"Error: a note URL needs a page and a coordinate pair");
		}
		
		
		NSLog(@"No anoto data loaded for url: %@",urlString);
		return;
		
	}  
	else if([command isEqualToString:@"start_annotation"])
	{
		NSLog(@"start_annotation");
		
		NSString *error = [params objectForKey:@"error"];
		if(error)
		{
			NSLog(@"%@",error);
			return;
		}
		
		NSString *anotopage = [params objectForKey:@"page"];
		NSString *x = [params objectForKey:@"x"];
		NSString *y = [params objectForKey:@"y"];
		
		if(anotopage && x && y)
		{
			for(NSWindowController *controller in [[AppController currentApp] dataWindowControllers])
			{
				if([controller isKindOfClass:[EthnographerViewController class]])
				{
					EthnographerViewController *anotoViewController = (EthnographerViewController*)controller;
					
					EthnographerDataSource *dataSource = (EthnographerDataSource*)[(AnotoNotesData*)[[[anotoViewController anotoView] dataSets] objectAtIndex:0] source];
					NSString *page = [dataSource livescribePageForAnotoPage:anotopage];
					
					if(page && [[[anotoViewController anotoView] pages] containsObject:page])
					{	
						for(AnotoNotesData *data in [[anotoViewController anotoView] dataSets])
						{
							EthnographerDataSource *source = (EthnographerDataSource*)[data source];
							if([[source pages] containsObject:page])
							{
								self.annotationDataSource = source;
								[[AppController currentApp] pause:self];
								annotationViewController = [anotoViewController anotoView];
								annotationStartTime = [[AppController currentApp] currentTime];
								[annotationPage release];
								annotationPage = [page retain];
                                
                                lastNotesView = annotationViewController;
                                lastDataSource = source;
                                self.lastLivescribePage = page;
								return;
							}
						}
					}
				}
			}
			NSLog(@"Error: couldn't find a page for the new note.");
		}
		else 
		{
			NSLog(@"Error: a note URL needs a page and a coordinate pair");
		}
		
		[lastAnnotation release];
		lastAnnotation = [[NSDate alloc] init];
		
		NSLog(@"No anoto data loaded for url: %@",urlString);
		return;
		
		
	}
	else if([command isEqualToString:@"end_annotation"])
	{
		NSLog(@"end_annotation");
		
		NSString *file = [params objectForKey:@"file"];
		
		file = [file stringByReplacingOccurrencesOfString:@"Application%20Support" withString:@"Application Support"];
		
		if(self.annotationDataSource 
		   && annotationViewController 
		   && annotationPage 
		   && [file fileExists] 
		   && ([[file pathExtension] caseInsensitiveCompare:@"xml"] == NSOrderedSame))
		{
			NSLog(@"Annotation Note File: %@",file);
			
			//NSLog(@"annotation file: %@",file);
			//NSString *xoffset = [params objectForKey:@"offsetX"];
			//NSString *yoffset = [params objectForKey:@"offsetY"];
            
			NSArray *traces = [self.annotationDataSource addFileToCurrentSession:file 
                                                                     atTimeRange:QTMakeTimeRange(annotationStartTime, kCMTimeZero)
                                                                          onPage:annotationPage];
            if([noteFiles count] > DP_NOTES_FILE_CACHE_MAX)
            {
                [noteFiles removeAllObjects];
                [noteFileAnnotations removeAllObjects];
            }
            
            if(currentTrajectory && currentTrajectoryControl)
            {
                Annotation* annotation = [[self.annotationDataSource.currentAnnotations annotations] lastObject];
                
//                AnnotationCategory *category = [[AnnotationDocument currentDocument] categoryForName:@"Trajectories"];
//                if(!category)
//                {
//                    category = [[AnnotationDocument currentDocument] createCategoryWithName:@"Trajectories"];
//                }
//                [annotation addCategory:[category valueForName:currentTrajectoryControl]];
                
                [annotation addKeyword:currentTrajectoryControl];
                [annotation addKeyword:[currentTrajectory trajectoryName]];
                
                [noteFileAnnotations setObject:annotation forKey:[file lastPathComponent]];
            }
            
            [noteFiles setObject:traces forKey:file];
			
			if([[annotationViewController dataSets] containsObject:[self.annotationDataSource currentSession]])
			{
				[annotationViewController updateData:[self.annotationDataSource currentSession]];
			}
			else
			{
				[annotationViewController addData:[self.annotationDataSource currentSession]];
			}
			
			[lastAnnotation release];
			lastAnnotation = [[NSDate alloc] init];
			
            if(![[NSUserDefaults standardUserDefaults] boolForKey:AFEthnographerKeepTempAnnotationFiles])
            {
                NSError *err = nil;
                [[NSFileManager defaultManager] removeItemAtPath:file error:&err];
                if(err)
                {
                    NSLog(@"Error deleting temp annotation file: %@",[err localizedDescription]);
                }
            }
			
			self.annotationDataSource = nil;
			annotationViewController = nil;
			
		}
        else
        {

            
            if(!annotationDataSource)
            {
                errorMsg = @"Can't find the digital version of the notes page.";
            }
            else if (!annotationViewController)
            {
                errorMsg = @"The notes are note visible on screen.";
            }
            else if (!annotationPage)
            {
                errorMsg = @"A start annotation message was never received.";
            }
            else if (![file fileExists])
            {
                errorMsg = @"The temporary annotation file does not exist.";
            }
            
        }
		
	}
    else if([command isEqualToString:@"trajectory"])
	{
		NSLog(@"trajectory");
		
		NSString *type = [params objectForKey:@"type"];
		
        if([type caseInsensitiveCompare:@"control"] == NSOrderedSame)
        {
            NSString *name = [params objectForKey:@"name"];
            
            if([name caseInsensitiveCompare:@"path"] == NSOrderedSame)
            {
                name = [name stringByAppendingFormat:@"-%@",[params objectForKey:@"direction"]];
            }
            
            [currentTrajectoryControl release];
            currentTrajectoryControl = [name retain];
        }
        else if([type caseInsensitiveCompare:@"id"] == NSOrderedSame)
        {
            if(!lastDataSource)
            {
                errorMsg = @"Please specify the page you'll be using for the trajectory by making a mark anywhere on the page, then tap the ID button again.";
            }
            else
            {
            
                NSString *name = [params objectForKey:@"name"];
                if(name)
                {
                    //int index = [name intValue];
                    //if((index > 0) && (index < [trajectories count]))
                    //{
                    //currentTrajectory = [trajectories objectAtIndex:index];
                    
                    currentTrajectory = [trajectories objectForKey:name];
                    if(!currentTrajectory)
                    {
                        EthnographerTrajectory *trajectory = [[EthnographerTrajectory alloc] init];
                        [trajectories setObject:trajectory forKey:name];
                        [trajectory release];
                        currentTrajectory = trajectory;
                        
                        DPSpatialDataBase *spatialBase = [[DPSpatialDataImageBase alloc] initWithBackgroundFile:[[lastDataSource backgroundTemplate] background]];
                        [[trajectory trajectory] setSpatialBase:spatialBase];
                        [spatialBase release];
                        
                        if(!trajectoriesMenuItem)
                        {
                            trajectoriesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit Trajectories…"
                                                                              action:@selector(editTrajectories:)
                                                                       keyEquivalent:@""];
                            [trajectoriesMenuItem setTarget:self];
                            
                            
                            NSMenu* trajectoriesMenu = [[NSMenu alloc] initWithTitle:@"Trajectories Menu"];
                            [trajectoriesMenuItem setSubmenu:trajectoriesMenu];
                            [trajectoriesMenu release];
                            
                            [theApp addMenuItem:trajectoriesMenuItem toMenuNamed:@"File"];
                        }
                        
                        NSMenuItem *menuItem = [[trajectoriesMenuItem submenu] addItemWithTitle:[NSString stringWithFormat:@"Trajectory %@",name]
                                                                  action:@selector(editTrajectories:)
                                                           keyEquivalent:@""];
                        [menuItem setRepresentedObject:trajectory];
                        [menuItem setTarget:self];
                    }
                
                    if(![[lastDataSource dataSets] containsObject:currentTrajectory.trajectory])
                    {
                        [currentTrajectory.trajectory setName:[NSString stringWithFormat:@"Trajectory %@",name]];
                        [currentTrajectory.trajectory setColor:nil];
                        [currentTrajectory.trajectory setAnnotationSession:[lastDataSource currentSession]];
                        [currentTrajectory setTrajectoryName:currentTrajectory.trajectory.name];
                        [lastDataSource addDataSet:currentTrajectory.trajectory];
                        [[AppController currentApp] updateViewMenu];
                    }
                    
                    if(!trajectoryView)
                    {

                        // Create a view for the trajectory data.
                        [[[AppController currentApp] viewManager] showData:currentTrajectory.trajectory];
                        
                        NSArray *views = [[[AppController currentApp] viewManager] viewsForData:currentTrajectory.trajectory];
                        for(NSObject<AnnotationView>* view in views)
                        {
                            if([view isKindOfClass:[DPSpatialDataView class]])
                            {
                                trajectoryView = (DPSpatialDataView*)view;
                                
                                [[NSNotificationCenter defaultCenter] addObserver:self
                                                                         selector:@selector(trajectoryWindowClosed:)
                                                                             name:NSWindowWillCloseNotification
                                                                           object:[trajectoryView window]];
                                
                                // Update coordinates to match digital notes coordinates
                                DPSpatialDataBase *spatialBase = [trajectoryView spatialBase];
                                CGRect coordinateSpace = spatialBase.coordinateSpace;
                                coordinateSpace.size.width = coordinateSpace.size.width/lastNotesView.scaleConversionFactor;
                                coordinateSpace.size.height = coordinateSpace.size.height/lastNotesView.scaleConversionFactor;
                                [spatialBase setCoordinateSpace:coordinateSpace];
                                [currentTrajectory.trajectory.spatialBase setCoordinateSpace:coordinateSpace];
                                
                                
                                int rotationLevel = [lastNotesView currentRotation];
                                if(rotationLevel == DPRotation90)
                                {
                                    rotationLevel = DPRotation270;
                                }
                                else if (rotationLevel == DPRotation270)
                                {
                                    rotationLevel = DPRotation90;
                                }
                                [trajectoryView setRotation:rotationLevel];
                                [trajectoryView setStaticPaths:YES];
                                [trajectoryView setBlurPaths:NO];
                                [trajectoryView setConnectedPaths:YES];
                            }
                        }
                    }
                    else
                    {
                        [trajectoryView addData:currentTrajectory.trajectory];
                    }
                        
                    //}
                }
            }
        }
        else if([type caseInsensitiveCompare:@"path"] == NSOrderedSame)
        {
            if(!currentTrajectory)
            {
                errorMsg = @"Please select a trajectory before making a path";
            }
            else 
            {
                NSString *form = [params objectForKey:@"form"];
                NSString *direction = [params objectForKey:@"direction"];
                if(!direction)
                {
                    direction = @"fw";
                }
                
                if([form caseInsensitiveCompare:@"curve"] == NSOrderedSame)
                {
                    NSString *file = [params objectForKey:@"file"];
                    if(file)
                    {
                        NSArray *traces = [noteFiles objectForKey:file];
                        
                        if([traces count] > 1)
                        {
                            NSMutableArray *points = [[NSMutableArray alloc] init];
                            for(AnotoTrace *trace in traces)
                            {
                                [points addObjectsFromArray:[trace dataPoints]];
                            }
                            AnotoTrace *combinedtrace = [[AnotoTrace alloc] initWithDataPointArray:points];
                            [currentTrajectory addPathStroke:combinedtrace];
                            [combinedtrace release];
                            [points release];
                        }
                        else 
                        {
                            [currentTrajectory addPathStroke:(AnotoTrace*)[traces lastObject]];
                        }
                        
                        
                        //[[currentTrajectory trajectory] setColor:[[lastDataSource currentSession] color]];
                    }
                    else
                    {
                        errorMsg = @"Note file missing from trajectory 'curve' URL";
                    }
                }
                else if ([form caseInsensitiveCompare:@"line"] == NSOrderedSame)
                {
                    NSString *startX = [params objectForKey:@"startX"];
                    NSString *startY = [params objectForKey:@"startY"];
                    NSString *endX = [params objectForKey:@"endX"];
                    NSString *endY = [params objectForKey:@"endY"];
                    
                    if(startX && startY && endX && endY)
                    {
                        DPPathSegment *line = [[DPPathSegment alloc] init];
                        [line setStart:NSMakePoint([startX doubleValue], [startY doubleValue])];
                        [line setEnd:NSMakePoint([endX doubleValue], [endY doubleValue])];
                        if([direction caseInsensitiveCompare:@"fw"] != NSOrderedSame)
                        {
                            [line setReversed:YES];
                        }
                        [currentTrajectory addPathSegment:line];
                        //[[currentTrajectory trajectory] setColor:[[lastDataSource currentSession] color]];
                        [line release];
                    }
                    else
                    {
                        errorMsg = @"Missing parameter in trajectory 'line' URL";
                    }
                    
                }
            }
        }
        else if([type caseInsensitiveCompare:@"timemarker"] == NSOrderedSame)
        {
            if(!currentTrajectory)
            {
                errorMsg = @"Please select a trajectory before making a time marker";
            }
            else 
            {
                NSString *startX = [params objectForKey:@"startX"];
                NSString *startY = [params objectForKey:@"startY"];
                NSString *endX = [params objectForKey:@"endX"];
                NSString *endY = [params objectForKey:@"endY"];
                
                NSString *uuid = [params objectForKey:@"uuid"];
                
                if(startX && startY && endX && endY)
                {
                    DPPathSegment *line = [[DPPathSegment alloc] init];
                    [line setStart:NSMakePoint([startX doubleValue], [startY doubleValue])];
                    [line setEnd:NSMakePoint([endX doubleValue], [endY doubleValue])];
                    [currentTrajectory addTimeMarker:line atTime:[[AppController currentApp] currentTime] withId:uuid];
                    [line release];
                    
//                    NSArray *views = [[[AppController currentApp] viewManager] viewsForData:currentTrajectory.trajectory];
//                    for(id<AnnotationView> view in views)
//                    {
//                        [view removeData:currentTrajectory.trajectory];
//                        [view addData:currentTrajectory.trajectory];
//                        [view update];
//                    }
                }
                else
                {
                    errorMsg = @"Missing parameter in trajectory 'timemarker' URL";
                }
                
            }
        }
        else if([type caseInsensitiveCompare:@"orientation"] == NSOrderedSame)
        {
            //chronoviz://trajectory?type=orientation&uuid=...&startX=...&startY=...&angle=...&file=...
            
            if(!currentTrajectory)
            {
                errorMsg = @"Please select a trajectory before making an orientation mark";
            }
            else 
            {
                NSString *startX = [params objectForKey:@"startX"];
                NSString *startY = [params objectForKey:@"startY"];
                NSString *endX = [params objectForKey:@"endX"];
                NSString *endY = [params objectForKey:@"endY"];
                
                NSString *angle = [params objectForKey:@"angle"];
                NSString *uuid = [params objectForKey:@"uuid"];
                
                NSString *file = [[params objectForKey:@"file"] lastPathComponent];
                
                if(startX && startY && endX && endY && angle && uuid)
                {
                    [currentTrajectory addOrientation:[angle floatValue]
                                              atTime:[[AppController currentApp] currentTime]
                                              withId:uuid];
                    
//                    NSArray *views = [[[AppController currentApp] viewManager] viewsForData:currentTrajectory.trajectory];
//                    for(id<AnnotationView> view in views)
//                    {
//                        [view removeData:currentTrajectory.trajectory];
//                        [view addData:currentTrajectory.trajectory];
//                        [view update];
//                    }
                    
                    //Annotation* annotation = [[self.annotationDataSource.currentAnnotations annotations] lastObject];
                    Annotation *annotation = [noteFileAnnotations objectForKey:file];
                    NSString *currentAnnotation = [annotation annotation];
                    if(currentAnnotation)
                    {
                        [annotation setAnnotation:[[annotation annotation] stringByAppendingFormat:@"\nOrientation:%f",[angle floatValue]]];
                    }
                    else
                    {
                        [annotation setAnnotation:[NSString stringWithFormat:@"\nOrientation:%f",[angle floatValue]]];
                    }
                }
                else
                {
                    errorMsg = @"Missing parameter in trajectory 'orientation' URL";
                }
                
            }
        }
        else if([type caseInsensitiveCompare:@"pivot"] == NSOrderedSame)
        {
            //chronoviz://trajectory?type=pivot&uuid=...&sourceuuid=...&targetuuid=...&direction=...&file=...
            
            if(!currentTrajectory)
            {
                errorMsg = @"Please select a trajectory before making a pivot mark";
            }
            else 
            {
                
                NSString *sourceuuid = [params objectForKey:@"sourceuuid"];
                NSString *targetuuid = [params objectForKey:@"targetuuid"];
                NSString *direction = [params objectForKey:@"direction"];
                NSString *uuid = [params objectForKey:@"uuid"];
                
                if(sourceuuid && targetuuid && direction && uuid)
                {
                    BOOL clockwise = NO;
                    if([direction caseInsensitiveCompare:@"cw"] == NSOrderedSame)
                    {
                        clockwise = YES;
                    }
                    
                    [currentTrajectory addPivotFromSource:sourceuuid 
                                                 toTarget:targetuuid 
                                                clockwise:clockwise 
                                           startingAtTime:[[AppController currentApp] currentTime] 
                                                   withId:uuid];
                    
//                    NSArray *views = [[[AppController currentApp] viewManager] viewsForData:currentTrajectory.trajectory];
//                    for(id<AnnotationView> view in views)
//                    {
//                        [view removeData:currentTrajectory.trajectory];
//                        [view addData:currentTrajectory.trajectory];
//                        [view update];
//                    }
                }
                else
                {
                    errorMsg = @"Missing parameter in trajectory 'pivot' URL";
                }
                
            }
        }
				
	}
	else if([command isEqualToString:@"penbrowser"] || [command isEqualToString:@"changestatus"])
	{
		//NSLog(@"%@",urlString);
		
		NSString *status = [params objectForKey:@"status"];
		
		if([status isEqualToString:@"starting"])
		{
			[[DPBluetoothPen penClient] penBrowserStarting:self];
		}
		else if([status isEqualToString:@"ready"])
		{
			[[DPBluetoothPen penClient] penBrowserStarted:self];
		}
		else if([status isEqualToString:@"connected"])
		{
			[[DPBluetoothPen penClient] penBrowserConnected:self];
            
            if(!lastNotesView)
            {
                for(NSWindowController *controller in [[AppController currentApp] dataWindowControllers])
                {
                    if([controller isKindOfClass:[EthnographerViewController class]])
                    {
                        lastNotesView = [(EthnographerViewController*)controller anotoView];
                        
                        lastDataSource = (EthnographerDataSource*)[(AnotoNotesData*)[[lastNotesView dataSets] objectAtIndex:0] source];
                    }
                }
            }
            
		}
        else if([status caseInsensitiveCompare:@"trajectory"] == NSOrderedSame)
        {
            // Nothing is done here currently.
            // "Trajectory Mode" is maintained by the PenBrowser
        }
        else if([status caseInsensitiveCompare:@"annotation"]== NSOrderedSame)
        {
            currentTrajectory = nil;
        }
        else if([status caseInsensitiveCompare:@"error"] == NSOrderedSame)
		{
			errorMsg = [params objectForKey:@"message"];
		}
		
	} 
	else if([command isEqualToString:@"anotoprinter"])
	{
		//NSLog(@"%@",urlString);
		
		NSString *status = [params objectForKey:@"status"];
		
		//	chronoviz://anotoprinter?status=sessioncreated&session=/Users/afouse/Dropbox/Projects/Boeing/tempannotation_Aug_27_2011_5:51:48_PM/tempannotation_session.xml
		
		if([status isEqualToString:@"printed"])
		{
			NSString *postscript = [params objectForKey:@"postscript"];
			if(postscript)
			{
				[[self printer] setCurrentPrintFile:postscript];
			}
			
		}
		else if([status isEqualToString:@"printing"])
		{
			NSString *message = [params objectForKey:@"message"];
			CGFloat percent = [[params objectForKey:@"progress"] doubleValue];
			if(message)
			{
				[[self printer] updatePrintStatus:message percent:percent];
			}
		}
		else if([status isEqualToString:@"sessioncreated"])
		{
			NSString *sessionfile = [params objectForKey:@"session"];
			if(sessionfile)
			{
				[currentProject reload];
				EthnographerDataSource *blankNotes = [[EthnographerDataSource alloc] initWithPath:sessionfile];
				[[AppController currentDoc] addDataSource:blankNotes];
				[blankNotes dataArray];
				[[[AppController currentApp] viewManager] showData:[blankNotes currentSession]];
				[[AppController currentApp] updateViewMenu];
				[blankNotes release];
				
				if([[templatesController window] isVisible])
				{
					[[templatesController window] makeKeyAndOrderFront:self];
				}
			}
		}
        else if([status isEqualToString:@"sessionimported"])
		{
            if(![self hasCurrentProject])
            {
                NSString *projects = [params objectForKey:@"projects"];
                NSString *projectName = [[projects componentsSeparatedByString:@","] objectAtIndex:0];
                if([projectName length] > 0)
                {
                    EthnographerProject *importedProject = [self projectForName:projectName];
                    [self setCurrentProject:importedProject];
                }
            }
            
            [[self currentProject] reload];
            
            [self showTemplatesWindow:self];
            [templatesController selectSessionsPane:self];
		}
        else if([status isEqualToString:@"pdfgenerated"])
        {
            [templatesController reloadPreview];
        }
		else if([status isEqualToString:@"error"])
		{
			NSString *message = [params objectForKey:@"message"];
			if(message)
			{
				[[self printer] setCurrentPrintError:message];
			}
		}
		
	} 
	
    if(errorMsg)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"There was an error processing the digital pen annotation:"];
        [alert setInformativeText:errorMsg];
        [alert runModal];
        [alert release];
    }
    
}

#pragma mark Project Management UI
- (IBAction)showTemplatesWindow:(id)sender
{
	EthnographerProject *proj = [self currentProject];
	
	if(!proj)
	{
		return;
	}
	
	if(!templatesController)
	{
		templatesController = [[EthnographerTemplateManagementController alloc] init];
		templatesController.plugin = self;
		templatesController.currentProject = proj;
	}
	
	[templatesController showWindow:self];
	[[templatesController window] center];
	[[templatesController window] makeKeyAndOrderFront:self];
}

- (IBAction)requestProjectSelection:(id)sender
{
	if (!projectSelectionWindow)
        [NSBundle loadNibNamed: @"EthnographerRequestProjectWindow" owner: self];
	
	[projectTable reloadData];
	
	//    [NSApp beginSheet: projectSelectionWindow
	//	   modalForWindow: [[AppController currentApp] window]
	//		modalDelegate: nil
	//	   didEndSelector: nil
	//		  contextInfo: nil];
    [NSApp runModalForWindow: projectSelectionWindow];
    // Dialog is up here.
	[projectSelectionWindow close];
	//    [NSApp endSheet: projectSelectionWindow];
	//    [projectSelectionWindow orderOut: self];
	
}

- (IBAction)cancelProjectSelection:(id)sender
{
	[NSApp stopModal];
}

- (void)requestNewProjectNameInWindow:(NSWindow*)theWindow withCallback:(SEL)callbackSel andTarget:(id)target
{
	NSAlert* alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Please enter a name for the new project."];
	[alert addButtonWithTitle:@"Create Project"];
	[alert addButtonWithTitle:@"Cancel"];
	
	NSTextField *nameInputField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 22)];
	[nameInputField setStringValue:@"New Project"];
	[alert setAccessoryView:nameInputField];
	
	NSDictionary *context = nil;
	if(target && (callbackSel != NULL))
	{
		context = [[NSDictionary alloc] initWithObjectsAndKeys:
				   nameInputField,@"nameInputField",
				   target,@"target",
				   [NSValue valueWithPointer:callbackSel], @"callback",
				   nil];
	}
	else
	{
		context = [[NSDictionary alloc] initWithObjectsAndKeys:
				   nameInputField,@"nameInputField",
				   nil];
	}
	[nameInputField release];
	
	[alert beginSheetModalForWindow:theWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:context];
	[nameInputField selectText:self];		
}

- (IBAction)requestNewProjectName:(id)sender
{
	if([sender respondsToSelector:@selector(window)])
	{
		if([sender window] == projectSelectionWindow)
		{
			[self requestNewProjectNameInWindow:projectSelectionWindow
								   withCallback:@selector(cancelProjectSelection:)
									  andTarget:self];
		}
		else
		{
			[self requestNewProjectNameInWindow:projectSelectionWindow
								   withCallback:NULL
									  andTarget:nil];
		}
	}
}

-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSDictionary *contextDict = (NSDictionary*)contextInfo;
	
	if (returnCode == NSAlertFirstButtonReturn) {
		
		NSTextField *nameInputField = [contextDict objectForKey:@"nameInputField"];
		NSString *newProjectName = [nameInputField stringValue];
		
		if(![projectNames containsObject:newProjectName])
		{
			self.currentProject = [self createNewProject:newProjectName];
			[projectNames addObject:newProjectName];
		}
		else
		{
			self.currentProject = [self projectForName:newProjectName];
		}
		
		id callbackTarget = [contextDict objectForKey:@"target"];
		id callbackSelectorObj = [contextDict objectForKey:@"callback"];
		
		if(callbackTarget && callbackSelectorObj)
		{
			SEL callback = [callbackSelectorObj pointerValue];
			
			[callbackTarget performSelector:callback withObject:self];
		}
	}
	
	[contextDict release];
	[alert release];
}

#pragma mark Table View Delegate Methods
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
	return [projectNames count];
}

- (id) tableView:(NSTableView*) aTableView objectValueForTableColumn:(NSTableColumn*) tableColumn row:(NSInteger) rowIndex {
	
	if(rowIndex < [projectNames count])
	{
		return [projectNames objectAtIndex:rowIndex];
	}
	else
	{
		return @"";
	}
	
}

- (BOOL) tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{	
	[NSApp stopModal];
	NSString *projectName = [projectNames objectAtIndex:[(NSTableView*)[aNotification object] selectedRow]];
	[[[AppController currentDoc] documentVariables] setObject:projectName forKey:AFEthnographerDocumentProjectKey];
	self.currentProject = [self projectForName:projectName];
}

						   
@end
