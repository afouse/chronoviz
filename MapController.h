//
//  MapController.h
//  Annotation
//
//  Created by Adam Fouse on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MapView;
@class SpatialAnnotationOverlay;

@interface MapController : NSWindowController<NSToolbarDelegate> {

	IBOutlet MapView *mapView;
	IBOutlet NSToolbar *toolbar;
	
	IBOutlet NSPanel *dataSetsPanel;
	IBOutlet NSTableView *dataSetsTable;
	IBOutlet NSButton *showPathsButton;	
	
	NSMutableArray *geoDataSets;
	
	NSString *toolbarCursorButtonIdentifier;
	NSString *toolbarPanButtonIdentifier;
	NSString *toolbarZoomInButtonIdentifier;
	NSString *toolbarZoomOutButtonIdentifier;
	
	SpatialAnnotationOverlay *overlay;
}

- (MapView*)mapView;

- (IBAction)showDataSets:(id)sender;
- (IBAction)closeDataSets:(id)sender;
- (IBAction)toggleShowPaths:(id)sender;

- (IBAction)mapTypeButtonPress:(id)sender;
- (IBAction)zoomButtonPress:(id)sender;
- (IBAction)cursorButtonPress:(id)sender;

- (IBAction)showOverlay:(id)sender;

@end
