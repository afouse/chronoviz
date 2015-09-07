//
//  DPExportPDF.m
//  DataPrism
//
//  Created by Adam Fouse on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DPExportPDF.h"
#import "AppController.h"
#import "Annotation.h"
#import "AnnotationCategory.h"
#import "AnnotationDocument.h"
#import "MultiTimelineView.h"
#import "TimelineView.h"
#import <QTKit/QTKit.h>

@implementation DPExportPDF

-(NSString*)name
{
	return @"Image File";
}

- (BOOL)export:(AnnotationDocument*)doc;
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	[savePanel setCanCreateDirectories:YES];
	[savePanel setTitle:@"Image Export"];
	[savePanel setPrompt:@"Export"];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"png"]];
	[savePanel setExtensionHidden:NO];
	[savePanel setCanSelectHiddenExtension:YES];
	
	NSRect viewFrame = NSMakeRect(0, 0, 350, 100);
	NSRect buttonFrame = NSMakeRect(140, 16, 180, 26);
	NSRect labelFrame = NSMakeRect(0, 22, 138, 17);
	NSRect instructionsFrame = NSMakeRect(10,50,330,40);
	
	NSView *view = [[NSView alloc] initWithFrame:viewFrame];
	
	NSPopUpButton *button = [[NSPopUpButton alloc] initWithFrame:buttonFrame pullsDown:NO];
	
	NSTextField *label = [[NSTextField alloc] initWithFrame:labelFrame];
	[label setStringValue:@"View to export:"];
	[label setEditable:NO];
	[label setDrawsBackground:NO];
	[label setBordered:NO];
	[label setAlignment:NSRightTextAlignment];
	
	NSTextField *instructions = [[NSTextField alloc] initWithFrame:instructionsFrame];
	[instructions setStringValue:@"Select one of the current views to export."];
	[instructions setEditable:NO];
	[instructions setDrawsBackground:NO];
	[instructions setBordered:NO];
	[instructions setAlignment:NSCenterTextAlignment];
	
	[view addSubview:instructions];
	[view addSubview:button];
	[view addSubview:label];
	
	[instructions release];
	[label release];
	[button release];
	
	for(id<AnnotationView> view in [[AppController currentApp] annotationViews])
	{
		if(view == [[AppController currentApp] timelineView])
		{
			int timelineIndex = 1;
			for(TimelineView *timeline in [(MultiTimelineView*)view timelines])
			{
                if([[timeline label] length] && ![button itemWithTitle:[timeline label]])
                {
                    [button addItemWithTitle:[timeline label]];
                }
                else
                {
                    [button addItemWithTitle:[NSString stringWithFormat:@"Timeline %i",timelineIndex]];
                }
				[[button lastItem] setRepresentedObject:timeline];
				timelineIndex++;
			}
		}
//		[button addItemWithTitle:@"Timeline"];
//		[[button lastItem] setRepresentedObject:view];
	}
	
	[savePanel setAccessoryView:view];
	
	if([savePanel runModal] == NSOKButton) {
		
		//NSString *file = [savePanel filename];	
		NSObject<AnnotationView> *selectedView = [[button selectedItem] representedObject];
		
		if([selectedView isKindOfClass:[NSView class]])
		{
//            if([selectedView isKindOfClass:[TimelineView class]])
//            {
//                [(TimelineView*)selectedView setWhiteBackground:YES];
//                [(TimelineView*)selectedView redrawAllSegments];
//            }
//            
			NSView *theView = (NSView*)selectedView;
			
//			NSRect r = [(NSView*)selectedView bounds];
//            NSData *data = [(NSView*)selectedView dataWithPDFInsideRect:r];
//            
//            [data writeToFile:[savePanel filename] atomically:YES];
			
			
			
			CGContextRef    context = NULL;
			CGColorSpaceRef colorSpace;
			int bitmapByteCount;
			int bitmapBytesPerRow;
			
			int pixelsHigh = (int)[[theView layer] bounds].size.height;
			int pixelsWide = (int)[[theView layer] bounds].size.width;
			
			bitmapBytesPerRow   = (pixelsWide * 4);
			bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
			
			colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
			
			context = CGBitmapContextCreate (NULL,
											 pixelsWide,
											 pixelsHigh,
											 8,
											 bitmapBytesPerRow,
											 colorSpace,
											 kCGImageAlphaPremultipliedLast);
			if (context== NULL)
			{
				NSLog(@"Failed to create context.");
				return NO;
			}
			
			CGColorSpaceRelease( colorSpace );
			
			if([theView isKindOfClass:[TimelineView class]])
			{
                [(TimelineView*)theView setShowPlayhead:NO];
                [(TimelineView*)theView setWhiteBackground:YES];
                [[(TimelineView*)theView layer] setNeedsDisplay];
                [(TimelineView*)theView redrawAllSegments];
				[[(TimelineView*)theView layer] renderInContext:context];
                
                CGContextSetStrokeColorWithColor(context, CGColorGetConstantColor(kCGColorBlack));
                CGContextStrokeRectWithWidth(context, CGRectMake(0.5,0.5,pixelsWide - 1.0,pixelsHigh - 1.0),1.0);
                
                [(TimelineView*)theView setShowPlayhead:YES];
                [(TimelineView*)theView setWhiteBackground:NO];
                [[(TimelineView*)theView layer] setNeedsDisplay];
                [(TimelineView*)theView redrawAllSegments];
			}
			else
			{
				[[theView layer] renderInContext:context];
			}
			
			CGImageRef img = CGBitmapContextCreateImage(context);
			NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:img];
			CFRelease(img);
			
			
			//NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
			NSData *imageData = [bitmap representationUsingType:NSPNGFileType properties:nil];
			[imageData writeToFile:[savePanel filename] atomically:NO];
			
			[bitmap release];
			
			
		}
		

		
		return YES;
	}
	else
	{
		return NO;
	}
}

@end
