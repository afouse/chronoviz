//
//  DPDocumentTemplate.h
//  ChronoViz
//
//  Created by Adam Fouse on 11/13/12.
//
//

#import <Cocoa/Cocoa.h>
@class AnnotationDocument;

@interface DPDocumentTemplate : NSObject {
    
    NSXMLDocument *templateXMLDoc;
    NSURL *templateURL;
    
    NSDictionary *dataTypes;
    
}

-(id)initFromURL:(NSURL*)fileURL;
-(void)applyToDocument:(AnnotationDocument*)document;


@end
