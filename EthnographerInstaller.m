//
//  EthnographerInstaller.m
//  ChronoViz
//
//  Created by Adam Fouse on 12/7/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "EthnographerInstaller.h"
#import "EthnographerPlugin.h"
#import "DPComponentInstaller.h"
#import "NSStringFileManagement.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "NSString+DropboxPath.h"

@interface EthnographerInstaller (Internal)

- (BOOL)isConnectionAvailable;
- (void)downloadFinished;
- (BOOL)unzipFile:(NSString*)zipFile;
- (NSString*)dropboxDirectory;
- (NSString*)checkForExistingProjectsDirectory;
- (void)updatePossibleProjectLocations;
- (BOOL)isValidProjectsFolder:(NSString*)filepath;
- (void)createProjectsDirectory;

- (void)setCurrentView:(NSView*)nextView animate:(BOOL)shouldAnimate;

- (NSArray*)connectedPens;
- (void)installPenlet:(NSString*)penlet ToPen:(NSNumber*)penID;

@end

NSString * const ethnographerInstructionsURL = @"http://chronoviz.com/penInstructions.html";

@implementation EthnographerInstaller

@synthesize existingProjectsView;
@synthesize instructionsView;
@synthesize projectsSetupView;
@synthesize projectsOptionsButtons;
@synthesize nextButton;
@synthesize cancelButton;
@synthesize instructionsWebView;
@synthesize existingFolderLocationField;
@synthesize emailSignupField;
@synthesize dropboxLocationLabel;
@synthesize documentsLocationLabel;
@synthesize updateView;
@synthesize updateCompleteView;
@synthesize update;
@synthesize completeView;
@synthesize penletInstallView;
@synthesize defaultDropboxLocation;
@synthesize defaultDocumentsLocation;
@synthesize selectedProjectsFolder;
@synthesize existingProjectsFolder;

- (id)initWithPlugin:(EthnographerPlugin*)ethnoPlugin;
{
    self = 	[super initWithWindowNibName:@"EthnographerInstallerWindow"];
    if (self) {
        plugin = [ethnoPlugin retain];
        installer = nil;
        
        defaultProjectsFolderName = @"ChronoViz Digital Pen Projects";
        
        update = NO;
        self.existingProjectsFolder = nil;
        self.selectedProjectsFolder = nil;
    }
    
    return self;
}

- (void)dealloc {
    self.existingProjectsFolder = nil;
    self.selectedProjectsFolder = nil;
    self.defaultDropboxLocation = nil;
    self.defaultDocumentsLocation = nil;
    [dropboxDirectory release];
    [plugin release];
    [installer release];
    [super dealloc];
}

- (void)updatePossibleProjectLocations
{
    NSString *dropbox = [self dropboxDirectory];
    if(dropbox)
    {
        [[projectsOptionsButtons cellAtRow:0 column:0] setEnabled:YES];
        self.defaultDropboxLocation = [[self dropboxDirectory] stringByAppendingPathComponent:defaultProjectsFolderName]; 
        [dropboxLocationLabel setStringValue:[NSString stringWithFormat:@"(%@)",self.defaultDropboxLocation]];
    }
    else
    {
        [[projectsOptionsButtons cellAtRow:0 column:0] setEnabled:NO];
        self.defaultDropboxLocation = nil;
        [dropboxLocationLabel setStringValue:@"(Dropbox not installed)"];
    }
    
    self.defaultDocumentsLocation = [[@"~/Documents" stringByAppendingPathComponent:defaultProjectsFolderName] stringByExpandingTildeInPath];
    [documentsLocationLabel setStringValue:[NSString stringWithFormat:@"(%@)",self.defaultDocumentsLocation]];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSView *contentView = [[self window] contentView];
    
    if(self.update)
    {
        [self setCurrentView:[self updateView] animate:NO];
    }
    else
    {
        [self setCurrentView:[self instructionsView] animate:NO];
    }
    
    
    transition = [CATransition animation];
    [transition setType:kCATransitionPush];
    [transition setSubtype:kCATransitionFromRight];
    
    NSDictionary *ani = [NSDictionary dictionaryWithObject:transition forKey:@"subviews"];
    [contentView setAnimations:ani];
    
    if([self isConnectionAvailable])
    {
        if(!self.update)
        {
            [instructionsWebView setMaintainsBackForwardList:NO];
            [instructionsWebView setMainFrameURL:ethnographerInstructionsURL];
            [instructionsWebView setPolicyDelegate:self];
        }
    }
    else
    {
        NSString *informativeText;
        if(self.update)
        {
            informativeText = @"An update needs to be downloaded from chronoviz.com for the digital pen components to work with this version of ChronoViz. Please make sure that you are connected to the internet and try again."; 
        }
        else
        {
            informativeText = @"Installing the digital pen components requires downloading additional software from chronoviz.com. Please make sure that you are connected to the internet and try again.";
        }
        NSAlert *noConnectionAlert = [[NSAlert alloc] init];
        [noConnectionAlert setMessageText:@"The ChronoViz website could not be reached"];
        [noConnectionAlert setInformativeText:informativeText];
        [noConnectionAlert beginSheetModalForWindow:[self window]
                                      modalDelegate:self
                                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                        contextInfo:NULL];
    }
    
}

- (void)setCurrentView:(NSView*)nextView animate:(BOOL)shouldAnimate
{
    NSSize size = [nextView frame].size;
    size.height = size.height + 22;
    NSRect currentFrame = [[self window] frame];
    CGFloat diff = currentFrame.size.height - size.height;
    currentFrame.size = size;
    currentFrame.origin.y = currentFrame.origin.y + diff;
    [[self window] setFrame:currentFrame display:YES animate:shouldAnimate];
    
    if(nextView == instructionsView)
    {
        [[self window] setStyleMask:([[self window] styleMask] | NSResizableWindowMask)];
    }
    else
    {
        [[self window] setStyleMask:([[self window] styleMask] & ~NSResizableWindowMask)];
    }
    
    if(!currentView)
    {
        NSView *contentView = [[self window] contentView];
        [contentView setWantsLayer:YES];
        [contentView addSubview:nextView];
        currentView = nextView;
    }
    else
    {
    
        NSView *contentView = [[self window] contentView];
        
        NSView *previousView = currentView;
        currentView = nextView;
        
        if(shouldAnimate)
        {
            [[contentView animator] replaceSubview:previousView 
                                              with:nextView];   
        }
        else
        {
            [contentView replaceSubview:previousView
                                   with:nextView];
        }
    }
    
    
    
}

-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [self cancel:self];
    [alert release];
}

- (IBAction)cancel:(id)sender {
    [self close];
}

- (IBAction)startDownload:(id)sender {
    
    if([[emailSignupField stringValue] length] > 1)
    {
        NSURL *signupURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://chronoviz.com/recordpenemail.php?email=%@",[[emailSignupField stringValue] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        
        NSLog(@"Sending request: %@",[signupURL absoluteString]);
        
        NSStringEncoding usedEnc = NSUTF8StringEncoding;
        NSError *err = nil;
        NSString *result = [NSString stringWithContentsOfURL:signupURL 
                             usedEncoding:&usedEnc
                                    error:&err];
        NSLog(@"Result: %@",result);
    }
    
    NSString *clientURL = [[NSString alloc] initWithFormat:@"http://chronoviz.com/penbrowser/PenBrowser_%@.zip",DPBluetoothPenRequiredVersion];
    NSString *printingURL = [[NSString alloc] initWithFormat:@"http://chronoviz.com/anotoprinter/PenPrinting_%@.zip",DPBluetoothPenRequiredVersion];
    
    installer = [[DPComponentInstaller alloc] init];
    [installer setBaseWindow:[self window]];
    
    NSArray *remoteFiles = [NSArray arrayWithObjects:clientURL,printingURL,nil];
    NSArray *localFiles = [NSArray arrayWithObjects:plugin.penClientPath,plugin.penPrintingPath,nil];
    NSArray *descriptions = [NSArray arrayWithObjects:@"Bluetooth Connection Components",@"Printing Components",nil];
    
    [installer setRemoteFiles:remoteFiles
                   localFiles:localFiles
                 descriptions:descriptions];
    
    [installer setCallback:@selector(downloadFinished)
                 andTarget:self];
    
    [installer startDownload];
}

- (void)downloadFinished
{
    if(update)
    {
        [self setCurrentView:[self updateCompleteView] animate:YES];
    }
    else
    {
        
        self.existingProjectsFolder = [self checkForExistingProjectsDirectory];
        
        NSView *nextView = nil;
        
        if(self.existingProjectsFolder)
        {
            nextView = existingProjectsView;
            [existingFolderLocationField setStringValue:self.existingProjectsFolder];
        }
        else
        {
            [self updatePossibleProjectLocations];
            nextView = projectsSetupView;
            if(self.defaultDropboxLocation)
            {
                [projectsOptionsButtons selectCellAtRow:0 column:0];
            }
            else
            {
                [projectsOptionsButtons selectCellAtRow:1 column:0];
            }
            [self changeSelectedProjectsFolder:self];

        }
        
        [self setCurrentView:nextView animate:YES];
    }
}

- (IBAction)selectProjectsLocation:(id)sender
{
    [projectsOptionsButtons selectCellAtRow:0 column:0];
    [self changeSelectedProjectsFolder:self];
    [self setCurrentView:projectsSetupView animate:NO];
}

- (IBAction)createFolder:(id)sender 
{
    if(!self.selectedProjectsFolder)
    {
        NSOpenPanel *newFolderPanel = [[NSOpenPanel alloc] init];
        [newFolderPanel setMessage:@"Select a location where the “ChronoViz Digital Pen Projects” folder will be created"];
        [newFolderPanel setCanChooseFiles:NO];
        [newFolderPanel setCanChooseDirectories:YES];
        [newFolderPanel setCanCreateDirectories:YES];
        
        [newFolderPanel beginSheetForDirectory:nil
                                          file:nil
                                modalForWindow:[self window]
                                 modalDelegate:self
                                didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                                   contextInfo:NULL];
    }
    else
    {
        [self createProjectsDirectory];
    }
}

- (IBAction)selectExistingFolder:(id)sender {
    NSOpenPanel *newFolderPanel = [[NSOpenPanel alloc] init];
    [newFolderPanel setMessage:@"Select an existing ChronoViz Digital Pen Projects folder."];
    [newFolderPanel setCanChooseFiles:NO];
    [newFolderPanel setCanChooseDirectories:YES];
    [newFolderPanel setCanCreateDirectories:YES];
    
    [newFolderPanel beginSheetForDirectory:nil
                                      file:nil
                            modalForWindow:[self window]
                             modalDelegate:self
                            didEndSelector:@selector(selectExistingPanelDidEnd:returnCode:contextInfo:)
                               contextInfo:NULL];
    
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
    if(returnCode == NSOKButton)
    {
        self.selectedProjectsFolder = [[[panel URL] path] stringByAppendingPathComponent:defaultProjectsFolderName];
        [NSApp endSheet:panel];
        [panel orderOut:self];
        [self createProjectsDirectory];
    }
    else
    {
        [self cancel:self];
    }
    
    [panel release];
}

- (void)selectExistingPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
    if(returnCode == NSOKButton)
    {
        NSString *selectedPath = [[panel URL] path];
        if([self isValidProjectsFolder:selectedPath])
        {
            self.existingProjectsFolder = selectedPath;
            [existingFolderLocationField setStringValue:self.existingProjectsFolder];
            [self setCurrentView:existingProjectsView animate:YES];
        }
        else
        {
            [NSApp endSheet:panel];
            [panel orderOut:self];
            NSAlert *projectCreationAlert = [[NSAlert alloc] init];
            [projectCreationAlert setMessageText:@"The folder you selected was not a valid ChronoViz projects folder."];
            [projectCreationAlert setInformativeText:@"Please choose another folder or choose one of the other options."];
            [projectCreationAlert beginSheetModalForWindow:[self window]
                                             modalDelegate:nil
                                            didEndSelector:NULL 
                                               contextInfo:NULL];
        }
    }
    
    [panel release];
}

- (IBAction)useExistingFolder:(id)sender 
{
    self.selectedProjectsFolder = self.existingProjectsFolder;
    [self createProjectsDirectory];
}

- (IBAction)beginPenletInstallation:(id)sender
{
    if(![[self window] isVisible])
    {
        [[self window] makeKeyAndOrderFront:self];
    }
    [self setCurrentView:penletInstallView animate:(currentView == completeView)];
}

- (IBAction)confirmPenletInstallation:(id)sender
{
    BOOL livescribeInstalled = [plugin checkLivescribeDesktop];
    
    if(!livescribeInstalled)
    {
        return;
    }
    
    NSWindow *progressWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(200,400,480,120)
                                                           styleMask:NSTitledWindowMask
                                                             backing:NSBackingStoreBuffered
                                                               defer:NO];
    
    NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(18, 56, 444, 20)];
    
    NSTextField *progressTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(17, 84, 444, 17)];
    [progressTextField setStringValue:@"Detecting pens…"];
    [progressTextField setEditable:NO];
    [progressTextField setDrawsBackground:NO];
    [progressTextField setBordered:NO];
    [progressTextField setAlignment:NSLeftTextAlignment];
    
    [[progressWindow contentView] addSubview:progressIndicator];
    [[progressWindow contentView] addSubview:progressTextField];
    
    [progressIndicator setIndeterminate:YES];
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator startAnimation:self];
    
    [NSApp beginSheet:progressWindow
       modalForWindow:[self window]
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:nil];
    
    NSArray *connectedPens = [self connectedPens];
    
    [NSApp endSheet:progressWindow];
    [progressWindow orderOut:self];
    
    [progressIndicator release];
    [progressTextField release];
    [progressWindow release];

    
    
    NSString *alertMessage = nil;
    if([connectedPens count] == 0)
    {
        alertMessage = @"There are no pens connected to this computer. Please connect a pen and try again.";
    }
    else if ([connectedPens count] > 1)
    {
        alertMessage = @"There is more than one pen connected to this computer. Please make sure that only one pen is connected and try again.";
    }
    
    if(alertMessage)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:alertMessage];
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:nil
                         didEndSelector:NULL 
                            contextInfo:NULL];
    }
    else
    {

        NSWindow *progressWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(200,400,480,120)
                                                     styleMask:NSTitledWindowMask
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO];
        
        NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(18, 56, 444, 20)];
        
        NSTextField *progressTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(17, 84, 444, 17)];
        [progressTextField setStringValue:@"Installing Penlet…"];
        [progressTextField setEditable:NO];
        [progressTextField setDrawsBackground:NO];
        [progressTextField setBordered:NO];
        [progressTextField setAlignment:NSLeftTextAlignment];
        
        [[progressWindow contentView] addSubview:progressIndicator];
        [[progressWindow contentView] addSubview:progressTextField];
        
        [progressIndicator setIndeterminate:YES];
        [progressIndicator setUsesThreadedAnimation:YES];
        [progressIndicator startAnimation:self];
        
        [NSApp beginSheet:progressWindow
           modalForWindow:[self window]
            modalDelegate:nil
           didEndSelector:NULL
              contextInfo:nil];
        
        [self installPenlet:[plugin ethnographerPenletPath] ToPen:[connectedPens lastObject]];
        
        [progressTextField setStringValue:@"Installing Penlet Controls…"];
        
        [self installPenlet:[plugin ethnographerPenletControlsPath] ToPen:[connectedPens lastObject]];
        
        [NSApp endSheet:progressWindow];
        [progressWindow orderOut:self];
        
        [progressIndicator release];
        [progressTextField release];
        [progressWindow release];
        
        [self setCurrentView:[self completeView] animate:YES];
    }
}

- (IBAction)done:(id)sender 
{
    EthnographerPlugin *tempPlugin = [[plugin retain] autorelease];
    [self close];
    [tempPlugin setup];
}

- (IBAction)openTemplatesWindow:(id)sender 
{
    EthnographerPlugin *tempPlugin = [[plugin retain] autorelease];
    [self close];
    [tempPlugin setup];
    [tempPlugin showTemplatesWindow:self];
}

- (IBAction)changeSelectedProjectsFolder:(id)sender {
    
    NSInteger selection = [projectsOptionsButtons selectedRow];
    if(selection == 0)
    {
        self.selectedProjectsFolder = self.defaultDropboxLocation;
    }
    else if (selection == 1)
    {
        self.selectedProjectsFolder = self.defaultDocumentsLocation;
    }
    else
    {
        self.selectedProjectsFolder = nil;
    }
    
}


- (NSString*)checkForExistingProjectsDirectory
{
    NSString *existingProjectsLocation = nil;
    
    NSString *dropbox = [self dropboxDirectory];
    
    if(dropbox)
    {
        // Check to see if it exists in the default location
        NSString *defaultProjectsLocation = [dropbox stringByAppendingPathComponent:@"Projects"];
        if([defaultProjectsLocation fileExists] && [self isValidProjectsFolder:defaultProjectsLocation])
        {
            existingProjectsLocation = defaultProjectsLocation;
        }
        
        if(!existingProjectsLocation)
        {
            NSString *defaultProjectsLocation = [dropbox stringByAppendingPathComponent:defaultProjectsFolderName];
            if([defaultProjectsLocation fileExists] && [self isValidProjectsFolder:defaultProjectsLocation])
            {
                existingProjectsLocation = defaultProjectsLocation;
            }
        }
    }
    
    if(!existingProjectsLocation)
    {
        NSString *defaultProjectsLocation = [[@"~/Documents" stringByAppendingPathComponent:defaultProjectsFolderName] stringByExpandingTildeInPath];
        if([defaultProjectsLocation fileExists] && [self isValidProjectsFolder:defaultProjectsLocation])
        {
            existingProjectsLocation = defaultProjectsLocation;
        }
    }
    
    return existingProjectsLocation;
}



- (void)createProjectsDirectory
{
    if(self.selectedProjectsFolder && ![self isValidProjectsFolder:self.selectedProjectsFolder])
    {        
        BOOL result = [self unzipFile:[plugin projectsFolderTemplatePath]];
        NSString *projectsfolder = [[plugin projectsFolderTemplatePath] stringByDeletingPathExtension];
                
        NSError *err = nil;
        
        if(result && [projectsfolder fileExists])
        {
            [[NSFileManager defaultManager] moveItemAtPath:projectsfolder
                                                    toPath:self.selectedProjectsFolder
                                                     error:&err];
        }
        else
        {
            err = [NSError errorWithDomain:@"ChronoViz" code:0 userInfo:[NSDictionary dictionaryWithObject:@"Couldn't unzip projects folder template" forKey:NSLocalizedDescriptionKey]];
        }
        
        if(err)
        {
            self.selectedProjectsFolder = nil;
            
            if([projectsfolder fileExists])
            {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:projectsfolder error:&error];
                if(error)
                {
                    NSLog(@"Error aborting project directory creation: %@",[error localizedDescription]);
                }
            }
            
            NSAlert *projectCreationAlert = [[NSAlert alloc] init];
            [projectCreationAlert setMessageText:@"There was a problem creating the projects folder."];
            [projectCreationAlert setInformativeText:[NSString stringWithFormat:@"Error Information: %@",[err localizedDescription]]];
            [projectCreationAlert beginSheetModalForWindow:[self window]
                                             modalDelegate:nil
                                            didEndSelector:NULL 
                                               contextInfo:NULL];
            return;
        }
        
    }
    
    if([self isValidProjectsFolder:self.selectedProjectsFolder])
    {
    
        [[NSUserDefaults standardUserDefaults] setObject:self.selectedProjectsFolder forKey:AFEthnographerProjectsDirectoryKey];
            
         [self setCurrentView:[self completeView] animate:YES];
        
    }
}

//-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
//{
//    [self cancel:self];
//    [alert release];
//}

- (BOOL)unzipFile:(NSString*)zipFile
{
	BOOL result = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:zipFile] 
       && [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/unzip"])
	{
		NSTask *task = [[NSTask alloc] init];
		[task setCurrentDirectoryPath:[zipFile stringByDeletingLastPathComponent]];
		[task setLaunchPath:@"/usr/bin/unzip"];
		[task setArguments:[NSArray arrayWithObject:[zipFile lastPathComponent]]];
		[task launch];
		[task waitUntilExit];
				
		if([task terminationStatus] == 0)
		{
			result = YES;
		}
		
        if([[[zipFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"__MACOSX"] fileExists])
		{
            NSError *err = nil;
			[[NSFileManager defaultManager] removeItemAtPath:[[zipFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"__MACOSX"] error:&err];
		}
        
		[task release];	
	}		
	return result;
}

- (NSString*)dropboxDirectory
{
    
    if(!dropboxDirectory)
    {
        NSString *result = [NSString dropboxPath];
        
        if(result)
        {
            dropboxDirectory = [result copy];
        }
    }
    
    return dropboxDirectory;
}

- (BOOL)isValidProjectsFolder:(NSString*)filepath
{
    return [[filepath stringByAppendingPathComponent:@".default/.mappings.xml"] fileExists];
}

- (BOOL)isConnectionAvailable
{
    BOOL connected;
    Boolean success;    
    const char *host_name = "chronoviz.com";
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, host_name);
    SCNetworkReachabilityFlags flags;
    success = SCNetworkReachabilityGetFlags(reachability, &flags);
    connected = success && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired);
    CFRelease(reachability);
    
    return connected;
}

#pragma mark WebView Delegate

- (IBAction)printWebViewContents:(id)sender { 
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo]; 
    NSPrintOperation *printOperation = nil; 
    NSView *webView = [[[instructionsWebView mainFrame] frameView] documentView]; 
    [printInfo setTopMargin:15.0]; 
    [printInfo setLeftMargin:10.0]; 
    [printInfo setHorizontallyCentered:NO]; 
    [printInfo setVerticallyCentered:NO]; 
    printOperation = [NSPrintOperation printOperationWithView:webView printInfo:printInfo]; 
    [printOperation setShowsPrintPanel:YES];
    [printOperation setShowsProgressPanel:YES];
    [printOperation runOperationModalForWindow:[self window] 
                                      delegate:self 
                                didRunSelector:0
                                   contextInfo:NULL]; 
} 

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener {
    
    
    if([[[request URL] absoluteString] rangeOfString:ethnographerInstructionsURL].location != NSNotFound)
    {
        [listener use];
    }
    else
    {
        [listener ignore];
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];    
    }
    
    
//    NSString *host = [[request URL] host];
//    if ([host hasSuffix:@"company.com"])
//        [listener ignore];
//    else
//        [listener use];
}

#pragma mark Livescribe Pens

- (NSArray*)connectedPens
{
    NSTask *chmod = [[NSTask alloc] init];
    [chmod setCurrentDirectoryPath:[[plugin ethnographerTransferPath] stringByDeletingLastPathComponent]];
    [chmod setLaunchPath:@"/bin/chmod"];
    [chmod setArguments:[NSArray arrayWithObjects:@"a+x",[[plugin ethnographerTransferPath] lastPathComponent],nil]];
    [chmod launch];
    [chmod waitUntilExit];
    
    if([chmod terminationStatus] == 0)
    {
        NSLog(@"chmod of livescribe tool failed.");
    }
    
    [chmod release];
    
    NSTask *queueTask = [[NSTask alloc] init];
    NSPipe *newPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [newPipe fileHandleForReading];
    NSData *inData = nil;
    
    NSLog(@"Ethnographer transfer path: %@",[plugin ethnographerTransferPath]);
    
    // write handle is closed to this process
    [queueTask setCurrentDirectoryPath:[[plugin ethnographerTransferPath] stringByDeletingLastPathComponent]];
    [queueTask setStandardOutput:newPipe];
    [queueTask setLaunchPath:[plugin ethnographerTransferPath]];
    [queueTask setArguments:[NSArray arrayWithObjects:@"-function",@"getConnectedPens",nil]];
    [queueTask launch];
    
    NSMutableArray *pens = [NSMutableArray array];
    
    while ((inData = [readHandle availableData]) && [inData length]) {
        NSString *string = [[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding];
        //NSLog(@"Print status: %@",string);
        
        if([string length] > 0)
        {			
            for(NSString *line in [string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]])
            {
                if([[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] > 0)
                {
                    NSLog(@"getConnectedPens output: %@",line);
                    [pens addObject:[NSNumber numberWithLongLong:[line longLongValue]]];
                }
            }
        }
    }
    
    [queueTask release];
    
    return pens;
}

- (void)installPenlet:(NSString*)penlet ToPen:(NSNumber*)penID;
{
    NSTask *queueTask = [[NSTask alloc] init];
    
    // write handle is closed to this process
    [queueTask setLaunchPath:[plugin ethnographerTransferPath]];
    [queueTask setArguments:[NSArray arrayWithObjects:@"-function",@"installPenlet",@"-penID",[penID stringValue],@"-penlet",penlet,nil]];
    [queueTask launch];
    
    [queueTask waitUntilExit];
    
    [queueTask release];
}

@end
