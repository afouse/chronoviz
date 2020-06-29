#
#  Threshold.py
#  Threshold Plugin for ChronoViz
#

from Foundation import *
import objc

PluginClass = objc.lookUpClass(u"AnnotationDataAnalysisPlugin")
Annotation = objc.lookUpClass('Annotation')
TimeCodedDataPoint = objc.lookUpClass('TimeCodedDataPoint')
PluginParameter = objc.lookUpClass('PluginParameter')

class Threshold(PluginClass):

    inThreshold = False
    
    def setup(self):
         # Sets the name of the plugin in the menu
        self.setDisplayName_("Time Series Threshold")
        
        # Determines which data sets the user can choose when running the plugin
        self.setDataVariableClass_("TimeSeriesData")
        
        self.dataVariable = self.addDataVariable_("Data")
        self.thresholdParameter = self.addInputParameter_("Threshold")
        self.thresholdParameter.setParameterValue_(20)
        self.thresholdParameter.setMinValue_(1)
        self.thresholdParameter.setMaxValue_(10000)
    
    def performAnalysis(self):
        theThreshold = self.thresholdParameter.parameterValue()
        dataPoints = self.dataVariable.dataPoints()
        
        ResultsCat = self.categoryForName_(self.dataVariable.dataSet().name() + " above " + str(theThreshold))
        ResultsCat.autoColor()
        annotation = 0
        
        for data in dataPoints:
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
            else:
                if self.inThreshold:
                    self.inThreshold = False
                    annotation.setEndTime_(data.time())
                    
        if self.inThreshold:
            annotation.setEndTime_(data.time())
      
