from Foundation import *
import objc
import random
PluginClass = objc.lookUpClass('AnnotationDataAnalysisPlugin')
class RandomTimeSeries(PluginClass):
    def setup(self):
         # Sets the name of the plugin in the menu
        self.setDisplayName_("Random Time Series")
    def performAnalysis(self):
        series = self.newTimeSeries()
        (value, timescale, _, _) = self.currentDocument().duration()
        duration = value//timescale
        self.log_(duration)
        for second in range(0, duration + 1):
            self.log_(second)
            series.addValue_atSeconds_(random.randrange(1, 100), second)
