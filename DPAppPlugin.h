//
//  DPAppPlugin.h
//  ChronoViz
//
//  Created by Adam Fouse on 12/13/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AppController;
@class DPAppProxy;

@protocol DPAppPlugin <NSObject>

//- (id) initWithAppController:(AppController*)app;
- (id) initWithAppProxy:(DPAppProxy*)appProxy;
- (void) reset;

@optional

- (void) updateTime;

@end
