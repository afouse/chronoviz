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

- (void)linkVideoProperties:(VideoProperties *)videoProperties;

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

- (void)dealloc
{
    [self setVideoProperties:nil];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)path
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if(object == self && [path isEqualToString:@"videoProperties"])
    {
        VideoProperties *oldProps = [change objectForKey:NSKeyValueChangeOldKey];
        if(oldProps) {
            [oldProps removeObserver:self forKeyPath:@"title"];
            [oldProps removeObserver:self forKeyPath:@"offset"];
        }
        [self linkVideoProperties:[self videoProperties]];
    }
    else if ((object == [self videoProperties]) && [path isEqual:@"title"])
    {
        [[self window] setTitle:[[self videoProperties] title]];
    }
    else if ((object == [self videoProperties]) && [path isEqual:@"offset"])
    {
        QTTime newTime = QTTimeIncrement([[[AppController currentApp] movie] currentTime], [[self videoProperties] offset]);
        if(newTime.timeValue < 0)
        {
            newTime.timeValue = 0;
        }
        //[[movieView movie] setCurrentTime:newTime];
        //[self update];
    }
}

- (void)linkVideoProperties:(VideoProperties*)properties
{
        
    if(properties)
    {
        [self window];
        NSSize contentSize = [[[properties movie] attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
        
        contentSize.width = contentSize.width;
        contentSize.height = contentSize.height;
        
        CGFloat footer = 0;
        
//        if(statusBarVisible)
//        {
//            footer = [statusBar frame].size.height;
//        }
//        else if (alignmentBarVisible)
//        {
//            footer = [alignmentBar frame].size.height;
//        }
        
        contentSize.height = contentSize.height + footer;
        [[self window] setContentSize:contentSize];
        [[self window] setTitle:[properties title]];
        [[self spatialDataView] setBackgroundMovie:[[self videoProperties] movie]];
        [[self spatialDataView] setEnableAnnotation:YES];
        
        NSString *categoryName = @"Spatial Annotations";
        AnnotationCategory *spatial = [[AnnotationDocument currentDocument] categoryForName:categoryName];
        if(!spatial) {
            spatial = [[AnnotationDocument currentDocument] createCategoryWithName:categoryName];
        }
        
        [[self spatialDataView] setAnnotationCategory:spatial];
        
//        QTTime offset = [properties offset];
//        [offsetField setFloatValue:((CGFloat) offset.timeValue/(CGFloat) offset.timeScale)];
//        
//        [volumeSlider setHidden:![properties hasAudio]];
//        [volumeIcon setHidden:![properties hasAudio]];
        
        [properties addObserver:self forKeyPath:@"title" options:0 context:NULL];
        [properties addObserver:self forKeyPath:@"offset" options:0 context:NULL];
    }
    
}

- (id<AnnotationView>)annotationView
{
    return [self spatialDataView];
}


@end
