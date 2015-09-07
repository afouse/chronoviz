//
//  AnnotationQuickEntry.h
//  DataPrism
//
//  Created by Adam Fouse on 4/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
@class Annotation;
@class AnnotationCategory;
@class MAAttachedWindow;
@class TimelineView;

@interface AnnotationQuickEntry : NSObject <NSTextViewDelegate> {

	MAAttachedWindow *hoverWindow;
	IBOutlet NSView *quickEntryView;
	IBOutlet NSOutlineView *categoriesView;
	IBOutlet NSTextView* annotationTextField;
	
	QTTime currentTime;
	
	id actionTarget;
	SEL actionSelector;
	
	BOOL typeSelect;
	
	NSMutableArray *shortcuts;
	
}

- (void)displayQuickEntryWindowAtTime:(QTTime)time inTimeline:(TimelineView*)timeline;
- (void)displayQuickEntryWindowAtTime:(QTTime)time inTimeline:(TimelineView*)timeline forCategory:(AnnotationCategory*)category;
- (void)cancelQuickEntry;

- (void)setEntryTarget:(id)target;
- (void)setEntrySelector:(SEL)selector;

@end
