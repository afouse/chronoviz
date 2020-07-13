import objc

from Foundation import *
from AppKit import *
from CoreMedia import *
from Quartz import *

from Cocoa import *

PluginClass = objc.lookUpClass("AnnotationDataAnalysisPlugin")
AnnotationCategoryFilter = objc.lookUpClass("AnnotationCategoryFilter")
VideoFrameLoader = objc.lookUpClass("VideoFrameLoader")

class AverageColor(PluginClass):
    def setup(self):
         # Sets the name of the plugin in the menu
        self.setDisplayName_("Average color")
    
    def performAnalysis(self):
        app = NSApplication.sharedApplication()

        win = NSWindow.alloc()
        win.retain()
        frame = ((200.0, 300.0), (520.0, 560.0))
        win.initWithContentRect_styleMask_backing_defer_(frame, 15, 2, 0)
        win.setTitle_("Average color")
        win.setLevel_(3)  # floating window

        hel = NSButton.alloc().initWithFrame_(((10.0, 10.0), (80.0, 20.0)))
        win.contentView().addSubview_(hel)
        hel.setBezelStyle_(4)
        hel.setTitle_("Calculate")
        hel.setTarget_(self)
        hel.setAction_("calculate")
        
        frameTime = CMTimeMakeWithSeconds(1, 600)
        frameRef = VideoFrameLoader.generateImageAt_for_error_(frameTime, self.currentDocument().movie(), objc.NULL)
        image = NSImage.alloc().initWithCGImage_size_(frameRef, NSZeroSize)
        self.imageView = ImageSelection.alloc().initWithFrame_(((10, 50), (500, 500)))
        self.imageView.setImage_(image)
        self.imageView.setImageAlignment_(NSImageAlignBottom)
        win.contentView().addSubview_(self.imageView)

        win.makeKeyAndOrderFront_(self)
        
    def calculate(self):
        selection = self.imageView.getSelectionInImagePixels()
        print(NSStringFromRect(selection))

    def annotationsForCategory_(self, categoryName):
        category = self.categoryForName_(categoryName)
        return self.currentDocument().annotationsForCategory_(category)

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
                
                return CGRectMake(selection.origin.x * ratio, selection.origin.y * ratio, selection.size.width * ratio, selection.size.height * ratio)
            
except objc.error as e:
    if str(e).endswith("is overriding existing Objective-C class"):
        print(f"Did not reload class: {e}")
    else:
        raise e
