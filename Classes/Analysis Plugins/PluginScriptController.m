//
//  PluginScriptController.m
//  Annotation
//
//  Created by Adam Fouse on 11/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PluginScriptController.h"
#import "PluginScript.h"
#import "PluginConfigurationView.h"
#import "PluginConfiguration.h"
#import "AnnotationDataAnalysisPlugin.h"
#import "PluginManager.h"

@implementation PluginScriptController

- (id)init
{
	if(![super initWithWindowNibName:@"PluginScript"])
		return nil;
	
	currentScript = nil;
	return self;
}

- (void)windowDidLoad
{
	[scriptsButton removeAllItems];
	NSArray *scripts = [[PluginManager defaultPluginManager] pluginScripts];
	for(PluginScript* script in scripts)
	{
		[scriptsButton addItemWithTitle:[script name]];
		[[scriptsButton lastItem] setRepresentedObject:script];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(saveScript:)
												 name:NSWindowWillCloseNotification
											   object:[self window]];
}

- (IBAction)showWindow:(id)sender
{
	[super showWindow:sender];
	NSArray *scripts = [[PluginManager defaultPluginManager] pluginScripts];
	if([scripts count] == 0)
	{
		[self newScript:self];
	}
	else
	{
		[self selectScript:self];
	}
}

-(IBAction)newScript:(id)sender
{
	NSAlert* alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Please enter a name for the new script."];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	
	nameInputField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 22)];
	[nameInputField setStringValue:@"New Script"];
	[alert setAccessoryView:nameInputField];
	
	//[[alert window] makeFirstResponder:nameInputField];
	
	[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	[nameInputField selectText:self];
}

-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if(nameInputField)
	{
		if (returnCode == NSAlertFirstButtonReturn) {
			PluginScript *script = [[PluginScript alloc] init];
			[script setName:[nameInputField stringValue]];
			[[PluginManager defaultPluginManager] addPluginScript:script];
			[scriptsButton addItemWithTitle:[script name]];
			[[scriptsButton lastItem] setRepresentedObject:script];
			[scriptsButton selectItem:[scriptsButton lastItem]];
			[self selectScript:self];
		}
		[alert release];
		[nameInputField release];
		nameInputField = nil;
	}
	else if(pluginSelectionButton)
	{
		if (returnCode == NSAlertFirstButtonReturn) {
			Class PluginClass = [[[pluginSelectionButton selectedItem] representedObject] class];
			AnnotationDataAnalysisPlugin *plugin = [[PluginClass alloc] init];
			
			PluginConfiguration *configuration = [[PluginConfiguration alloc] initWithPlugin:plugin];
			[[currentScript pluginConfigurations] addObject:configuration];
			[pluginConfigurationsView reloadData];
			
			[self saveScript:self];
		}
		[alert release];
		[pluginSelectionButton release];
		pluginSelectionButton = nil;
	}

}

-(IBAction)selectScript:(id)sender
{
	[self saveScript:self];
	
	currentScript = (PluginScript*)[[scriptsButton selectedItem] representedObject];
	
	[pluginConfigurationsView deselectAll:self];
	[pluginConfigurationsView reloadData];
	
	[addConfigurationButton setEnabled:YES];
}

-(IBAction)deleteScript:(id)sender
{
	PluginScript *scriptToDelete = currentScript;
	
	[scriptsButton removeItemAtIndex:[scriptsButton indexOfSelectedItem]];
	[self selectScript:self];
	
	[[PluginManager defaultPluginManager] deletePluginScript:scriptToDelete];
}

-(IBAction)saveScript:(id)sender
{
	if(currentScript)
	{
		[[PluginManager defaultPluginManager] saveScript:currentScript];
	}
}

-(IBAction)runScript:(id)sender
{
	for(PluginConfiguration *config in [currentScript pluginConfigurations])
	{
		BOOL result = [config runPlugin:self];
		if(!result)
		{
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:[NSString stringWithFormat:@"Plugin script failed while running plugin %@",[[config plugin] displayName]]];
			[alert runModal];
			return;
		}
	}
}

-(IBAction)addConfiguration:(id)sender
{
	NSAlert* alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Please select the plugin you want to use."];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	
	pluginSelectionButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 300, 22)];
	
	NSArray* plugins = [[PluginManager defaultPluginManager] plugins];
	for(AnnotationDataAnalysisPlugin* plugin in plugins)
	{
		[pluginSelectionButton addItemWithTitle:[plugin displayName]];
		[[pluginSelectionButton lastItem] setRepresentedObject:plugin];
	}
	
	[alert setAccessoryView:pluginSelectionButton];
	
	[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	
}

-(IBAction)removeConfiguration:(id)sender
{
	[[currentScript pluginConfigurations] removeObjectAtIndex:[pluginConfigurationsView selectedRow]];
	[pluginConfigurationsView deselectAll:self];
	[pluginConfigurationsView reloadData];
	
	[[PluginManager defaultPluginManager] saveScript:currentScript];
}

//Based on the new content view frame, calculate the window's new frame
-(NSRect)newFrameForConfigurationView:(PluginConfigurationView *)view {
    NSWindow *window = [self window];
    NSRect newFrameRect = [window frame];
    NSRect oldFrameRect = [window frame];
    
	CGFloat heightDiff = [view frame].size.height - [configurationView frame].size.height;
	
	newFrameRect.size.height = oldFrameRect.size.height + heightDiff;	
	
	NSSize newSize = newFrameRect.size;
    NSSize oldSize = oldFrameRect.size;
    
    NSRect frame = [window frame];
    frame.size = newSize;
    frame.origin.y -= (newSize.height - oldSize.height);
    
    return frame;
}

#pragma mark Table View Delegate Methods
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
	if(currentScript)
	{
		return [[currentScript pluginConfigurations] count];
	}
	else
	{
		return 0;
	}
}

- (id) tableView:(NSTableView*) aTableView objectValueForTableColumn:(NSTableColumn*) tableColumn row:(NSInteger) rowIndex {
	return [NSString stringWithFormat:@"%i. %@",(rowIndex + 1),[[[[currentScript pluginConfigurations] objectAtIndex:rowIndex] plugin] displayName]];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	return NO;
}


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	// The script shouldn't need saving for every selection change as long as it's saved before
	// the active script is changed or the window is closed.
	//[self saveScript:self];
	
	if([pluginConfigurationsView selectedRow] < 0)
	{
		[configurationView setHidden:YES];
		[removeConfigurationButton setEnabled:NO];
		return;
	}
	
	PluginConfiguration *configuration = [[currentScript pluginConfigurations] objectAtIndex:[pluginConfigurationsView selectedRow]];
	PluginConfigurationView *view = [[PluginConfigurationView alloc] initWithPluginConfiguration:configuration];
	[view setRunButtonsHidden:YES];
    
	//[configurationView setHidden:NO];
	NSRect oldViewFrame = [configurationView frame];
	NSRect newViewFrame = [view frame];
	newViewFrame.origin.x = oldViewFrame.origin.x;
	newViewFrame.origin.y = oldViewFrame.origin.y;
	[view setFrame:newViewFrame];
	
    NSRect newFrame = [self newFrameForConfigurationView:view];
	
    // Using an animation grouping because we may be changing the duration
    [NSAnimationContext beginGrouping];
    
    // With the shift key down, do slow-mo animation
    if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
        [[NSAnimationContext currentContext] setDuration:1.0];
    
    // Call the animator instead of the view / window directly
    //[[[[self window] contentView] animator] replaceSubview:configurationView with:view];
    [[[self window] animator] setFrame:newFrame display:YES];
//	[[configurationView animator] setHidden:YES];
	[[[configurationView superview] animator] replaceSubview:configurationView with:view];
	
    [NSAnimationContext endGrouping];
		
	[view release];
	configurationView = view;
	
	[removeConfigurationButton setEnabled:YES];
	
}


@end
