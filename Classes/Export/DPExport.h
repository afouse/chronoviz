//
//  DPExport.h
//  DataPrism
//
//  Created by Adam Fouse on 3/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class AnnotationDocument;

@interface DPExport : NSObject {

}

-(NSString*)name;
-(BOOL)export:(AnnotationDocument*)doc;

@end
