import math
import struct
import sys

import objc

from Foundation import *
from AppKit import *
from CoreMedia import *
from Quartz import *
from AVFoundation import *

from Cocoa import *


# If the class already exists, catch the exception
# ChronoViz prevents the "main" class in this file from such clashes, but not other classes.
#
# If you change this code and need to reload it, you have to relaunch ChronoViz,
# because after the first time this file is run the class will exist and
# it will not be overwritten until ChronoViz is restarted.
try:
    class ImageSelection(NSImageView):
        selectionStart = objc.ivar(u"selectionStart")
        selectionEnd = objc.ivar(u"selectionEnd")
        
        def drawRect_(self, dirtyRect):
            objc.super(ImageSelection, self).drawRect_(dirtyRect)
            
            selection = self.getSelectionInViewPixels()
            if selection is not None:
                context = NSGraphicsContext.currentContext().CGContext()
                
                path = CGPathCreateWithRect(selection, objc.NULL)
                CGContextAddPath(context, path)
                NSColor.greenColor().setStroke()
                
                CGContextSetLineWidth(context, 2)
                CGContextStrokePath(context)
            
        def mouseDown_(self, event):
            globalPoint = event.locationInWindow()
            localPoint = self.convertPoint_fromView_(globalPoint, None)
            self.setSelectionStart_(localPoint)
            self.setSelectionEnd_(localPoint)
            self.setNeedsDisplay_(True)
            
        def mouseDragged_(self, event):
            globalPoint = event.locationInWindow()
            localPoint = self.convertPoint_fromView_(globalPoint, None)
            self.setSelectionEnd_(localPoint)
            self.setNeedsDisplay_(True)
            
        def setSelectionStart_(self, point):
            self.selectionStart = point
            
        def setSelectionEnd_(self, point):
            self.selectionEnd = point
        
        def getSelectionInViewPixels(self):
            if (self.selectionStart is None) or (self.selectionEnd is None):
                return None
            
            xs = [self.selectionStart.x, self.selectionEnd.x]
            ys = [self.selectionStart.y, self.selectionEnd.y]
            xs.sort()
            ys.sort()
            width = xs[1] - xs[0]
            height = ys[1] - ys[0]
            return CGRectMake(xs[0], ys[0], width, height)
            
        def getSelectionInImagePixels(self):
            selection = self.getSelectionInViewPixels()
            if selection is not None:
                imageSize = self.image().size()
                imageWidth = imageSize.width
                imageHeight = imageSize.height
                
                frame = self.frame()
                # The ratios to increase the frame by to obtain the image size
                widthRatio = imageWidth / NSWidth(frame)
                heightRatio = imageHeight / NSHeight(frame)
                
                # Since the frame's aspect ratio can differ from the image's and
                # we know that the image is fit into the frame,
                # we choose the larger ratio.
                ratio = max(widthRatio, heightRatio)
                
                x = math.floor(selection.origin.x * ratio)
                y = math.floor(selection.origin.y * ratio)
                width = math.floor(selection.size.width * ratio)
                height = math.floor(selection.size.height * ratio)
                return CGRectMake(x, y, width, height)
            
except objc.error as e:
    if str(e).endswith("is overriding existing Objective-C class"):
        print(f"Did not reload class: {e}")
        # Load the existing class so that it is available in the following.
        ImageSelection = objc.lookUpClass("ImageSelection")
    else:
        raise e

class AverageColor(AnnotationDataAnalysisPlugin):
    def setup(self):
         # Sets the name of the plugin in the menu
        self.setDisplayName_("Average color")
    
    def performAnalysis(self):
        app = NSApplication.sharedApplication()

        self.win = NSWindow.alloc()
        self.win.retain()
        frame = ((200.0, 300.0), (520.0, 560.0))
        self.win.initWithContentRect_styleMask_backing_defer_(frame, 15, 2, 0)
        self.win.setTitle_("Average color")
        self.win.setLevel_(3)  # floating window

        hel = NSButton.alloc().initWithFrame_(((10.0, 10.0), (80.0, 20.0)))
        self.win.contentView().addSubview_(hel)
        hel.setBezelStyle_(4)
        hel.setTitle_("Calculate")
        hel.setTarget_(self)
        hel.setAction_("calculate")
        
        frameTime = self.currentDocument().movie().currentTime()
        frameRef = VideoFrameLoader.generateImageAt_for_error_(frameTime, self.currentDocument().movie(), objc.NULL)
        image = NSImage.alloc().initWithCGImage_size_(frameRef, NSZeroSize)
        self.imageView = ImageSelection.alloc().initWithFrame_(((10, 50), (500, 500)))
        self.imageView.setImage_(image)
        self.imageView.setImageAlignment_(NSImageAlignBottom)
        self.win.contentView().addSubview_(self.imageView)

        self.win.makeKeyAndOrderFront_(self)
        
    def calculate(self):
        self.selection = self.imageView.getSelectionInImagePixels()
        print(self.selection)
        
        frameRate = self.getFrameRate()
        durationInSeconds = CMTimeGetSeconds(self.currentDocument().movie().currentItem().duration())
        end = min(math.floor(frameRate * durationInSeconds), 500)
        
        self.series = TimeSeriesData.alloc().init()
        self.series.setName_("Average color data")
        dataSource = PluginDataSource.alloc().initWithPath_(None)
        dataSource.setName_("Average color")
        dataSource.addDataSet_(self.series)
            
        print("Start analyzing")
        self.frameCount = 0
        self.frameRate = self.getFrameRate()
        frameAnalyzer = VideoFrameAnalyzer.analyze_withDelegate_(self.currentDocument().movie(), self)
        print("Done analyzing")
        
        AppController.currentApp().viewManager().showData_(self.series)
        self.win.close()
        
    def readFrame_(self, buffer):
        width = CVPixelBufferGetWidth(buffer)
        height = CVPixelBufferGetHeight(buffer)
        
        CVPixelBufferLockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly)
        pointer = CVPixelBufferGetBaseAddress(buffer)
        ls = [self.getL_width_height_forPixel_(pointer, width, height, point) for point in self.pointsInRect_(self.selection)]
        average = sum(ls) / len(ls)
        CVPixelBufferUnlockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly)
        
        frameTime = CMTimeMake(self.frameCount, self.frameRate)
        self.series.addValue_atTime_(average, frameTime)
        self.frameCount += 1
        
    def pointsInRect_(self, rect):
        points = [
            (int(rect.origin.x + x), int(rect.origin.y + y)) for x in range(0, int(rect.size.width)) for y in range(0, int(rect.size.height))
        ]
        return points
    
    def getL_width_height_forPixel_(self, buffer, width, height, pixel):
        pixels = self.getPixel_width_height_forCoords_(buffer, width, height, pixel)
        r, = struct.unpack("B", pixels["r"])
        g, = struct.unpack("B", pixels["g"])
        b, = struct.unpack("B", pixels["b"])
        h, s, l = self.hslFromR_G_B_(r, g, b)
        return l
        
    def getFrameRate(self):
        asset = self.currentDocument().movie().currentItem().asset()
        return asset.tracksWithMediaType_(AVMediaTypeVideo).objectAtIndex_(0).nominalFrameRate()
        
    def getPixel_width_height_forCoords_(self, buffer, width, height, pixel):
        def coordinatesToOffset(x, y):
            # Each y increase is a full row, which adds `width` pixels to the offset.
            # Each pixel has 4 components.
            return (y * width + x) * 4
        
        offset = int(coordinatesToOffset(pixel[0], pixel[1]))
        return {"r": buffer[offset], "g": buffer[offset+1], "b": buffer[offset+2], "a": buffer[offset+3]}
        
    def hslFromR_G_B_(self, rByte, gByte, bByte):
        # Conversion following https://www.rapidtables.com/convert/color/rgb-to-hsl.html
        r = rByte/255.0
        g = gByte/255.0
        b = bByte/255.0
        
        cmax = max(r, g, b)
        cmin = min(r, g, b)
        delta = cmax - cmin
        
        if delta == 0:
            h = 0
        elif max == r:
            h = 60 * (((g - b)/delta) % 6)
        elif max == g:
            h = 60 * (((b - r)/delta) + 2)
        else:
            h = 60 * (((r - g)/delta) + 4)
            
        l = (cmax + cmin)/2
        
        if delta == 0:
            s = 0
        else:
            s = delta/(1-abs(2*l-1))
            
        return h, s, l

    def annotationsForCategory_(self, categoryName):
        category = self.categoryForName_(categoryName)
        return self.currentDocument().annotationsForCategory_(category)

