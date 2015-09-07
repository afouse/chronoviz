//
//  EthnographerTemplateManagementController.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/11/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "EthnographerTemplateManagementController.h"
#import "EthnographerPlugin.h"
#import "EthnographerPrinter.h"
#import "EthnographerProject.h"
#import "EthnographerTemplate.h"

@interface EthnographerTemplateManagementController (Internal)

- (void)selectTemplate:(EthnographerTemplate*)template;
- (void)showTemplatePage:(NSUInteger)index;
- (void)requestNewTemplateNameForFile:(NSString*)filePath;

- (void)selectSessionFile:(NSString*)sessionFile loadPreview:(BOOL)loadPreview;

- (void)selectControl:(NSString*)control;

@end

@implementation EthnographerTemplateManagementController

@synthesize plugin, currentProject;
@synthesize selectedSessionFile;

- (id)init
{
	if(![super initWithWindowNibName:@"EthnographerTemplateManagementWindow"])
		return nil;
	
	plugin = nil;
	currentProject = nil;
    splitViewDelegates = nil;
		
	return self;
}

- (void) dealloc
{	
    [splitViewDelegates release];
	plugin = nil;
	currentProject = nil;
    self.selectedSessionFile = nil;
	[super dealloc];
}


- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex;
{
    //NSLog(@"%@:%s proposedMinimum: %f",[self class], _cmd, proposedMinimumPosition);
    return proposedMinimumPosition + 150;
}


- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex;
{
   // NSLog(@"%@:%s proposedMaximum: %f",[self class], _cmd, proposedMaximumPosition);
    return proposedMaximumPosition - 300;
}

-(IBAction)showWindow:(id)sender
{
	[self window];
	
    [templatesSplitView setDelegate:self];
    [sessionsSplitView setDelegate:self];
    [controlsSplitView setDelegate:self];
    
    [tabView selectTabViewItemAtIndex:0];
    
	[pageLabel setStringValue:@""];
	[nextPageButton setEnabled:NO];
	[previousPageButton setEnabled:NO];
	
	if(plugin)
	{
		if([[plugin projectNames] count] > 0)
		{
			[projectButton removeAllItems];
			for(NSString *project in [plugin projectNames])
			{
				[projectButton addItemWithTitle:project];
			}		
		}
		
		currentProject = [plugin currentProject];
		
		[projectButton selectItemWithTitle:[currentProject projectName]];
		
		[templateList reloadData];
	
	}
	
	[super showWindow:sender];
}

- (IBAction)newProjectAction:(id)sender
{
	[plugin requestNewProjectNameInWindow:[self window]
							 withCallback:@selector(showWindow:)
								andTarget:self];
}

- (IBAction)changeProjectAction:(id)sender
{
	NSString *newProjectName = [[projectButton selectedItem] title];
	if(![newProjectName isEqualToString:[currentProject projectName]])
	{
		EthnographerProject* project = [plugin projectForName:newProjectName];
		plugin.currentProject = project;
		currentProject = project;
		
		[self showWindow:self];
	}
}

- (void)reloadPreview
{
    if(self.selectedSessionFile)
    {
        [self selectSessionFile:self.selectedSessionFile loadPreview:YES];
    }
}

- (void)cancelPreview
{
    if(self.selectedSessionFile)
    {
        [self selectSessionFile:self.selectedSessionFile loadPreview:NO];
    }
}

- (IBAction)selectTemplatesPane:(id)sender
{
    [tabView selectTabViewItemAtIndex:0];
}

- (IBAction)selectSessionsPane:(id)sender
{
    [tabView selectTabViewItemAtIndex:1];
}

- (IBAction)selectControlsPane:(id)sender
{
    [tabView selectTabViewItemAtIndex:2];
}

#pragma mark Templates

- (IBAction)newTemplateAction:(id)sender
{
	NSOpenPanel *backgroundSelectionPanel = [NSOpenPanel openPanel];
	[backgroundSelectionPanel setTitle:@"Choose Template Background"];
	[backgroundSelectionPanel setMessage:@"Choose a PDF file to use with the template."];
	[backgroundSelectionPanel setPrompt:@"Use Selected File"];
	[backgroundSelectionPanel setAllowsMultipleSelection:NO];
	
	[backgroundSelectionPanel beginSheetForDirectory:nil
												file:nil
											   types:[NSArray arrayWithObject:@"pdf"]
									  modalForWindow:[self window]
									   modalDelegate:self
									  didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
										 contextInfo:nil];
	 
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	if(returnCode == NSOKButton)
	{
		NSURL *fileURL = [[panel URLs] objectAtIndex:0];
		
		//[currentProject addTemplateWithBackground:[fileURL path]];	
		
		[NSApp endSheet: panel];
		
		[panel orderOut: self];
		
		[self requestNewTemplateNameForFile:[fileURL path]];
	}
	
}

- (void)requestNewTemplateNameForFile:(NSString*)filePath
{
	NSAlert* alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Please enter a name for the new template."];
	NSButton *createButton = [alert addButtonWithTitle:@"Create Template"];
	NSButton *cancelButton = [alert addButtonWithTitle:@"Cancel"];
	
	NSTextField *nameInputField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 22)];
	[nameInputField setStringValue:[[filePath lastPathComponent] stringByDeletingPathExtension]];
	[alert setAccessoryView:nameInputField];
	
	NSDictionary *context = [[NSDictionary alloc] initWithObjectsAndKeys:
							 nameInputField,@"nameInputField",
							 filePath,@"filePath",
							 createButton,@"createButton",
							 cancelButton,@"cancelButton",
							 nil];
	[nameInputField release];
	
	[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:context];
	[nameInputField selectText:self];		
}

-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSDictionary *contextDict = (NSDictionary*)contextInfo;
	
	if (returnCode == NSAlertFirstButtonReturn) {
		
		NSTextField *nameInputField = [contextDict objectForKey:@"nameInputField"];
		NSString *newTemplateName = [nameInputField stringValue];
		
		for(EthnographerTemplate *template in [currentProject templates])
		{
			if([newTemplateName caseInsensitiveCompare:[template name]] == NSOrderedSame)
			{
				[[alert window] close];
				
				NSAlert* newalert = [[NSAlert alloc] init];
				[newalert setMessageText:[NSString stringWithFormat:@"The template name “%@” already exists. Please use a different name",newTemplateName]];
				NSButton *createButton = [newalert addButtonWithTitle:@"Create Template"];
				NSButton *cancelButton = [newalert addButtonWithTitle:@"Cancel"];
				
				NSTextField *newNameInputField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 22)];
				[newNameInputField setStringValue:newTemplateName];
				[newalert setAccessoryView:newNameInputField];
				
				NSDictionary *context = [[NSDictionary alloc] initWithObjectsAndKeys:
										 newNameInputField,@"nameInputField",
										 [contextDict objectForKey:@"filePath"],@"filePath",
										 createButton,@"createButton",
										 cancelButton,@"cancelButton",
										 nil];
				[newNameInputField release];
				
				[newalert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:context];
				[newNameInputField selectText:self];
				
				[contextDict release];
				[alert release];
				
				return;
			}
		}
		
		NSString *templateFile = [contextDict objectForKey:@"filePath"];
		
		[alert setMessageText:@"Creating template…"];
		NSProgressIndicator *progress = [[NSProgressIndicator alloc] initWithFrame:[nameInputField frame]];
		NSView *accessoryView = [nameInputField superview];
		[nameInputField removeFromSuperview];
		
		[[contextDict objectForKey:@"createButton"] setEnabled:NO];
		[[contextDict objectForKey:@"cancelButton"] setEnabled:NO];
		
		[accessoryView addSubview:progress];
		[progress setIndeterminate:YES];
		[progress startAnimation:self];
		[progress release];
		
		[[plugin printer] saveTemplate:newTemplateName 
						withBackground:templateFile
							 toProject:currentProject];
		
		[currentProject reload];
		
		[templateList reloadData];
		
		int index = 0;
		for(EthnographerTemplate *template in [currentProject templates])
		{
			if([[template name] isEqualToString:newTemplateName])
			{
				[templateList selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
						  byExtendingSelection:NO];
				break;
			}
			index++;
		}
	}
	
	[contextDict release];
	[alert release];
}

- (IBAction)deleteTemplateAction:(id)sender
{
    NSAlert *deleteTemplateAlert = [[NSAlert alloc] init];
    [deleteTemplateAlert setMessageText:[NSString stringWithFormat:@"Are you sure you want to delete the %@ template?",[selectedTemplate name]]];
    [deleteTemplateAlert setInformativeText:@"Deleting the template will prevent any notes taken on printed sheets of the template from being properly displayed."];
	
    NSProgressIndicator *progress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 300, 22)];
    [deleteTemplateAlert setAccessoryView:progress];
    [progress setHidden:YES];
    [progress release];
    
    [deleteTemplateAlert addButtonWithTitle:@"Delete"];
    [deleteTemplateAlert addButtonWithTitle:@"Cancel"];
    
    [deleteTemplateAlert beginSheetModalForWindow:[self window]
                                    modalDelegate:self
                                   didEndSelector:@selector(deleteAlertDidEnd:returnCode:contextInfo:)  
                                      contextInfo:NULL];
    
}


-(void)deleteAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{	
	if (returnCode == NSAlertFirstButtonReturn) {
		
		NSString *templateName = [selectedTemplate name];
		
		[alert setMessageText:@"Deleting template…"];
        [alert setInformativeText:@""];
		//NSProgressIndicator *progress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 300, 22)];
        //[alert setAccessoryView:progress];
        NSProgressIndicator *progress = (NSProgressIndicator*)[alert accessoryView];
        [progress setHidden:NO];
		for(NSButton *button in [alert buttons])
        {
            [button setEnabled:NO];
        }
        
		[progress setIndeterminate:YES];
		[progress startAnimation:self];
		
		[[plugin printer] deleteTemplate:templateName fromProject:currentProject];
		
		[currentProject reload];
		
		[templateList reloadData];
	}
	
	[alert release];
}



- (IBAction)nextPageAction:(id)sender
{
    PDFView *currentPreview = nil;
    if(sender == nextPageButton)
    {
        currentPreview = templatePreview;
    }
    else if(sender == nextSessionPageButton)
    {
        currentPreview = sessionPreview;
    }
    
    if(!currentPreview)
    {
        return;
    }
    
    PDFDocument *doc = [currentPreview document];
	NSUInteger currentIndex = [doc indexForPage:[currentPreview currentPage]];	
	
	if((currentIndex + 1) < [doc pageCount])
	{
		[self showTemplatePage:(currentIndex + 1)];
	}
}

- (IBAction)previousPageAction:(id)sender
{
	
    PDFView *currentPreview = nil;
    if(sender == previousPageButton)
    {
        currentPreview = templatePreview;
    }
    else if(sender == previousSessionPageButton)
    {
        currentPreview = sessionPreview;
    }
    
    if(!currentPreview)
    {
        return;
    }
    
    PDFDocument *doc = [currentPreview document];
	NSInteger currentIndex = [doc indexForPage:[currentPreview currentPage]];	
	
	if((currentIndex - 1) >= 0)
	{
		[self showTemplatePage:(currentIndex - 1)];
	}
}

- (void)showTemplatePage:(NSUInteger)index
{
    PDFView *currentPreview = nil;
    NSButton *nextButton = nil;
    NSButton *previousButton = nil;
    NSTextField *pageField = nil;
    NSInteger tab = [tabView indexOfTabViewItem:[tabView selectedTabViewItem]];
    if(tab == 0)
    {
        currentPreview = templatePreview;
        nextButton = nextPageButton;
        previousButton = previousPageButton;
        pageField = pageLabel;
    }
    else if(tab == 1)
    {
        currentPreview = sessionPreview;
        nextButton = nextSessionPageButton;
        previousButton = previousSessionPageButton;
        pageField = sessionPageLabel;
    }
    
    if(!currentPreview)
    {
        return;
    }
    
    PDFDocument *doc = [currentPreview document];
	PDFPage *currentPage = [currentPreview currentPage];
    
	NSUInteger pageCount = [doc pageCount];
	NSUInteger currentIndex = [doc indexForPage:currentPage];
	
	if((index != currentIndex) && (index < pageCount))
	{
		PDFPage *newPage = [doc pageAtIndex:index];
		[currentPreview goToPage:newPage];
		currentIndex = index;
	}
	
	[nextButton setEnabled:((currentIndex + 1) < pageCount)];
		
	[previousButton setEnabled:(currentIndex > 0)];
	
	[pageField setStringValue:[NSString stringWithFormat:@"Page %u of %u",(currentIndex + 1),pageCount]];
}

- (IBAction)rotateTemplateCCW:(id)sender {
    NSInteger rotation = [selectedTemplate rotationForPdfPage:1];
    [selectedTemplate setRotation:(rotation + 270)];
    [self selectTemplate:selectedTemplate];
    [currentProject performSelectorInBackground:@selector(saveTemplates) withObject:nil];
}

- (IBAction)rotateTemplateCW:(id)sender {
    NSInteger rotation = [selectedTemplate rotationForPdfPage:1];
    [selectedTemplate setRotation:(rotation + 90)];
    [self selectTemplate:selectedTemplate];
    [currentProject performSelectorInBackground:@selector(saveTemplates) withObject:nil];
}


#pragma mark Sessions

- (IBAction)loadSessionAction:(id)sender {
    
    if(self.selectedSessionFile)
    {
         [plugin loadSession:self.selectedSessionFile];   
    }

}

- (IBAction)deleteSessionAction:(id)sender 
{
    NSAlert *deleteTemplateAlert = [[NSAlert alloc] init];
    [deleteTemplateAlert setMessageText:[NSString stringWithFormat:@"Are you sure you want to delete the session \"%@\"?",[[self.selectedSessionFile stringByDeletingLastPathComponent] lastPathComponent]]];
    [deleteTemplateAlert setInformativeText:@"Deleting the permanently delete any associated notes."];
	
    [deleteTemplateAlert addButtonWithTitle:@"Delete"];
    [deleteTemplateAlert addButtonWithTitle:@"Cancel"];
    
    [deleteTemplateAlert beginSheetModalForWindow:[self window]
                                    modalDelegate:self
                                   didEndSelector:@selector(deleteSessionAlertDidEnd:returnCode:contextInfo:)  
                                      contextInfo:NULL];
}

-(void)deleteSessionAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{	
	if (returnCode == NSAlertFirstButtonReturn) {
		
		[alert setMessageText:@"Deleting session…"];
        [alert setInformativeText:@""];
		NSProgressIndicator *progress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 300, 22)];
        [alert setAccessoryView:progress];
		for(NSButton *button in [alert buttons])
        {
            [button setEnabled:NO];
        }
        
        
		[progress setIndeterminate:YES];
		[progress startAnimation:self];
		[progress release];
		
		//[[plugin printer] deleteNoteSession:[self.selectedSessionFile stringByDeletingLastPathComponent] fromProject:currentProject];
		
        [plugin deleteSession:self.selectedSessionFile];
                
        [sessionsList deselectAll:self];
		[sessionsList reloadData];
	}
	
	[alert release];
}

#pragma mark Printing


- (IBAction)printTemplateAction:(id)sender
{
	[[plugin printer] printTemplate:selectedTemplate fromWindow:[self window]];
}

- (IBAction)printControlAction:(id)sender {
    if(selectedControl)
    {
        NSString *controlPS = [[[[plugin controlFiles] objectForKey:selectedControl] stringByDeletingPathExtension] stringByAppendingPathExtension:@"ps"];
        [[plugin printer] printControl:controlPS fromWindow:[self window]];
    }
}


#pragma mark Table View Delegate Methods
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
    if(tableView == templateList)
    {
        return [[currentProject templates] count];  
    }
    else if(tableView == controlsList)
    {
        return [[plugin controlFiles] count];  
    }
    else
    {
        return [[currentProject sessions] count];
    }
	
}

- (id) tableView:(NSTableView*) aTableView objectValueForTableColumn:(NSTableColumn*) tableColumn row:(NSInteger) rowIndex {
    if(aTableView == templateList)
    {
        if(rowIndex < [[currentProject templates] count])
        {
            return [(EthnographerTemplate*)[[currentProject templates] objectAtIndex:rowIndex] name];
        }
        else
        {
            return @"";
        }
    }
    else if(aTableView == controlsList)
    {
        if(rowIndex < [[plugin controlFiles] count])
        {
            return [[[plugin controlFiles] allKeys] objectAtIndex:rowIndex];
        }
        else
        {
            return @"";
        }
    }
	else
    {
        if(rowIndex < [[currentProject sessions] count])
        {
            return [[(NSString*)[[currentProject sessions] objectAtIndex:rowIndex] stringByDeletingLastPathComponent] lastPathComponent];
        }
        else
        {
            return @"";
        }
    }
}

- (BOOL) tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return NO;
}

- (void)selectTemplate:(EthnographerTemplate*)template
{
    selectedTemplate = template;
    
    PDFDocument *selectedTemplateDocument = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:selectedTemplate.background]];
    if(selectedTemplateDocument)
    {
        // Template pdf pages are 1-indexed
        
        int pageIndex;
        for(pageIndex = 0; pageIndex < [selectedTemplateDocument pageCount]; pageIndex++)
        {
            NSUInteger rotation = [selectedTemplate rotationForPdfPage:(pageIndex + 1)];
            [[selectedTemplateDocument pageAtIndex:pageIndex] setRotation:rotation];
        }
        
        
        
        [templatePreview setDocument:selectedTemplateDocument];
        [self showTemplatePage:0];
        [printTemplateButton setEnabled:YES];
        [deleteTemplateButton setEnabled:YES];
        [selectedTemplateDocument release];
        return;
    }
}

- (void)selectSessionFile:(NSString*)sessionFile loadPreview:(BOOL)loadPreview
{
    self.selectedSessionFile = sessionFile;
    if(sessionFile)
    {
        NSError *err = nil;
        NSString *previewPDF = nil;
        NSStringEncoding enc = NSUTF8StringEncoding;
        NSString *xmlString = [[NSString alloc] initWithContentsOfFile:self.selectedSessionFile usedEncoding:&enc error:&err];
        if([xmlString rangeOfString:@"modified=\"true\""].location == NSNotFound)
        {
            NSDate *latestDate = (NSDate*)[NSDate distantPast];
            NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self.selectedSessionFile stringByDeletingLastPathComponent] error:&err];
            for(NSString *item in items)
            {
                if([[item pathExtension] caseInsensitiveCompare:@"pdf"] == NSOrderedSame)
                {
                    NSString *pdf = [[self.selectedSessionFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:item];
                    NSDate *modDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:pdf error:&err] fileModificationDate];
                    if([latestDate compare:modDate] == NSOrderedAscending)
                    {
                        latestDate = modDate;
                        previewPDF = pdf;
                    }
                }
            }
        }
        
        if(!previewPDF && loadPreview)
        {
            [[plugin printer] updateSessionPdf:[self.selectedSessionFile stringByDeletingLastPathComponent] inProject:currentProject];
        }
        
        if(previewPDF)
        {
            [previewLoadingProgress setHidden:YES];
            [previewLoadingProgress setUsesThreadedAnimation:NO];
            [previewLoadingProgress stopAnimation:self];
            
            PDFDocument *selectedTemplateDocument = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:previewPDF]];
            if(selectedTemplateDocument)
            {
                [sessionPreview setHidden:NO];
                [sessionPreview setDocument:selectedTemplateDocument];
                [self showTemplatePage:0];
                [selectedTemplateDocument release];
                return;
            }
        }
    }
    else
    {
        self.selectedSessionFile = nil;
    }
    
    if(loadPreview)
    {
        [previewLoadingProgress setHidden:NO];
        [previewLoadingProgress setUsesThreadedAnimation:YES];
        [previewLoadingProgress startAnimation:self];
    }
    else
    {
        [previewLoadingProgress setHidden:YES];
        [previewLoadingProgress setUsesThreadedAnimation:NO];
        [previewLoadingProgress stopAnimation:self];
    }
    
    [sessionPreview setHidden:YES];
    [sessionPreview setDocument:nil];
    [sessionPageLabel setStringValue:@""];

}

- (void)selectControl:(NSString*)control
{
    selectedControl = control;
    if(selectedControl)
    {                    
        NSString *previewPDF = [[plugin controlFiles] objectForKey:selectedControl];
        
        PDFDocument *selectedControlDocument = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:previewPDF]];
        if(selectedControlDocument)
        {
            [controlsPrintButton setEnabled:YES];
            [controlsPreview setHidden:NO];
            [controlsPreview setDocument:selectedControlDocument];
            [selectedControlDocument release];
            return;
        }
    }
    else
    {
        self.selectedSessionFile = nil;
    }
    
    [controlsPrintButton setEnabled:NO];
    [controlsPreview setHidden:YES];
    [controlsPreview setDocument:nil];
    
}


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    if([aNotification object] == templateList)
    { 
        NSUInteger index = [templateList selectedRow];
        
        if(index < [[currentProject templates] count])
        {
            selectedTemplate = [[currentProject templates] objectAtIndex:index];
            
            PDFDocument *selectedTemplateDocument = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:selectedTemplate.background]];
            if(selectedTemplateDocument)
            {
                // Template pdf pages are 1-indexed
                
                int pageIndex;
                for(pageIndex = 0; pageIndex < [selectedTemplateDocument pageCount]; pageIndex++)
                {
                    NSUInteger rotation = [selectedTemplate rotationForPdfPage:(pageIndex + 1)];
                    [[selectedTemplateDocument pageAtIndex:pageIndex] setRotation:rotation];
                }
                

                
                [templatePreview setDocument:selectedTemplateDocument];
                [self showTemplatePage:0];
                [printTemplateButton setEnabled:YES];
                [deleteTemplateButton setEnabled:YES];
                [selectedTemplateDocument release];
                return;
            }
        }
        
        [printTemplateButton setEnabled:NO];
        [deleteTemplateButton setEnabled:NO];
        [templatePreview setDocument:nil];
        [pageLabel setStringValue:@""];
    }
    else if([aNotification object] == controlsList)
    { 
        NSUInteger index = [controlsList selectedRow];
        
        if(index < [[plugin controlFiles] count])
        {
            [self selectControl:[[[plugin controlFiles] allKeys] objectAtIndex:index]];
        }
        else
        {
            [self selectControl:nil];
        }
    }
    else
    {
        NSUInteger index = [sessionsList selectedRow];
        
        if(index < [[currentProject sessions] count])
        {
            [self selectSessionFile:[[currentProject sessions] objectAtIndex:index] loadPreview:YES];
        }
        else
        {
            [self selectSessionFile:nil loadPreview:NO];
        }
    }

}

@end
