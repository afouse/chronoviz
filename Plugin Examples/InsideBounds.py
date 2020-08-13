#
#  Threshold.py
#  Threshold Plugin for ChronoViz
#

from Foundation import *
from AppKit import *
import objc

class InsideBounds(AnnotationDataAnalysisPlugin):
    inThreshold = False
    
    def setup(self):
         # Sets the name of the plugin in the menu
        self.setDisplayName_("Annotate inside bounds")
    
    def performAnalysis(self):
        app = NSApplication.sharedApplication()

        self.win = NSWindow.alloc()
        self.win.retain()
        frame = ((200.0, 300.0), (400.0, 200.0))
        self.win.initWithContentRect_styleMask_backing_defer_(frame, 15, 2, 0)
        self.win.setTitle_(self.displayName())
        self.win.setLevel_(3)  # floating window
        
        #
        # Data selection
        #
        
        labelDataInput = NSTextField.alloc().initWithFrame_(((10, 150), (100, 20)))
        labelDataInput.setStringValue_("Data to annotate")
        labelDataInput.setEditable_(False)
        labelDataInput.setDrawsBackground_(False)
        labelDataInput.setBordered_(False)
        labelDataInput.setAlignment_(NSRightTextAlignment)
        self.win.contentView().addSubview_(labelDataInput)
        
        self.dataInput = NSPopUpButton.alloc().initWithFrame_(((110, 150), (200, 20)))
        dataSets = self.currentDocument().dataSetsOfClass_(TimeSeriesData)
        for dataSet in dataSets:
            self.dataInput.addItemWithTitle_(dataSet.name())
            self.dataInput.lastItem().setRepresentedObject_(dataSet)
        self.win.contentView().addSubview_(self.dataInput)
        
        #
        # Upper bound input
        #
        
        labelUpperBoundInput = NSTextField.alloc().initWithFrame_(((10, 100), (100, 20)))
        labelUpperBoundInput.setStringValue_("Upper bound")
        labelUpperBoundInput.setEditable_(False)
        labelUpperBoundInput.setDrawsBackground_(False)
        labelUpperBoundInput.setBordered_(False)
        labelUpperBoundInput.setAlignment_(NSRightTextAlignment)
        self.win.contentView().addSubview_(labelUpperBoundInput)
        
        self.upperBoundInput = NSTextField.alloc().initWithFrame_(((115, 100), (200, 20)))
        self.upperBoundInput.setEditable_(True)
        self.upperBoundInput.setContinuous_(True)
        self.win.contentView().addSubview_(self.upperBoundInput)
        
        #
        # Lower bound input
        #
        
        labelLowerBoundInput = NSTextField.alloc().initWithFrame_(((10, 50), (100, 20)))
        labelLowerBoundInput.setStringValue_("Lower bound")
        labelLowerBoundInput.setEditable_(False)
        labelLowerBoundInput.setDrawsBackground_(False)
        labelLowerBoundInput.setBordered_(False)
        labelLowerBoundInput.setAlignment_(NSRightTextAlignment)
        self.win.contentView().addSubview_(labelLowerBoundInput)
        
        self.lowerBoundInput = NSTextField.alloc().initWithFrame_(((115, 50), (200, 20)))
        self.lowerBoundInput.setEditable_(True)
        self.lowerBoundInput.setContinuous_(True)
        self.win.contentView().addSubview_(self.lowerBoundInput)
        
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

        try:
            upperBound = float(self.upperBoundInput.stringValue())
        except ValueError:
            print(f"Upper bound invalid: {self.upperBoundInput.stringValue()} is not a number")
            return
        try:
            lowerBound = float(self.lowerBoundInput.stringValue())
        except ValueError:
            print(f"Lower bound invalid: {self.lowerBoundInput.stringValue()} is not a number")
            return
           
        dataSet = self.dataInput.selectedItem().representedObject()
        dataPoints = dataSet.dataPoints()

        ResultsCat = self.categoryForName_(dataSet.name() + " between " + str(lowerBound) + " and " + str(upperBound))
        ResultsCat.autoColor()
        annotation = 0

        for data in dataPoints:
            dataValue = data.numericValue()
            if lowerBound <= dataValue and dataValue <= upperBound:
                if self.inThreshold:
                    pass
                else:
                    self.inThreshold = True
                    annotation = self.newAnnotationAtTime_(data.time())
                    annotation.setTitle_("Inside bounds")
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
