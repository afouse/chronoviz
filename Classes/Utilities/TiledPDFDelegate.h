//
//  TiledPDFDelegate.h
//
//  Created by Adam Fouse.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 *  This class is responsible for the drawing. To compare the drawing speed of this 
 */
@interface TiledPDFDelegate : NSObject {
    CGPDFDocumentRef pdfDoc;
    CGPDFPageRef page;
    
    BOOL verticalMirror;
}

@property BOOL verticalMirror;

-(id)initWithFile:(NSString*)pdfFile;
-(id)initWithFile:(NSString*)pdfFile forPage:(NSUInteger)pageNum;
-(id)initWithDocument:(CGPDFDocumentRef)doc forPage:(NSUInteger)pageNum;

-(CGPDFPageRef)page;
-(CGPDFDocumentRef)pdfDoc;


@end
