//
//  DPAppProxy.m
//  ChronoViz
//
//  Created by Adam Fouse on 2/27/12.
//  Copyright (c) 2012 University of California, San Diego. All rights reserved.
//

#import "DPAppProxy.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "LinkedFilesController.h"
#import "DPViewManager.h"
#import "DPURLHandler.h"
#import "TimeCodedData.h"
#import "DataSource.h"

@implementation DPAppProxy

- (void)registerDataSourceClass:(Class)dataSourceClass
{
    [LinkedFilesController registerDataSourceClass:dataSourceClass];
}

- (void)registerDataClass:(Class)dataClass 
            withViewClass:(Class)viewClass 
          controllerClass:(Class)controllerClass 
             viewMenuName:(NSString*)menuName
{
    [[[AppController currentApp] viewManager] registerDataClass:dataClass
                                                  withViewClass:viewClass
                                                controllerClass:controllerClass
                                                   viewMenuName:menuName];
}

- (void)registerURLHandler:(id)handler forCommand:(NSString*)command
{
    [[[AppController currentApp] urlHandler] registerHandler:handler
                                                  forCommand:command];
}

- (void)addMenuItem:(NSMenuItem*)menuItem toMenuNamed:(NSString*)menuName
{
    [[AppController currentApp] addMenuItem:menuItem toMenuNamed:menuName];
}

#pragma mark Data Management

- (TimeCodedData*)dataSetForID:(NSString*)uuid
{
    NSArray *allData = [[AnnotationDocument currentDocument] dataSets];
    for(TimeCodedData *data in allData)
    {
        if([uuid isEqualToString:[data uuid]])
        {
            return data;
        }
    }
    return nil;
}

- (NSArray*)dataSetsOfClass:(Class)dataSetClass
{
    NSMutableArray *sets = [NSMutableArray array];
    NSArray *allData = [[AnnotationDocument currentDocument] dataSets];
    for(TimeCodedData *data in allData)
    {
        if([data isKindOfClass:dataSetClass])
        {
            [sets addObject:data];
        }
    }
    return sets;
}

- (NSArray*)dataSourcesOfClass:(Class)dataSourceClass
{
    NSMutableArray *sources = [NSMutableArray array];
    NSArray *allData = [[AnnotationDocument currentDocument] dataSources];
    for(DataSource *data in allData)
    {
        if([data isKindOfClass:dataSourceClass])
        {
            [sources addObject:data];
        }
    }
    return sources;
}

- (NSArray*)allMedia
{
    return [[AnnotationDocument currentDocument] allMediaProperties];
}

#pragma mark View Management

- (void)addAnnotationView:(NSObject<AnnotationView>*)view
{
    [[AppController currentApp] addAnnotationView:view];
}

#pragma mark App Status

- (QTTime)currentTime
{
    return [[AppController currentApp] currentTime];
}

- (void)setCurrentTime:(QTTime)time fromSender:(id)sender
{
    [[AppController currentApp] moveToTime:time fromSender:sender];
}

- (void)setCurrentRate:(CGFloat)rate fromSender:(id)sender
{
    [[AppController currentApp] setRate:rate fromSender:sender];
}

- (void)updateViewMenu
{
    [[AppController currentApp] updateViewMenu];
}

@end
