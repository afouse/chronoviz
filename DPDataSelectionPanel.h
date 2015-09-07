//
//  DPDataSelectionPanel.h
//  ChronoViz
//
//  Created by Adam Fouse on 6/14/12.
//  Copyright (c) 2012 University of California, San Diego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AnnotationView.h"

@interface DPDataSelectionPanel : NSObject {

    Class dataClass;
    
    IBOutlet NSPanel *dataSetsPanel;
    IBOutlet NSOutlineView *dataSetsOutlineView;
    
    NSMutableArray *dataSources;
    NSMutableDictionary *dataSetsPerSource;
    
    id colorEditDataSet;
    
    NSView<AnnotationView> *dataView;
    
    BOOL allowGroupColorChange;
    BOOL allowItemRename;
    BOOL allowGroupRename;
    BOOL changeCategoryNames;
    
}

@property BOOL allowGroupColorChange;
@property BOOL allowItemRename;
@property BOOL allowGroupRename;
@property BOOL changeCategoryNames;

- (id)initForView:(NSView<AnnotationView>*)view;
- (void)setDataClass:(Class)theDataClass;

- (IBAction)showDataSets:(id)sender;
- (IBAction)closeDataSets:(id)sender;

@end
