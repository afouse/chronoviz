//
//  TiledPDFDelegate.m
//
//  Created by Adam Fouse.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TiledPDFDelegate.h"

@implementation TiledPDFDelegate

@synthesize verticalMirror;

-(id)initWithFile:(NSString*)pdfFile
{
	return [self initWithFile:pdfFile forPage:1];
}

-(id)initWithFile:(NSString*)pdfFile forPage:(NSUInteger)pageNum
{
	NSURL *docURL = [NSURL fileURLWithPath:pdfFile];
	CGPDFDocumentRef doc = CGPDFDocumentCreateWithURL((CFURLRef)docURL);
	self = [self initWithDocument:doc forPage:pageNum];
    CGPDFDocumentRelease(doc);
	return self;
}

-(id)initWithDocument:(CGPDFDocumentRef)doc forPage:(NSUInteger)pageNum
{
	self = [super init];
	if (self != nil) {
		CGPDFDocumentRetain(doc);
		pdfDoc = doc;
		page = CGPDFDocumentGetPage(pdfDoc, pageNum);
		CGPDFPageRetain(page);
        
        self.verticalMirror = YES;
	}
	return self;
}

- (void)dealloc {
    CGPDFPageRelease(page);
    CGPDFDocumentRelease(pdfDoc);
    [super dealloc];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
	
	//CGAffineTransform m = CGPDFPageGetDrawingTransform (page, box, rect, rotation,preserveAspectRato);
    
	CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
	CGFloat h = pageRect.size.height;
	
	CGContextSaveGState (ctx);
    
    if(self.verticalMirror)
    {
        CGContextTranslateCTM(ctx, 0.0, h/2);
        CGContextScaleCTM(ctx, 1.0, -1.0);
        CGContextTranslateCTM(ctx, 0.0, -h/2);
    }
    else 
    {
        CGFloat pdfScale = layer.bounds.size.width/pageRect.size.width;
        CGContextScaleCTM(ctx, pdfScale,pdfScale); 
    }
    //CGContextClipToRect (context,CGPDFPageGetBoxRect (page, box));
	//CGContextConcatCTM(ctx, CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, [layer bounds], 0, true));
    CGContextDrawPDFPage (ctx, page);
	
    CGContextRestoreGState (ctx);
	
    //CGContextDrawPDFPage(ctx, page);
}

-(CGPDFPageRef)page
{
	return page;
}

-(CGPDFDocumentRef)pdfDoc
{
	return pdfDoc;
}

@end
