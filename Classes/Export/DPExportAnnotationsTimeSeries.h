//
//  DPExportAnnotationsTimeSeries.h
//  ChronoViz
//
//  Created by Adam Fouse on 4/19/12.
//  Copyright (c) 2012 University of California, San Diego. All rights reserved.
//

#import "DPExport.h"

@class AnnotationCategoryFilter;

@interface DPExportAnnotationsTimeSeries : DPExport {
    AnnotationDocument *theDoc;
    AnnotationCategoryFilter *categories;
    
    IBOutlet NSWindow *exportWindow;
    IBOutlet NSPopUpButton *rateButton;
    IBOutlet NSOutlineView *categoriesOutlineView;
    IBOutlet NSMatrix *entryTypeMatrix;
}

- (IBAction)saveOutput:(id)sender;

@end
