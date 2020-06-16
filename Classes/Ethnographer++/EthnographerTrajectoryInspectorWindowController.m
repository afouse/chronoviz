//
//  EthnographerTrajectoryInspectorWindowController.m
//  ChronoViz
//
//  Created by Adam Fouse on 9/20/12.
//
//

#import "EthnographerTrajectoryInspectorWindowController.h"
#import "EthnographerTrajectory.h"
#import "DPPathSegment.h"
#import "DPPath.h"
#import "DPTimeUtilities.h"
#import "NSStringTimeCodes.h"
#import "AppController.h"
#import <AVKit/AVKit.h>

NSString * const TrajectoryTypeColummn = @"type";
NSString * const TrajectoryTimeColummn = @"time";
NSString * const TrajectoryDataColummn = @"data";

NSString * const TrajectoryStraightPathType = @"Straight Path";
NSString * const TrajectoryCurvedPathType = @"Curved Path";
NSString * const TrajectoryTimeMarkerType = @"Time";
NSString * const TrajectoryOrientationMarkerType = @"Orientation";
NSString * const TrajectoryPivotMarkerType = @"Pivot";

@interface EthnographerTrajectoryEntry : NSObject {
    NSString *type;
    CMTime time;
    NSString *dataString;
    NSObject *dataObject;
    
}

@property(assign) NSString* type;
@property CMTime time;
@property(copy) NSString* dataString;
@property(retain) NSObject* dataObject;

@end

@implementation EthnographerTrajectoryEntry

@synthesize type,time,dataString,dataObject;

- (void)dealloc
{
    self.dataString = nil;
    self.dataObject = nil;
    [super dealloc];
}

@end

@interface EthnographerTrajectoryInspectorWindowController ()

- (void)compileElements;

@end

@implementation EthnographerTrajectoryInspectorWindowController
@synthesize elementsTable,trajectory;

- (id)initForTrajectory:(EthnographerTrajectory*)theTrajectory;
{
    self = [super initWithWindowNibName:@"EthnographerTrajectoryInspectorWindow"];
    if (self) {
        trajectory = [theTrajectory retain];
        elements = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(compileElements)
                                                     name:DPDataSetUpdatedNotification
                                                   object:trajectory];
    }
    
    return self;
}

- (void)dealloc
{
    [elements release];
    [trajectory release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSArray *columns = [elementsTable tableColumns];
    NSTableColumn *type = [columns objectAtIndex:0];
    [type setIdentifier:TrajectoryTypeColummn];
    NSTableColumn *time = [columns objectAtIndex:1];
    [time setIdentifier:TrajectoryTimeColummn];
    NSTableColumn *dataCol = [columns objectAtIndex:2];
    [dataCol setIdentifier:TrajectoryDataColummn];
    
    [self compileElements];
    
}

- (void)compileElements
{
    [elements removeAllObjects];
    
    for(NSObject *pathElement in [trajectory pathSegments])
    {
        if([pathElement isKindOfClass:[DPPathSegment class]])
        {
            DPPathSegment *segment = (DPPathSegment*)pathElement;
            EthnographerTrajectoryEntry *entry = [[EthnographerTrajectoryEntry alloc] init];
            entry.type = TrajectoryStraightPathType;
            entry.time = kCMTimeZero;
            entry.dataString = [NSString stringWithFormat:@"(%.2f,%.2f) to (%.2f,%.2f)",segment.start.x,segment.start.y,segment.end.x,segment.end.y];
            entry.dataObject = segment;
            
            [elements addObject:entry];
            
            [entry release];
        }
        else if ([pathElement isKindOfClass:[DPPath class]])
        {
            DPPath *path = (DPPath*)pathElement;
            EthnographerTrajectoryEntry *entry = [[EthnographerTrajectoryEntry alloc] init];
            entry.type = TrajectoryCurvedPathType;
            entry.time = kCMTimeZero;
            DPPathSegment *start = [[path segments] objectAtIndex:0];
            DPPathSegment *end = [[path segments] lastObject];
            entry.dataString = [NSString stringWithFormat:@"(%.2f,%.2f) to (%.2f,%.2f)",start.start.x,start.start.y,end.end.x,end.end.y];
            entry.dataObject = path;
            
            [elements addObject:entry];
            
            [entry release];
        }
    }
    
    NSDictionary *timeMarkers = [trajectory timeMarks];
    NSArray *timeMarkerTimes = [[timeMarkers allKeys] sortedArrayUsingFunction:dpCMTimeValueSort context:NULL];
    for(NSValue *timeValue in timeMarkerTimes)
    {
        DPPathSegment *segment = [timeMarkers objectForKey:timeValue];
        EthnographerTrajectoryEntry *entry = [[EthnographerTrajectoryEntry alloc] init];
        entry.type = TrajectoryTimeMarkerType;
        entry.time = [timeValue CMTimeValue];
        entry.dataString = [NSString stringWithFormat:@"(%.2f,%.2f) to (%.2f,%.2f)",segment.start.x,segment.start.y,segment.end.x,segment.end.y];
        entry.dataObject = segment;
        
        [elements addObject:entry];
        
        [entry release];
        
    }
    
    NSDictionary *inputOrientations = [trajectory orientationMarks];
    NSArray *orientations = [[inputOrientations allValues] sortedArrayUsingComparator:^(id obj1, id obj2) {
        EthnographerOrientedTimeMarker *point1 = (EthnographerOrientedTimeMarker*)obj1;
        EthnographerOrientedTimeMarker *point2 = (EthnographerOrientedTimeMarker*)obj2;
        return CMTimeCompare([point1 time], [point2 time]);
    }];
    for(EthnographerOrientedTimeMarker *marker in orientations)
    {
        if([marker hasOrientation])
        {
            EthnographerTrajectoryEntry *entry = [[EthnographerTrajectoryEntry alloc] init];
            entry.type = TrajectoryOrientationMarkerType;
            entry.time = [marker time];
            entry.dataString = [NSString stringWithFormat:@"%.2f degrees",marker.orientation];
            entry.dataObject = marker;
            
            [elements addObject:entry];
            
            [entry release];
        }
    }
    
    
    for(EthnographerTrajectoryPivot *pivot in [[trajectory pivotMarks] allValues])
    {
        EthnographerTrajectoryEntry *entry = [[EthnographerTrajectoryEntry alloc] init];
        entry.type = TrajectoryPivotMarkerType;
        entry.time = pivot.source.time;
        entry.dataString = [NSString stringWithFormat:@"From %.2f to %.2f degrees",pivot.source.orientation,pivot.target.orientation];
        entry.dataObject = pivot;
        
        [elements addObject:entry];
        
        [entry release];
    }
    
    [elementsTable reloadData];
}

- (void)deleteElement:(EthnographerTrajectoryEntry*)entry
{
    if(entry.type == TrajectoryStraightPathType)
    {
        [trajectory removePathElement:entry.dataObject];
    }
    else if (entry.type == TrajectoryCurvedPathType)
    {
        [trajectory removePathElement:entry.dataObject];
    }
    else if (entry.type == TrajectoryTimeMarkerType)
    {
        [trajectory removeTimeMarkerAtTime:entry.time];
    }
    else if (entry.type == TrajectoryOrientationMarkerType)
    {
        [trajectory removeOrientationMark:(EthnographerOrientedTimeMarker*)entry.dataObject];
    }
    else if (entry.type == TrajectoryPivotMarkerType)
    {
        [trajectory removePivot:(EthnographerTrajectoryPivot*)entry.dataObject];
    }
}

#pragma mark Table View Delegate Methods
- (void)deleteSelection
{
	NSIndexSet *selectedRows = [elementsTable selectedRowIndexes];
	
	NSString *message;
	if([selectedRows count] < 1)
	{
		return;
	}
	else if ([selectedRows count] == 1)
	{
		message = @"Are you sure you want to delete the currently selected trajectory component?";
	}
	else
	{
		message = @"Are you sure you want to delete the currently selected trajectory components?";
	}
	
	NSAlert *confirmation = [[NSAlert alloc] init];
	[confirmation setMessageText:message];
	[[confirmation addButtonWithTitle:@"Delete"] setKeyEquivalent:@""];
	[[confirmation addButtonWithTitle:@"Cancel"] setKeyEquivalent:@"\r"];
	
	NSInteger result = [confirmation runModal];
	
	if(result == NSAlertFirstButtonReturn)
	{
		NSArray *selected = [elements objectsAtIndexes:selectedRows];
		[elementsTable deselectAll:self];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            for(EthnographerTrajectoryEntry *entry in selected)
            {
                [self deleteElement:entry];
            }
            [trajectory regeneratePath];
            
        });
    }
}

             
             
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
	return [elements count];
}

- (id) tableView:(NSTableView*) aTableView objectValueForTableColumn:(NSTableColumn*) tableColumn row:(NSInteger) rowIndex {
	NSString *identifier = [tableColumn identifier];
	NSParameterAssert(rowIndex >= 0 && rowIndex < [elements count]);
	EthnographerTrajectoryEntry* element = [elements objectAtIndex:rowIndex];
	if(identifier == TrajectoryTypeColummn)
	{
		return element.type;
	}
	else if(identifier == TrajectoryTimeColummn)
	{
		return [NSString stringWithQTTime:element.time];
	}
	else if(identifier == TrajectoryDataColummn)
	{
		return element.dataString;
	}
	else
	{
		return @"";
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    return NO;
}


- (void)tableView:(NSTableView *)theTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    [elements sortUsingDescriptors:[elementsTable sortDescriptors]];
    [elementsTable reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([elementsTable selectedRow] > -1)
	{
        EthnographerTrajectoryEntry *entry = [elements objectAtIndex:[elementsTable selectedRow]];
        
        [[AppController currentApp] moveToTime:entry.time fromSender:self];
        
//		[[AppController currentApp] moveToTime:[[annotations objectAtIndex:[tableView selectedRow]] startTime] fromSender:self];
//		[[AppController currentApp] setSelectedAnnotation:[annotations objectAtIndex:[tableView selectedRow]]];
	}
}


@end
