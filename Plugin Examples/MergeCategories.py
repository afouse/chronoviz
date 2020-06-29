from Foundation import *
import objc

PluginClass = objc.lookUpClass('AnnotationDataAnalysisPlugin')

def categoryNamesFromAnnotationInput(annotationInput):
    selectedCategories = annotationInput.annotationFilter().visibleCategories()
    combinedNames = ", ".join(map(lambda category: category.name(), selectedCategories))
    return combinedNames

class MergeCategories(PluginClass):
    
    def setup(self):
        # Sets the name of the plugin in the menu
        self.setDisplayName_("Merge Categories")
        
        self.firstAnnotationInput = self.addAnnotationSet_("First category")
        self.secondAnnotationInput = self.addAnnotationSet_("Second category")
        
            
    def performAnalysis(self):
        firstCategoryName = categoryNamesFromAnnotationInput(self.firstAnnotationInput)
        secondCategoryName = categoryNamesFromAnnotationInput(self.secondAnnotationInput)
        
        combinedCategory = self.categoryForName_(firstCategoryName + " + " + secondCategoryName)
        combinedCategory.autoColor()
        
        firstAnnotations = self.firstAnnotationInput.annotations()
        secondAnnotations = self.secondAnnotationInput.annotations()
        
        # Using a set here to easily combine without duplicates
        allAnnotations = set(firstAnnotations)
        allAnnotations.update(secondAnnotations)
        
        for anno in allAnnotations:
            newAnno = self.newAnnotationAtTime_(anno.startTime())
            newAnno.setIsDuration_(anno.isDuration())
            if(anno.isDuration()):
                newAnno.setEndTime_(anno.endTime())
            newAnno.setTitle_(anno.title())
            newAnno.setAnnotation_(anno.annotation())
            newAnno.addCategory_(combinedCategory)

