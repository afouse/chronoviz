//
//  DPAppProxy.h
//  ChronoViz
//
//  Created by Adam Fouse on 2/27/12.
//  Copyright (c) 2012 University of California, San Diego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>
#import "AnnotationView.h"
@class TimeCodedData;

@interface DPAppProxy : NSObject


#pragma mark Plugin Setup

- (void)registerDataSourceClass:(Class)dataSourceClass;

- (void)registerDataClass:(Class)dataClass 
            withViewClass:(Class)viewClass 
          controllerClass:(Class)controllerClass 
             viewMenuName:(NSString*)menuName;

- (void)registerURLHandler:(id)handler forCommand:(NSString*)command;

- (void)addMenuItem:(NSMenuItem*)menuItem toMenuNamed:(NSString*)menuName;

#pragma mark Data Management

- (TimeCodedData*)dataSetForID:(NSString*)uuid;
- (NSArray*)dataSetsOfClass:(Class)dataSetClass;
- (NSArray*)dataSourcesOfClass:(Class)dataSourceClass;
- (NSArray*)allMedia;

#pragma mark View Management

- (void)addAnnotationView:(NSObject<AnnotationView>*)view;

#pragma mark App Status

- (QTTime)currentTime;
- (void)setCurrentTime:(QTTime)time fromSender:(id)sender;
- (void)setCurrentRate:(CGFloat)rate fromSender:(id)sender;
- (void)updateViewMenu;

@end
