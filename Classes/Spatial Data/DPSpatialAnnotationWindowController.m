//
//  DPSpatialAnnotationWindowController.m
//  
//
//  Created by Adam Fouse on 10/18/15.
//
//

#import "DPSpatialAnnotationWindowController.h"
#import "DPSpatialDataView.h"
#import "SpatialTimeSeriesData.h"
#import "AnnotationDocument.h"
#import "VideoProperties.h"
#import "AppController.h"
#import "DataSource.h"
#import "TimelineView.h"
#import "ColorMappedTimeSeriesVisualizer.h"
#import "DPMaskedSelectionView.h"
#import "DPMaskedSelectionArea.h"
#import "DPDataSelectionPanel.h"
#import "DPSelectionDataSource.h"
#import "DPSpatialDataBase.h"

@interface DPSpatialAnnotationWindowController ()

@property(assign) IBOutlet DPSpatialDataView* spatialDataView;

@end

@implementation DPSpatialAnnotationWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (id)init
{
    if(![super initWithWindowNibName:@"DPSpatialAnnotationWindow"])
        return nil;
    
    [self addObserver:self
           forKeyPath:@"videoProperties"
              options:0
              context:NULL];
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)path
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if(object == self && [path isEqualToString:@"videoProperties"])
    {
        [[self spatialDataView] setBackgroundMovie:[[self videoProperties] movie]];
    }
}

- (id<AnnotationView>)annotationView
{
    return [self spatialDataView];
}


@end
