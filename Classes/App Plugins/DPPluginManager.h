//
//  DPPluginManager.h
//  ChronoViz
//
//  Created by Adam Fouse on 12/13/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DPAppProxy;

@interface DPPluginManager : NSObject {
    NSMutableArray *plugins;
    
    DPAppProxy *appProxy;
}

-(void)loadPlugins;
-(void)resetPlugins;

@end
