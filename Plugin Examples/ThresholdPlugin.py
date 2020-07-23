#
#  Threshold.py
#  Threshold Plugin for ChronoViz
#

from Foundation import *
from AppKit import *
import objc

class ThresholdPlugin(AnnotationDataAnalysisPlugin):
    inThreshold = False
    
    def setup(self):
         # Sets the name of the plugin in the menu
        self.setDisplayName_("Annotate data over threshold")
    
    def performAnalysis(self):
        print("setting up")
        app = NSApplication.sharedApplication()

        self.win = NSWindow.alloc()
        self.win.retain()
        frame = ((200.0, 300.0), (400.0, 150.0))
        self.win.initWithContentRect_styleMask_backing_defer_(frame, 15, 2, 0)
        self.win.setTitle_(self.displayName())
        self.win.setLevel_(3)  # floating window
        
        #
        # Data selection
        #
        
        labelDataInput = NSTextField.alloc().initWithFrame_(((10, 100), (100, 20)))
        labelDataInput.setStringValue_("Data to annotate")
        labelDataInput.setEditable_(False)
        labelDataInput.setDrawsBackground_(False)
        labelDataInput.setBordered_(False)
        labelDataInput.setAlignment_(NSRightTextAlignment)
        self.win.contentView().addSubview_(labelDataInput)
        
        self.dataInput = NSPopUpButton.alloc().initWithFrame_(((110, 100), (200, 20)))
        dataSets = self.currentDocument().dataSetsOfClass_(TimeSeriesData)
        for dataSet in dataSets:
            self.dataInput.addItemWithTitle_(dataSet.name())
            self.dataInput.lastItem().setRepresentedObject_(dataSet)
        self.win.contentView().addSubview_(self.dataInput)
        
        #
        # Threshold input
        #
        
        labelThresholdInput = NSTextField.alloc().initWithFrame_(((10, 50), (100, 20)))
        labelThresholdInput.setStringValue_("Threshold")
        labelThresholdInput.setEditable_(False)
        labelThresholdInput.setDrawsBackground_(False)
        labelThresholdInput.setBordered_(False)
        labelThresholdInput.setAlignment_(NSRightTextAlignment)
        self.win.contentView().addSubview_(labelThresholdInput)
        
        self.thresholdInput = NSTextField.alloc().initWithFrame_(((115, 50), (200, 20)))
        self.thresholdInput.setEditable_(True)
        self.thresholdInput.setContinuous_(True)
        self.win.contentView().addSubview_(self.thresholdInput)
        
        #
        # Execute button
        #

        executeButton = NSButton.alloc().initWithFrame_(((10.0, 10.0), (80.0, 20.0)))
        self.win.contentView().addSubview_(executeButton)
        executeButton.setBezelStyle_(4)
        executeButton.setTitle_("Annotate")
        executeButton.setTarget_(self)
        executeButton.setAction_("calculate")

        self.win.makeKeyAndOrderFront_(self)
    
    def calculate(self):
        print("calculate")
        dataSet = self.dataInput.selectedItem().representedObject()
        dataPoints = dataSet.dataPoints()
        try:
            theThreshold = float(self.thresholdInput.stringValue())
            print(f"threshold: {theThreshold}")
        except ValueError:
            print(f"{self.thresholdInput.stringValue()} is not a number")
            return
        
        ResultsCat = self.categoryForName_(dataSet.name() + " above " + str(theThreshold))
        ResultsCat.autoColor()
        annotation = 0
        
        for data in dataPoints:
            print(data)
            dataValue = data.numericValue()
            if (dataValue > theThreshold):
                if self.inThreshold:
                    pass
                else:
                    self.inThreshold = True
                    annotation = self.newAnnotationAtTime_(data.time())
                    annotation.setTitle_("Above threshold")
                    annotation.setIsDuration_(True)
                    annotation.addCategory_(ResultsCat)
                    self.currentDocument().addAnnotation_(annotation)
                    
            else:
                if self.inThreshold:
                    self.inThreshold = False
                    annotation.setEndTime_(data.time())
                    
        if self.inThreshold:
            annotation.setEndTime_(data.time())
            
        self.win.close()
      
