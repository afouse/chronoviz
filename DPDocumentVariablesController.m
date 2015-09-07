//
//  DPDocumentVariablesController.m
//  ChronoViz
//
//  Created by Adam Fouse on 7/29/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPDocumentVariablesController.h"
#import "AnnotationDocument.h"

@implementation DPDocumentVariablesController

@synthesize annotationDocument;

- (id)initForDocument:(AnnotationDocument*)theDocument
{
	if(![super initWithWindowNibName:@"DocumentVariablesWindow"])
		return nil;
	
	annotationDocument = theDocument;
	
	variables = [annotationDocument documentVariables];
	
	return self;
}

-(IBAction)addVariable:(id)sender
{
	[variables setObject:@"New Value" forKey:@"New Variable"];
	[variablesTableView reloadData];
	[variablesTableView editColumn:0 row:([variables count] - 1) withEvent:nil select:YES];
}

-(IBAction)removeVariable:(id)sender
{
	id key = [[variables allKeys] objectAtIndex:[[variablesTableView selectedRowIndexes] firstIndex]];
	[variables removeObjectForKey:key];
	[variablesTableView reloadData];
}

-(IBAction)showWindow:(id)sender
{
	[variablesTableView reloadData];
	[super showWindow:sender];
}

#pragma mark Table View Delegate Methods
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
	return [variables count];
}

- (id) tableView:(NSTableView*) aTableView objectValueForTableColumn:(NSTableColumn*) tableColumn row:(NSInteger) rowIndex {
	NSString *identifier = [tableColumn identifier];
	NSString *key = [[variables allKeys] objectAtIndex:rowIndex];
	if([identifier isEqualToString:@"Key"])
	{
		return key;
	}
	else if([identifier isEqualToString:@"Value"])
	{
		return [variables objectForKey:key];
	}
	else {
		return nil;
	}
	
}

- (void)    tableView:(NSTableView*) tv setObjectValue:(id) val 
	   forTableColumn:(NSTableColumn*) aTableColumn row:(NSInteger) rowIndex
{
	NSString *key = [[variables allKeys] objectAtIndex:rowIndex];
    if([[aTableColumn identifier] isEqualToString:@"Key"])
    {
		NSString *object = [variables objectForKey:key];
		[variables setObject:object forKey:val];
		[variables removeObjectForKey:key];
    }
	else if([[aTableColumn identifier] isEqualToString:@"Value"])
    {
		[variables setObject:val forKey:key];
    }
	[annotationDocument saveDocumentProperties];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if(([variablesTableView selectedRow] > -1) && ([variablesTableView selectedRow] < [variables count]))
	{	
		[removeVariableButton setEnabled:YES];
	}
	else
	{
		[removeVariableButton setEnabled:NO];
	}
}

@end
