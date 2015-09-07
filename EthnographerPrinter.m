//
//  EthnographerPrinter.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/15/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "EthnographerPrinter.h"
#import "EthnographerPlugin.h"
#import "EthnographerProject.h"
#import "EthnographerTemplate.h"
#import "EthnographerDataSource.h"
#import "AnnotationDocument.h"
#import "DPApplicationSupport.h"
#import "NSStringParsing.h"
#import "NSStringFileManagement.h"
#import "DPConsole.h"

NSString * const DPEthnographerPrintLivescribe = @"livescribe";
NSString * const DPEthnographerPrintAnotoWithoutControls = @"plain";
NSString * const DPEthnographerPrintAnotoWithControls = @"control";

NSString * const DPEthnographerPrintPageSizeLetter = @"letter";
NSString * const DPEthnographerPrintPageSizeA4 = @"isoa4";

NSString * const DPEthnographerPrintDotRadius = @"EthnographerPrintDotRadius";
NSString * const DPEthnographerPrintPageSize = @"EthnographerPrintPageSize";

NSString * const DPEthnographerLastPrinterKey = @"DPEthnographerLastPrinter";
NSString * const DPEthnographerLastPrintTypeKey = @"DPEthnographerLastPrintType";

NSString * const DPEthnographerJavaMemSizeKey = @"DPEthnographerJavaMemSize";

NSString * const AFEthnographerDoNotPrint = @"EthnographerDoNotPrint";

@interface EthnographerPrinter (Internal)

- (NSString*)printingDirectory;

- (void)runPrintJob:(NSDictionary*)printJob inWindow:(NSWindow*)window;

- (void)continuePrintJob;

- (void)deleteCurrentPrintFiles;

- (OSStatus) createPMPrinters:( CFArrayRef *)outPrinters andPrinterNames:(CFArrayRef *)outPrinterNames;

- (NSWindow*)dataTransferStartupWindow;

@end


@implementation EthnographerPrinter
@synthesize copiesField;
@synthesize copiesNumberFormatter;

@synthesize printPanel,printButton,printLabel,printTypeLabel,printerList,printProgressIndicator,printTypeList,printOptionsButton;
@synthesize advancedOptions,dotRadiusSlider,paperTypeList;
@synthesize dotRadius,paperFormat,printType;
@synthesize currentPrintFile, currentPrintError;

+ (void)initialize
{
	if ( self == [EthnographerPrinter class] ) {
		NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
		
		[defaultValues setObject:[NSNumber numberWithDouble:0.02] forKey:DPEthnographerPrintDotRadius];
		[defaultValues setObject:DPEthnographerPrintPageSizeLetter forKey:DPEthnographerPrintPageSize];
        [defaultValues setObject:[NSNumber numberWithInt:768] forKey:DPEthnographerJavaMemSizeKey];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
	}
}

- (id) initWithPlugin:(EthnographerPlugin*)thePlugin
{
	self = [super init];
	if (self != nil) {
		plugin = [thePlugin retain];
		
		currentPrintFile = nil;
        dataTransferTask = nil;
        
        printAnotoClasspath = [[NSString alloc] initWithFormat:@"%@:%@",[plugin printingClientPath],[[plugin penPrintingPath] stringByAppendingPathComponent:@"resources"]];
        
        //printAnotoClasspath = [[plugin printingClientPath] stringByAppendingString:@":./resources/"];
		//printAnotoClasspath = @"AnotoPrinter.jar:./resources/";
		printAnotoClass = @"PrintAnotoStreaming";
		printLivescribeClass = @"PrintLivescribe";
		saveTemplateClass = @"SaveTemplate";
        deleteTemplateClass = @"DeleteTemplate";
        deleteNotesClass = @"DeleteNotes";
        generatePdfClass = @"GeneratePdf";
		
		self.printType = DPEthnographerPrintLivescribe;
		 
		[self addObserver:self
			   forKeyPath:@"currentPrintFile"
				  options:0
				  context:NULL];
		
		[self addObserver:self
			   forKeyPath:@"currentPrintError"
				  options:0
				  context:NULL];
		
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if([keyPath isEqualToString:@"currentPrintFile"])
	{
		if(currentPrintFile != nil)
			[self continuePrintJob];
	}
	else if ([keyPath isEqualToString:@"currentPrintError"])
	{
		if(currentPrintError != nil)
			[self continuePrintJob];
    }
}

- (void) dealloc
{
    [self closeDataTransferWindow:self];
    
	self.printPanel = nil;
	self.printButton = nil;
	self.printLabel = nil;
	self.printerList = nil;
	self.printProgressIndicator = nil;
	self.printTypeList = nil;
	self.printOptionsButton = nil;
	
	self.advancedOptions = nil;
	self.dotRadiusSlider = nil;
	self.paperTypeList = nil;
	
	self.currentPrintFile = nil;
	
	self.paperFormat = nil;
	self.printType = nil;
	
    [printAnotoClasspath release];
	[plugin release];
	[super dealloc];
}

- (void)printTemplate:(EthnographerTemplate*)theTemplate fromWindow:(NSWindow*)window
{
    NSString *lastPrintType = [[NSUserDefaults standardUserDefaults] stringForKey:DPEthnographerLastPrintTypeKey];
    if(lastPrintType)
    {
        self.printType = lastPrintType;
    }
    else
    {
        self.printType = DPEthnographerPrintLivescribe;
    }
    
    NSDictionary *printJob = [NSDictionary dictionaryWithObjectsAndKeys:
                              [theTemplate name], @"Template",
							  nil];
	
	NSLog(@"Template to print: %@",[theTemplate name]);
	
	[self runPrintJob:printJob inWindow:window];
}

- (void)printLivescribeTemplate:(EthnographerTemplate*)theTemplate fromWindow:(NSWindow*)window
{
	self.printType = DPEthnographerPrintLivescribe;
	
	NSDictionary *printJob = [NSDictionary dictionaryWithObjectsAndKeys:
							 [theTemplate name], @"Template",
							  nil];
	
	NSLog(@"Template to print: %@",[theTemplate name]);
	
	[self runPrintJob:printJob inWindow:window];
}

- (void)printAnoto:(EthnographerDataSource*)notesSource fromWindow:(NSWindow*)window
{
	self.printType = DPEthnographerPrintAnotoWithControls;
	
	NSDictionary *printJob = [NSDictionary dictionaryWithObjectsAndKeys:
							  notesSource,@"DataSource",
							  [notesSource dataFile],@"Session",
							  [notesSource.backgroundTemplate name],@"Template",
							  nil];
	
	[self runPrintJob:printJob inWindow:window];
}

- (void)printControl:(NSString*)control fromWindow:(NSWindow*)window
{
    self.printType = DPEthnographerPrintAnotoWithControls;
	
	NSDictionary *printJob = [NSDictionary dictionaryWithObjectsAndKeys:
							  control,@"ControlFile",
							  [NSNumber numberWithBool:YES],@"Controls",
							  nil];
	
	[self runPrintJob:printJob inWindow:window];
}

- (void)saveTemplate:(NSString*)templateName withBackground:(NSString*)backgroundFile toProject:(EthnographerProject*)theProject
{
	NSTask *currentPrintTask = [[NSTask alloc] init];
	//[task setCurrentDirectoryPath:[postscriptFile stringByDeletingLastPathComponent]];
	[currentPrintTask setCurrentDirectoryPath:[self printingDirectory]];
	[currentPrintTask setLaunchPath:@"/usr/bin/java"];

	NSString *template = [templateName quotedString];
	NSString *project = [[[theProject mappingsFile] stringByDeletingLastPathComponent] quotedString];
	NSString *background = [backgroundFile quotedString];
	
	self.paperFormat = [[NSUserDefaults standardUserDefaults] stringForKey:DPEthnographerPrintPageSize];
	
    int javaMemSize = [[NSUserDefaults standardUserDefaults] integerForKey:DPEthnographerJavaMemSizeKey];
    NSString * printJavaMinMem = [NSString stringWithFormat:@"-Xms%im",javaMemSize];
    NSString * printJavaMaxMem = [NSString stringWithFormat:@"-Xmx%im",javaMemSize];

    
	[currentPrintTask setArguments:[NSArray arrayWithObjects:
                                    printJavaMinMem,printJavaMaxMem,
									@"-Djava.awt.headless=true",
									@"-cp",printAnotoClasspath,
									saveTemplateClass,
									@"-format",@"Letter",
									@"-project",project,
									@"-template",template,
									@"-background",background,
									nil]];
	
	
	[currentPrintTask launch];
	[currentPrintTask waitUntilExit];
	[currentPrintTask release];
}

- (void)deleteTemplate:(NSString*)templateName fromProject:(EthnographerProject*)theProject
{
    NSTask *currentPrintTask = [[NSTask alloc] init];
	//[task setCurrentDirectoryPath:[postscriptFile stringByDeletingLastPathComponent]];
	[currentPrintTask setCurrentDirectoryPath:[self printingDirectory]];
	[currentPrintTask setLaunchPath:@"/usr/bin/java"];
    
	NSString *template = [templateName quotedString];
	NSString *project = [[[theProject mappingsFile] stringByDeletingLastPathComponent] quotedString];
    
	[currentPrintTask setArguments:[NSArray arrayWithObjects:
                                    @"-Xms512m",@"-Xmx512m",
                                    @"-cp",printAnotoClasspath,
									deleteTemplateClass,
									@"-project",project,
									@"-template",template,
                                    @"-deletenotes",@"yes",
									nil]];
	
	NSLog(@"%@",[currentPrintTask currentDirectoryPath]);
    NSLog(@"%@",[currentPrintTask arguments]);
    
	[currentPrintTask launch];
	[currentPrintTask waitUntilExit];
	[currentPrintTask release];
}

- (void)deleteNoteSession:(NSString*)sessionPath fromProject:(EthnographerProject*)theProject
{
    NSTask *currentPrintTask = [[NSTask alloc] init];
	//[task setCurrentDirectoryPath:[postscriptFile stringByDeletingLastPathComponent]];
	[currentPrintTask setCurrentDirectoryPath:[self printingDirectory]];
	[currentPrintTask setLaunchPath:@"/usr/bin/java"];
    
	NSString *session = [sessionPath quotedString];
	NSString *project = [[[theProject mappingsFile] stringByDeletingLastPathComponent] quotedString];
	
	[currentPrintTask setArguments:[NSArray arrayWithObjects:
                                    @"-Xms512m",@"-Xmx512m",
									@"-cp",printAnotoClasspath,
									deleteNotesClass,
									@"-project",project,
									@"-notes",session,
									nil]];
	
	
	[currentPrintTask launch];
	[currentPrintTask waitUntilExit];
	[currentPrintTask release];
}

- (void)updateSessionPdf:(NSString*)sessionPath inProject:(EthnographerProject*)theProject
{
    NSTask *currentPrintTask = [[NSTask alloc] init];
	//[task setCurrentDirectoryPath:[postscriptFile stringByDeletingLastPathComponent]];
	[currentPrintTask setCurrentDirectoryPath:[self printingDirectory]];
	[currentPrintTask setLaunchPath:@"/usr/bin/java"];
    
	NSString *session = [sessionPath quotedString];
	NSString *project = [[[theProject mappingsFile] stringByDeletingLastPathComponent] quotedString];
	
	[currentPrintTask setArguments:[NSArray arrayWithObjects:
                                    @"-Xms512m",@"-Xmx512m",
									@"-cp",printAnotoClasspath,
									generatePdfClass,
									@"-project",project,
									@"-session",session,
									nil]];
	
    NSLog(@"%@",[currentPrintTask description]);
	
	[currentPrintTask launch];
	//[currentPrintTask waitUntilExit];
	[currentPrintTask autorelease];
}

- (IBAction)showDataTransferWindow:(id)sender
{
    /*
     set appDir to result
     set rootDir to appDir & "Contents/Resources"
     #tell application "Terminal"
     #do shell script "cd " & rootDir & "; pwd"
     #display dialog "" & result buttons {"Close"} default button 1
     do shell script "cd " & rootDir & "; java  -Djava.awt.headless=true -Xdock:name=\"Ethnographer++ Transfer Tool\"  -d64 -XstartOnFirstThread  -classpath \"" & rootDir & "\":\"" & rootDir & "/AnotoPrinter.jar\" edu.ucsd.hci.chronoviz.anotoprinter.transfer.TransferToolApp >> " & rootDir & "/logs/transferTool.log  2>&1"
     */
    
    if(!dataTransferTask)
    {
        [[self dataTransferStartupWindow] makeKeyAndOrderFront:self];
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(receivedApplicationStarted:)
																   name:NSWorkspaceDidLaunchApplicationNotification
																 object:nil];
		
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(receivedApplicationTerminated:)
																   name:NSWorkspaceDidTerminateApplicationNotification
																 object:nil];
        
        dataTransferTask = [[NSTask alloc] init];
        NSTask *currentPrintTask = dataTransferTask;
        [currentPrintTask setCurrentDirectoryPath:[[plugin printingClientPath] stringByDeletingLastPathComponent]];
        [currentPrintTask setLaunchPath:@"/usr/bin/java"];
        
        NSString *toolicon = [[[plugin printingClientPath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"TransferToolIcon.icns"];
        
        int javaMemSize = [[NSUserDefaults standardUserDefaults] integerForKey:DPEthnographerJavaMemSizeKey];
        NSString * printJavaMinMem = [NSString stringWithFormat:@"-Xms%im",javaMemSize];
        NSString * printJavaMaxMem = [NSString stringWithFormat:@"-Xmx%im",javaMemSize];
        
        [currentPrintTask setArguments:[NSArray arrayWithObjects:
                                        //@"-Djava.awt.headless=true",
                                        printJavaMinMem,printJavaMaxMem,
                                        @"-Xdock:name=Livescribe Data Transfer Tool",
                                        [NSString stringWithFormat:@"-Xdock:icon=%@",toolicon],
                                        @"-d64",
                                        @"-XstartOnFirstThread",
                                        @"-cp",printAnotoClasspath,
                                        @"edu.ucsd.hci.chronoviz.anotoprinter.transfer.TransferToolApp",
                                        nil]];
        
        NSLog(@"%@",[currentPrintTask arguments]);
        
        [currentPrintTask launch];
        //[currentPrintTask autorelease]; 
        
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(closeDataTransferWindow:)
													 name:NSApplicationWillTerminateNotification
												   object:nil];
    }
}

- (NSWindow*)dataTransferStartupWindow
{
	if(!dataTransferStartupWindow)
	{
		dataTransferStartupWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(200,400,480,120)
                                                     styleMask:NSTitledWindowMask
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO];
		[dataTransferStartupWindow setLevel:NSStatusWindowLevel];
		[dataTransferStartupWindow setReleasedWhenClosed:NO];
		
		NSProgressIndicator* progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(18, 56, 444, 20)];
		
//		cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(370,12,96,32)];
//		[cancelButton setBezelStyle:NSRoundedBezelStyle];
//		[cancelButton setTitle:@"Cancel"];
//		[cancelButton setAction:@selector(stopListening:)];
//		[cancelButton setTarget:self];
		
		NSTextField *progressTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(17, 84, 444, 17)];
		[progressTextField setStringValue:@"Starting Livescribe Transfer Tool…"];
		[progressTextField setEditable:NO];
		[progressTextField setDrawsBackground:NO];
		[progressTextField setBordered:NO];
		[progressTextField setAlignment:NSLeftTextAlignment];
		
		[[dataTransferStartupWindow contentView] addSubview:progressIndicator];
		//[[progressWindow contentView] addSubview:cancelButton];
		[[dataTransferStartupWindow contentView] addSubview:progressTextField];
        
        [progressIndicator setIndeterminate:YES];
        [progressIndicator startAnimation:self];
	}
	return dataTransferStartupWindow;
}


- (void)receivedApplicationTerminated:(NSNotification*)notification
{
	NSDictionary *userInfo = [notification userInfo];
        
    //NSLog(@"App Terminated %@",[userInfo objectForKey:@"NSApplicationBundleIdentifier"]);
    
    NSString *appName = [userInfo objectForKey:@"NSApplicationName"];
    
    if(dataTransferTask && ([appName rangeOfString:@"Transfer Tool"].location != NSNotFound))
    {
        [self closeDataTransferWindow:self];
    }

}

- (void)receivedApplicationStarted:(NSNotification*)notification
{
	//NSDictionary *userInfo = [notification userInfo];
	
	//NSLog(@"App Started %@",[userInfo objectForKey:@"NSApplicationBundleIdentifier"]);
    
    if(dataTransferStartupWindow)
    {
        [dataTransferStartupWindow close];
        [dataTransferStartupWindow release];
        dataTransferStartupWindow = nil;
    }
	
}

- (IBAction)closeDataTransferWindow:(id)sender
{
    if(dataTransferTask)
    {
        [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
        
        [dataTransferTask terminate];
        [dataTransferTask release];
        dataTransferTask = nil;
    }
}

- (void)runPrintJob:(NSDictionary*)printJob inWindow:(NSWindow*)window
{
    if(printPanel && [printPanel isVisible])
    {
        return;
    }
    
	[currentPrintJob release];
	currentPrintJob = [printJob retain];
	
	if (!printPanel)
	{
		[NSBundle loadNibNamed:@"EthnographerPrintingWindow" owner:self];

		[advancedOptions setHidden:YES];
		
		[dotRadiusSlider setMinValue:0.02];
		[dotRadiusSlider setMaxValue:0.1];
		self.dotRadius = [[NSUserDefaults standardUserDefaults] doubleForKey:DPEthnographerPrintDotRadius];
		[dotRadiusSlider setFloatValue:self.dotRadius];
		
		NSLog(@"Dot Radius: %f",(float)self.dotRadius);
		
		[printTypeList removeAllItems];
		[printTypeList addItemWithTitle:@"Livescribe"];
		[[printTypeList lastItem] setRepresentedObject:DPEthnographerPrintLivescribe];
		[printTypeList addItemWithTitle:@"Anoto Streaming With Controls"];
		[[printTypeList lastItem] setRepresentedObject:DPEthnographerPrintAnotoWithControls];
		[printTypeList addItemWithTitle:@"Anoto Streaming Without Controls"];
		[[printTypeList lastItem] setRepresentedObject:DPEthnographerPrintAnotoWithoutControls];
		
		[paperTypeList removeAllItems];
		[paperTypeList addItemWithTitle:@"Letter"];
		[[paperTypeList lastItem] setRepresentedObject:DPEthnographerPrintPageSizeLetter];
		[paperTypeList addItemWithTitle:@"A4"];
		[[paperTypeList lastItem] setRepresentedObject:DPEthnographerPrintPageSizeA4];
		
		self.paperFormat = [[NSUserDefaults standardUserDefaults] stringForKey:DPEthnographerPrintPageSize];
		
		for(NSMenuItem *item in [paperTypeList itemArray])
		{
			if([self.paperFormat isEqualToString:[item representedObject]])
			{
				[paperTypeList selectItem:item];
				break;
			}
		}
        
	}
	
    [copiesField setStringValue:@"1"];
    
    if([printJob objectForKey:@"Controls"])
    {
        [printTypeList selectItemWithTitle:@"Anoto Streaming With Controls"];
        [printTypeList setEnabled:NO];
    }
    else
    {
        [printTypeList setAutoenablesItems:NO];
        NSMenuItem *livescribeItem = [printTypeList itemWithTitle:@"Livescribe"];
        BOOL sessionIncluded = ([printJob objectForKey:@"Session"] != nil);
        [printTypeList setEnabled:YES];
        [livescribeItem setEnabled:!sessionIncluded];
        //NSLog(@"Template for printing: %@",[printJob objectForKey:@"Template"]);
    }
    
	if([advancedOptions window] == printPanel)
	{
		NSRect frame = [printPanel frame];
		frame.size.height = frame.size.height - [advancedOptions frame].size.height;
		[advancedOptions removeFromSuperview];
		[printPanel setFrame:frame display:YES];
	}
	
	for(NSMenuItem *item in [printTypeList itemArray])
	{
		if([self.printType isEqualToString:[item representedObject]])
		{
			[printTypeList selectItem:item];
			break;
		}
	}
	
	[printerList removeAllItems];
	
    /////
    
    NSArray* printers = nil;
    NSArray* printerNames = nil;
    
    [self createPMPrinters:(CFArrayRef*)&printers andPrinterNames:(CFArrayRef*)&printerNames];
    
    CFStringRef printerID;
    for(int i = 0; i < [printerNames count]; i++)
    {
        
        PMPrinter printer = (PMPrinter)CFArrayGetValueAtIndex((CFArrayRef)printers, i );
        printerID = PMPrinterGetID( printer );
        
        [printerList addItemWithTitle:(NSString*)[printerNames objectAtIndex:i]];
        [[printerList lastItem] setRepresentedObject:(NSString*)printerID];
        
        
        NSLog(@"Printer name: %@",[printerNames objectAtIndex:i]);
        NSLog(@"Printer ID: %@",(NSString*)printerID);
        
        CFRelease( printerID );
    }
    
    
    /////
	
    
    NSString *lastPrinter = [[NSUserDefaults standardUserDefaults] stringForKey:DPEthnographerLastPrinterKey];
    if(lastPrinter)
    {
        [printerList selectItemWithTitle:lastPrinter];
    }
    else
    {
        [printerList selectItemWithTitle:[[[NSPrintInfo sharedPrintInfo] printer] name]];
    }
    
	//NSPrinter *currentPrinter = [[NSPrintInfo sharedPrintInfo] printer];
	//[printerList selectItemWithTitle:[currentPrinter name]];
	
	[printProgressIndicator stopAnimation:self];
	[printProgressIndicator setHidden:YES];
	[printerList setHidden:NO];
	[printTypeList setHidden:NO];
	[printTypeLabel setHidden:NO];
	[printButton setEnabled:YES];
	[printLabel setStringValue:@"Printer:"];
	
	[NSApp beginSheet: printPanel
	   modalForWindow: window
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
}

- (IBAction)closePrintPanel:(id)sender
{
	[NSApp endSheet:printPanel];
	[currentPrintJob release];
	currentPrintJob = nil;
}

- (IBAction)confirmPrint:(id)sender
{
	
    EthnographerDataSource *source = (EthnographerDataSource *)[currentPrintJob objectForKey:@"DataSource"];
    
    if(source)
    {
        [source updateSessionFile:nil];
    }
    
    self.printType = [[printTypeList selectedItem] representedObject];
    
    [[NSUserDefaults standardUserDefaults] setObject:[[printerList selectedItem] title] forKey:DPEthnographerLastPrinterKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.printType forKey:DPEthnographerLastPrintTypeKey];
    
    NSString *queueName = [[printerList selectedItem] representedObject];
    
	NSLog(@"Print to printer: %@",queueName);
	
	[printQueue release];
	printQueue = [queueName copy];
	
	[printProgressIndicator setIndeterminate:YES];
	[printProgressIndicator startAnimation:self];
	[printProgressIndicator setHidden:NO];
	[printerList setHidden:YES];
	[printTypeList setHidden:YES];
	[printTypeLabel setHidden:YES];
	[printButton setEnabled:NO];
    
    if([currentPrintJob objectForKey:@"Controls"])
    {
        self.currentPrintFile = [currentPrintJob objectForKey:@"ControlFile"];
        return;
    }
    
	[printLabel setStringValue:@"Preparing template for printing…"];
	
	self.currentPrintFile = nil;
	self.currentPrintError = nil;
	
	NSTask *currentPrintTask = [[NSTask alloc] init];
	//[task setCurrentDirectoryPath:[postscriptFile stringByDeletingLastPathComponent]];
	[currentPrintTask setCurrentDirectoryPath:[self printingDirectory]];
	[currentPrintTask setLaunchPath:@"/usr/bin/java"];
	
	NSString *printFormat = [[[paperTypeList selectedItem] representedObject] quotedString];
	NSString *template = [[currentPrintJob objectForKey:@"Template"] quotedString];
	NSString *project = [[[plugin.currentProject mappingsFile] stringByDeletingLastPathComponent] quotedString];
	
	NSLog(@"Trying to print: %@",template);
	
	NSString *printerIcon = [[NSBundle mainBundle] pathForResource:@"ChronoVizPrinterIcon" ofType:@"png"];
	
    int javaMemSize = [[NSUserDefaults standardUserDefaults] integerForKey:DPEthnographerJavaMemSizeKey];
    NSString * printJavaMinMem = [NSString stringWithFormat:@"-Xms%im",javaMemSize];
    NSString * printJavaMaxMem = [NSString stringWithFormat:@"-Xmx%im",javaMemSize];
    
	NSMutableArray *arguments = [[NSMutableArray alloc] initWithObjects:
								 @"-Xdock:name=\"ChronoViz Anoto Printer\"",
								 [NSString stringWithFormat:@"-Xdock:icon=%@",printerIcon],
								 printJavaMinMem,printJavaMaxMem,
								 @"-cp",printAnotoClasspath,
								 nil];
	
	NSString *docID = nil;
	
	if([printType isEqualToString:DPEthnographerPrintLivescribe])
	{
		[arguments addObjectsFromArray:[NSArray arrayWithObjects:
										printLivescribeClass,
										@"-type",@"plain",
										nil]];
										
		
	}
	else
	{
		[arguments addObjectsFromArray:[NSArray arrayWithObjects:
										printAnotoClass,
										@"-type",[printType quotedString],
										nil]];
		
		NSString *session = [currentPrintJob objectForKey:@"Session"];
		
		if(session)
		{
			[arguments addObjectsFromArray:[NSArray arrayWithObjects:
											@"-session",session,
											nil]];
			docID = [NSString stringWithFormat:@"%@ - %@",
							[[[[AnnotationDocument currentDocument] annotationsDirectory] lastPathComponent] stringByDeletingPathExtension],
							[session lastPathComponent]];
		}
        
        session =[session quotedString];

	}
	
	if(!docID)
	{
		docID = [[[[AnnotationDocument currentDocument] annotationsDirectory] lastPathComponent] stringByDeletingPathExtension];
        
        if ([docID isEqualToString:@"tempannotation"])
        {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            [dateFormatter setLocale:usLocale];
            docID = [dateFormatter stringFromDate:[NSDate date]];
            [dateFormatter release];
        }
	}
	
	[arguments addObjectsFromArray:[NSArray arrayWithObjects:
									 @"-document",[docID quotedString],
									 @"-project",project,
									 @"-template",template,
									 @"-format",printFormat,
									 @"-dotrad",[NSString stringWithFormat:@"%.2f",self.dotRadius],
									 nil]];
	
	NSLog(@"Print arguments: %@",[arguments description]);
	
    NSInteger copies = [copiesField integerValue];
    if(copies < 1)
    {
        copies = 1;
    }
    if(copies > 100)
    {
        copies = 100;
    }
    if(copies > 1)
    {
        NSMutableDictionary *newPrintJob = [currentPrintJob mutableCopy];
        [newPrintJob setObject:[NSNumber numberWithInteger:copies] forKey:@"NumberOfCopies"];
        [currentPrintJob release];
        currentPrintJob = newPrintJob;
    }
    
	[currentPrintTask setArguments:arguments];
	[arguments release];
	
	[[DPConsole defaultConsole] attachTaskOutput:currentPrintTask];
	
	[currentPrintTask launch];
	//[currentPrintTask waitUntilExit];
	[currentPrintTask autorelease];
	
	return;
	
}
		 

-(void)continuePrintJob
{	
	NSLog(@"Continute print job");
	
	if(currentPrintFile && currentPrintJob)
	{
		EthnographerDataSource *source = (EthnographerDataSource *)[currentPrintJob objectForKey:@"DataSource"];
		
		if(source)
		{
            [source reloadSessionXML];
			[source updateAnotoMappings];
		}
		
		[self updatePrintStatus:@"Sending to printer…" percent:-1.0];
		
		NSTask *task = [[NSTask alloc] init];
		//[task setCurrentDirectoryPath:[postscriptFile stringByDeletingLastPathComponent]];
		[task setLaunchPath:@"/usr/bin/lpr"];
        
        NSNumber *copies = [currentPrintJob objectForKey:@"NumberOfCopies"];
        if(copies)
        {
            [task setArguments:[NSArray arrayWithObjects:@"-P",printQueue,@"-#",[copies stringValue],@"-o",@"Collate=True",currentPrintFile,nil]];
        }
        else
        {
            [task setArguments:[NSArray arrayWithObjects:@"-P",printQueue,currentPrintFile,nil]];
        }
        
        //[[NSUserDefaults standardUserDefaults] boolForKey:AFEthnographerDoNotPrint];
		BOOL reallyprint = ![[NSUserDefaults standardUserDefaults] boolForKey:AFEthnographerDoNotPrint];
		if(reallyprint)
		{
			[task launch];
			[task waitUntilExit];			
		}
		else
		{
			NSLog(@"WARNING: not actually printing!");
		}

		[task release];
		
		NSPrinter *currentPrinter = [NSPrinter printerWithName:[printerList titleOfSelectedItem]];
		[[NSPrintInfo sharedPrintInfo] setPrinter:currentPrinter];
		
		printMonitor = [NSTimer scheduledTimerWithTimeInterval:1.0
														target:self
													  selector:@selector(checkPrintStatus:)
													  userInfo:nil
													   repeats:YES];	
	}
	else
	{
		if(currentPrintError)
		{
			NSAlert *errorAlert = [[NSAlert alloc] init];
			[errorAlert setMessageText:currentPrintError];
			self.currentPrintError = nil;
			[errorAlert runModal];
			[errorAlert release];
		}
		[NSApp endSheet:printPanel];
		[printProgressIndicator stopAnimation:self];
		[printProgressIndicator setHidden:YES];
		[printerList setHidden:NO];
		[printTypeList setHidden:NO];
		[printTypeLabel setHidden:NO];
		[printButton setEnabled:YES];
		[printLabel setStringValue:@"Printer:"];
	}
	
	[currentPrintJob release];
	currentPrintJob = nil;
	
}

- (void)checkPrintStatus:(id)sender
{
    NSTask *queueTask = [[NSTask alloc] init];
    NSPipe *newPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [newPipe fileHandleForReading];
    NSData *inData = nil;
	
    // write handle is closed to this process
    [queueTask setStandardOutput:newPipe];
	[queueTask setLaunchPath:@"/usr/bin/lpq"];
	[queueTask setArguments:[NSArray arrayWithObjects:@"-P",printQueue,nil]];
    [queueTask launch];
	
    while ((inData = [readHandle availableData]) && [inData length]) {
		NSString *string = [[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding];
		//NSLog(@"Print status: %@",string);
		
		if([string length] > 0)
		{			
			if([string rangeOfString:@"no entries"].location != NSNotFound)
			{
				[printMonitor invalidate];
				printMonitor = nil;
				
				[NSApp endSheet:printPanel];
				[printProgressIndicator stopAnimation:self];
				[printProgressIndicator setHidden:YES];
				[printerList setHidden:NO];
				[printTypeList setHidden:NO];
				[printTypeLabel setHidden:NO];
				[printButton setEnabled:YES];
				[printLabel setStringValue:@"Printer:"];
				
                if([self.currentPrintFile rangeOfString:[plugin penPrintingPath]].location == NSNotFound)
                {
                    [self deleteCurrentPrintFiles];
                }
			}
		}
    }
	
    [queueTask release];
}


- (void)deleteCurrentPrintFiles
{
	NSError *err = nil;
	if(currentPrintFile)
	{
		NSString *printFilesDirectory = [currentPrintFile stringByDeletingLastPathComponent];
		
		if([printFilesDirectory isDirectory])
		{
			NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:printFilesDirectory error:&err];
			
			if(err)
			{
				NSLog(@"Error removing print files: %@",[err localizedDescription]);
			}
			else
			{
				for(NSString *file in files)
				{
					err = nil;
					[[NSFileManager defaultManager] removeItemAtPath:[printFilesDirectory stringByAppendingPathComponent:file] error:&err];
					if(err)
					{
						NSLog(@"Error removing print file %@:%@",file,[err localizedDescription]);
					}
				}
			}
		}
		
	}
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

- (IBAction)expandPrintOptions:(id)sender
{
	if([advancedOptions window] == printPanel)
	{
		[advancedOptions removeFromSuperview];
		
		NSRect frame = [printPanel frame];
		frame.size.height = frame.size.height - [advancedOptions frame].size.height;
		[printPanel setFrame:frame display:NO animate:YES];
		
		[printOptionsButton setState:0];
	}
	else
	{
		NSRect frame = [printPanel frame];
		frame.size.height = frame.size.height + [advancedOptions frame].size.height;
		[printPanel setFrame:frame display:NO animate:YES];	
		
        [copiesNumberFormatter setMaximumFractionDigits:0];
        
		[printOptionsButton setState:1];
		NSRect optionsFrame = [advancedOptions frame];
		optionsFrame.origin.x = 0;
		optionsFrame.origin.y = [printTypeList frame].origin.y - [advancedOptions frame].size.height;
		[advancedOptions setFrame:optionsFrame];
		
		[[printPanel contentView] addSubview:advancedOptions];
		[advancedOptions setHidden:NO];
	}
}
	
- (void)updatePrintStatus:(NSString*)message percent:(CGFloat)percent
{
	if(![printProgressIndicator isHidden])
	{
		[printLabel setStringValue:message];
		
		if(percent > 0)
		{
			if([printProgressIndicator isIndeterminate])
			{
				[printProgressIndicator setIndeterminate:NO];
				[printProgressIndicator setMinValue:0];
				[printProgressIndicator setMaxValue:100];
			}
			
			[printProgressIndicator setDoubleValue:percent];
		}
		else {
			if(![printProgressIndicator isIndeterminate])
			{
				[printProgressIndicator setIndeterminate:YES];
				[printProgressIndicator startAnimation:self];
			}
		}

	}
}

#pragma mark Paths

- (NSString*)printingDirectory
{
	//return [[DPApplicationSupport userSupportFolder] stringByAppendingPathComponent:@"PenPrinting"];
    return [plugin penPrintingPath];
}


#pragma mark Printers

- (OSStatus) createPMPrinters:( CFArrayRef *)outPrinters andPrinterNames:(CFArrayRef *)outPrinterNames
{
    *outPrinters = NULL;
    *outPrinterNames = NULL;
    // Obtain the list of PMPrinters
    OSStatus err = PMServerCreatePrinterList( kPMServerLocal, outPrinters );
    if( err == noErr )
    {
        CFIndex i, count = CFArrayGetCount(*outPrinters);
        // Create another array to hold the printer names. You may use this to create a menu or list for
        // the user to select a printer.
        CFMutableArrayRef printerNames = CFArrayCreateMutable( NULL, count, &kCFTypeArrayCallBacks );
        if( printerNames )
        {
            for(i = 0; i < count; ++i)
            {
                PMPrinter printer = (PMPrinter)CFArrayGetValueAtIndex( *outPrinters, i );
                CFStringRef name = PMPrinterGetName( printer );
                CFArrayAppendValue( printerNames, name );
            }
        }
        *outPrinterNames = printerNames;
    }
    return err;
}
				



@end
