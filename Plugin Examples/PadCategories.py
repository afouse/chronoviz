from Foundation import *
import objc

PluginClass = objc.lookUpClass('AnnotationDataAnalysisPlugin')
Annotation = objc.lookUpClass('Annotation')

def categoryNamesFromAnnotationInput(annotationInput):
    selectedCategories = annotationInput.annotationFilter().visibleCategories()
    combinedNames = ", ".join(map(lambda category: category.name(), selectedCategories))
    return combinedNames

class PadCategories(PluginClass):
    
    def setup(self):
        
        # Sets the name of the plugin in the menu
        self.setDisplayName_("Pad Categories")
        
        self.annotationInput = self.addAnnotationSet_("Category to pad")
        self.startPaddingParameter = self.addInputParameter_("Padding before (in s)")
        self.startPaddingParameter.setParameterValue_(1)
        self.endPaddingParameter = self.addInputParameter_("Padding after (in s)")
        self.endPaddingParameter.setParameterValue_(1)
        
            
    def performAnalysis(self):
        combinedCategory = self.categoryForName_(categoryNamesFromAnnotationInput(self.annotationInput) + " (padded)")
        combinedCategory.autoColor()
        
        startPadding = self.startPaddingParameter.parameterValue()
        endPadding = self.startPaddingParameter.parameterValue()
        
        for anno in self.annotationInput.annotations():
            if(anno.isDuration()):
                newStart = anno.startTimeSeconds() - startPadding
                newEnd = anno.endTimeSeconds() + endPadding
            else:
                newStart = anno.startTimeSeconds() - startPadding
                newEnd = anno.startTimeSeconds() + endPadding
            
            newAnno = self.newAnnotationAtSeconds_(max(0, newStart))
            newAnno.setIsDuration_(True)
            newAnno.setEndTimeString_(str(newEnd))
            newAnno.setTitle_(anno.title())
            newAnno.setAnnotation_(anno.annotation())
            newAnno.addCategory_(combinedCategory)
