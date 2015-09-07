//
//  AnnotationPlaybackControllerView.m
//  ChronoViz
//
//  Created by Adam Fouse on 7/30/12.
//
//

#import "AnnotationPlaybackControllerView.h"
#import "Annotation.h"
#import "AppController.h"

@implementation AnnotationPlaybackControllerView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

//- (BOOL)resignFirstResponder {
//    return NO;
//}

- (void)keyDown:(NSEvent *)event
{

        AppController *mAppController = [AppController currentApp];
		
		unsigned short theKey = [event keyCode];
		//NSLog(@"AFMovieView KeyDown %i",theKey);
		if(theKey == 123) // Left Arrow
		{
			[mAppController stepOneFrameBackward:self];
		} else if(theKey == 124) // Right Arrow
		{
			[mAppController stepOneFrameForward:self];
		} else if(theKey == 126) // Up Arrow
		{
			[mAppController stepBack:self];
		} else if(theKey == 125) // Down Arrow
		{
			[mAppController stepForward:self];
		} else if(theKey == 49) // Space Bar
		{
			[mAppController togglePlay:self];
		}
//        else if(theKey == 51) // Backspace
//		{
//			if([mAppController selectedAnnotation])
//			{
//				NSAlert *confirmation = [[NSAlert alloc] init];
//				[confirmation setMessageText:@"Are you sure you want to delete the currently selected annotation?"];
//				[[confirmation addButtonWithTitle:@"Delete"] setKeyEquivalent:@""];
//				[[confirmation addButtonWithTitle:@"Cancel"] setKeyEquivalent:@"\r"];
//				
//				NSInteger result = [confirmation runModal];
//				
//				if(result == NSAlertFirstButtonReturn)
//				{
//					[mAppController removeCurrentAnnotation:self];
//				}
//                
//                [confirmation release];
//			}
//            
//		}
//		else {
//			if([[NSUserDefaults standardUserDefaults] integerForKey:AFAnnotationShortcutActionKey] == AFCategoryShortcutEditor)
//			{
//				AnnotationCategory *category = [[AnnotationDocument currentDocument] annotationCategoryForKeyEquivalent:[event characters]];
//				if(category)
//				{
//					[mAppController showAnnotationQuickEntryForCategory:category];
//				}
//			}
//			else if([event isARepeat] && lastAddedAnnotation &&
//                    ([lastAddedAnnotation category] == [[AnnotationDocument currentDocument] annotationCategoryForKeyEquivalent:[event characters]]))
//			{
//				[lastAddedAnnotation setIsDuration:YES];
//				[lastAddedAnnotation setEndTime:[mAppController currentTime]];
//			}
//			else
//			{
//				lastAddedAnnotation = [[AnnotationDocument currentDocument] addAnnotationForCategoryKeyEquivalent:[event characters]];
//			}
//			if(!lastAddedAnnotation)
//			{
//				[super keyDown:event];
//			}		
//		}
}

#pragma mark AnnotationView Methods

-(void)addAnnotation:(Annotation*)annotation
{
	//[annotations addObject:annotation];
	//[tableView reloadData];
}

-(void)addAnnotations:(NSArray*)array
{
	//[annotations addObjectsFromArray:array];
	//[tableView reloadData];
}

-(void)removeAnnotation:(Annotation*)annotation
{
	//[annotations removeObject:annotation];
	//[tableView reloadData];
}

-(void)updateAnnotation:(Annotation*)annotation
{
	//[tableView reloadData];
}

-(void)setAnnotationFilter:(AnnotationFilter*)filter
{
	//	annotationFilter = [filter retain];
	//	filterAnnotations = YES;
	//	[self redrawAllSegments];
}

-(AnnotationFilter*)annotationFilter
{
	return nil;
}

-(NSArray*)dataSets
{
	return [NSArray array];
}


-(void)update
{

}



@end
