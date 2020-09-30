//
//  PluginConfigurationView.m
//  Annotation
//
//  Created by Adam Fouse on 9/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PluginConfigurationView.h"
#import "PluginConfiguration.h"
#import "PluginParameter.h"
#import "PluginAnnotationSet.h"
#import "PluginDataSet.h"
#import "AnnotationDataAnalysisPlugin.h"
#import "AnnotationCategoryFilter.h"
#import "TimeCodedData.h"
#import "AppController.h"
#import "AnnotationDocument.h"

@implementation PluginConfigurationView

- (id)initWithPluginConfiguration:(PluginConfiguration*)theConfiguration {
	
	AnnotationDataAnalysisPlugin *plugin = [theConfiguration plugin];
	
	CGFloat wmax = 0;
	CGFloat hmax = 0;
	CGFloat border = 18;
	CGFloat separation = 4;
	CGFloat dataHeight = 30;
	CGFloat buttonHeight = 32;
	CGFloat descriptionHeight = 50;
	CGFloat inputHeight = buttonHeight * 2 + 3;
	
	CGFloat totalWidth = 300;
	CGFloat totalHeight = 
	([[plugin dataParameters] count] * dataHeight)
    + ([[plugin annotationSets] count] * dataHeight)
	+ ([[plugin inputParameters] count] * inputHeight) 
	+ (border * 3)
	+ (buttonHeight)
	+ (dataHeight + descriptionHeight + 10);
	
    self = [super initWithFrame:NSMakeRect(0,0,totalWidth,totalHeight)];
    if (self) {
		configuration = theConfiguration;
		
		NSArray *dataParameters = [plugin dataParameters];
		NSArray *inputParameters = [plugin inputParameters];
        NSArray *annotationSetParameters = [plugin annotationSets];
		
		CGFloat currentHeight = totalHeight - dataHeight;
		
		// Calculate label sizes
		for(PluginDataSet* parameter in dataParameters)
		{
			NSSize size = [parameter.name sizeWithAttributes:nil];
			if(size.width > wmax)
				wmax = size.width;
			if(size.height > hmax)
				hmax = size.height;
		}
		for(PluginParameter* parameter in inputParameters)
		{
			NSSize size = [[parameter parameterName] sizeWithAttributes:nil];
			if(size.width > wmax)
				wmax = size.width;
			if(size.height > hmax)
				hmax = size.height;
		}
        for(PluginAnnotationSet* parameter in annotationSetParameters)
        {
            NSSize size = [[parameter annotationSetName] sizeWithAttributes:nil];
            if(size.width > wmax)
                wmax = size.width;
            if(size.height > hmax)
                hmax = size.height;
        }
		wmax += 12;
        if(hmax == 0) hmax = 15;
		CGFloat buttonWidth = totalWidth - wmax - (border * 2);
		
		// Create description field and label
		NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(border,currentHeight,totalWidth - border*2,hmax)];
		[label setStringValue:@"Configuration Description:"];
		[label setEditable:NO];
		[label setDrawsBackground:NO];
		[label setBordered:NO];
		[label setAlignment:NSLeftTextAlignment];
		[self addSubview:label];
		[label release];
		
		currentHeight -= descriptionHeight;
		
		NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(border,currentHeight,totalWidth - border*2,descriptionHeight - 6)];
		NSTextView *descriptionArea = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,totalWidth - border*2,descriptionHeight - 6)];
		[descriptionArea setRichText:NO];
		NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSContinuouslyUpdatesValueBindingOption];
		[descriptionArea bind:@"value" toObject:configuration withKeyPath:@"description" options:options];
		[scrollView setDocumentView:descriptionArea];
		[scrollView setBorderType:NSBezelBorder];
		[self addSubview:scrollView];
		[descriptionArea release];
		[scrollView release];
		
		currentHeight -= 10;
		
        if([dataParameters count]) {
            NSBox *lineone = [[NSBox alloc] initWithFrame:NSMakeRect(border,currentHeight,totalWidth - (border * 2), 1)];
            [lineone setBoxType:NSBoxSeparator];
            [self addSubview:lineone];
            [lineone release];
        }
		
		currentHeight -= buttonHeight;
		
		NSInteger index = 0;
		for(PluginDataSet* parameter in dataParameters)
		{
			label = [[NSTextField alloc] initWithFrame:NSMakeRect(border,currentHeight,wmax,hmax)];
			[label setStringValue:[parameter.name stringByAppendingString:@":"]];
			[label setEditable:NO];
			[label setDrawsBackground:NO];
			[label setBordered:NO];
			[label setAlignment:NSRightTextAlignment];
			[self addSubview:label];
			[label release];
			
			NSPopUpButton *selection = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(border + wmax + separation,currentHeight - 6,buttonWidth,26)];
			for(TimeCodedData* data in [[AppController currentDoc] dataSetsOfClass:[plugin dataVariableClass]])
			{
				[selection addItemWithTitle:[data name]];
				[[selection lastItem] setRepresentedObject:data];
				if(data == [configuration dataSetForIndex:index])
				{
					[selection selectItem:[selection lastItem]];
				}
			}
			[selection setAction:@selector(changeDataSet:)];
			[selection setTarget:self];
			[selection setTag:index];
			[self addSubview:selection];
			[selection release];
			index++;
			currentHeight -= dataHeight;
		}
		
		currentHeight += (dataHeight - 19);
        
        if([inputParameters count]) {
            NSBox *line = [[NSBox alloc] initWithFrame:NSMakeRect(border,currentHeight,totalWidth - (border * 2), 1)];
            [line setBoxType:NSBoxSeparator];
            [self addSubview:line];
            [line release];
            currentHeight -= 23;
        }
		
		
		index = 0;
		for(PluginParameter* param in inputParameters)
		{
			NSString *input = [param parameterName];
			NSSize size = [input sizeWithAttributes:nil];
			
			label = [[NSTextField alloc] initWithFrame:NSMakeRect(border,currentHeight,size.width + 18,hmax)];
			[label setStringValue:[input stringByAppendingString:@":"]];
			NSLog(@"Label: %@",[label stringValue]);
			[label setEditable:NO];
			[label setDrawsBackground:NO];
			[label setBordered:NO];
			[label setAlignment:NSLeftTextAlignment];
			[self addSubview:label];
			[label release];
			
			currentHeight -= 3;
			
			NSTextField *valueField = [[NSTextField alloc] initWithFrame:NSMakeRect(border + size.width + 18,currentHeight,100,22)];
			[valueField setEditable:YES];
			[valueField setContinuous:YES];
			NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSContinuouslyUpdatesValueBindingOption];
			[valueField bind:@"value" toObject:[configuration inputValueForIndex:index] withKeyPath:@"parameterValue" options:options];
			[self addSubview:valueField];
			[valueField release];
			
			currentHeight -= buttonHeight;
			
			NSSlider *slider = [[NSSlider alloc] initWithFrame:NSMakeRect(border,currentHeight,totalWidth - (border*2),25)];
			[slider setMinValue:[param minValue]];
			[slider setMaxValue:[param maxValue]];
			[slider setNumberOfTickMarks:5];
			[slider bind:@"value" toObject:[configuration inputValueForIndex:index] withKeyPath:@"parameterValue" options:nil];
			[self addSubview:slider];
			[slider release];
			 
			currentHeight -= buttonHeight;
			
			index++;
		}
		
        
        if([annotationSetParameters count]) {
            NSBox *line = [[NSBox alloc] initWithFrame:NSMakeRect(border,currentHeight,totalWidth - (border * 2), 1)];
            [line setBoxType:NSBoxSeparator];
            [self addSubview:line];
            [line release];
            currentHeight -= 23;
        }
        
        index = 0;
        for(PluginAnnotationSet* param in annotationSetParameters)
        {
            label = [[NSTextField alloc] initWithFrame:NSMakeRect(border,currentHeight,wmax,hmax)];
            [label setStringValue:[param.annotationSetName stringByAppendingString:@":"]];
            [label setEditable:NO];
            [label setDrawsBackground:NO];
            [label setBordered:NO];
            [label setAlignment:NSRightTextAlignment];
            [self addSubview:label];
            [label release];
            
            NSPopUpButton *selection = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(border + wmax + separation,currentHeight - 6,buttonWidth,26)];
            for(AnnotationCategory* category in [[AppController currentDoc] categories])
            {
                [selection addItemWithTitle:[category name]];
                [[selection lastItem] setRepresentedObject:category];
                if([[(AnnotationCategoryFilter*)[[configuration annotationSetForIndex:index] annotationFilter] visibleCategories] containsObject:category])
                {
                    [selection selectItem:[selection lastItem]];
                }
            }
            [selection setAction:@selector(changeAnnotationSet:)];
            [selection setTarget:self];
            [selection setTag:index];
            [self addSubview:selection];
            [selection release];
            index++;
            currentHeight -= dataHeight;
        }
        
        
		okayButton = [[NSButton alloc] initWithFrame:NSMakeRect(totalWidth - border - 121,border,121,32)];
		[okayButton setBezelStyle:NSRoundedBezelStyle];
		[okayButton setTitle:@"Run Analysis"];
		[okayButton setKeyEquivalent:@"\r"];
		[okayButton setAction:@selector(runPlugin:)];
		[okayButton setTarget:configuration];
		[self addSubview:okayButton];
		[okayButton release];
		
		cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(totalWidth - border - 121 - 96,border,96,32)];		
		[cancelButton setBezelStyle:NSRoundedBezelStyle];
		[cancelButton setTitle:@"Cancel"];
		[cancelButton setAction:@selector(closeWindow:)];
		[cancelButton setTarget:self];
		[self addSubview:cancelButton];
		[cancelButton release];
		
		[descriptionArea selectAll:self];
    }
    return self;
}

- (IBAction)closeWindow:(id)sender
{
	[[self window] close];
}

- (void)setRunButtonsHidden:(BOOL)hideButtons
{
	if([okayButton isHidden] == hideButtons)
	{
		return;
	}
	
	[okayButton setHidden:hideButtons];
	[cancelButton setHidden:hideButtons];
	
	NSSize size = [self frame].size;
	
	if(hideButtons)
	{
		[self setBoundsOrigin:NSMakePoint(0.0, 32.0)];
		size.height = size.height - 32;
	}
	else
	{
		[self setBoundsOrigin:NSMakePoint(0.0, 0.0)];
		size.height = size.height + 32;
	}
	
	[self setFrameSize:size];

}

- (IBAction)changeDataSet:(id)sender
{
	NSInteger index = [sender tag];
	[configuration setDataSet:[[sender selectedItem] representedObject] forIndex:index];	
}

- (IBAction)changeAnnotationSet:(id)sender
{
    NSInteger index = [sender tag];
    AnnotationCategory *category = (AnnotationCategory*)[[sender selectedItem] representedObject];
    AnnotationCategoryFilter *filter = [[AnnotationCategoryFilter alloc] initForCategories:@[category]];
    [configuration setAnnotationFilter:filter forIndex:index];
    [filter release];
}

@end
