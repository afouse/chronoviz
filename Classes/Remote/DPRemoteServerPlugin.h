//
//  DPRemoteServerPlugin.h
//  ChronoViz
//
//  Created by Adam Fouse on 12/13/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPAppPlugin.h"
#import "DPAppProxy.h"
@class DPRemoteConnection;

@interface DPRemoteServerPlugin : NSObject <DPAppPlugin> {
    DPAppProxy *app;
    
    DPRemoteConnection* client;
    NSMenuItem* clientMenuItem;
}

- (IBAction)startStopClient:(id)sender;

@end
