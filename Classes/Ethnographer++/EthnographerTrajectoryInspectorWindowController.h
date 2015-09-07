//
//  EthnographerTrajectoryInspectorWindowController.h
//  ChronoViz
//
//  Created by Adam Fouse on 9/20/12.
//
//

#import <Cocoa/Cocoa.h>
@class EthnographerTrajectory;

@interface EthnographerTrajectoryInspectorWindowController : NSWindowController {
    NSTableView *elementsTable;
    
    EthnographerTrajectory *trajectory;
    NSMutableArray *elements;
}

@property (assign) IBOutlet NSTableView *elementsTable;
@property (readonly) EthnographerTrajectory *trajectory;

- (id)initForTrajectory:(EthnographerTrajectory*)theTrajectory;

@end
