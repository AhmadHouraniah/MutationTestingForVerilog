import sys
#import MutationOperator
from MutationOperator import MutationOperator
from GlobalVars import globalIterations, IverilogFilePath, vvpPath
import re
import string
import numpy as np


class delayOutputs(MutationOperator):

    ## inputDict = {
    #   fileName: [{
    #       name: ....
    #       }, ....
    #   ]
    # }
    
    def __init__(self, TB, files):
        #print(files)
        super().__init__('feedback for delayOutputs', 'delayOutputs',TB, files)
        self.numOfMutationsThatCanBeApplied = 0
        self.outputDict = {fileName: None for fileName in self.files}
        for fileName in self.files:
            text = open('TestingCode/'+fileName).readlines()
            outputNames = []
            lineIndexes = []
            for lineIndex, line in enumerate(text): ## Go in the text line by line.
                if(('output' in line) & (not "//" in line) & (";" in line)):
                    rearrangedLine = line.replace('output', '') ## drop input statement
                    if("reg" in rearrangedLine):
                        rearrangedLine = rearrangedLine.replace('reg', '') ## drop reg statement
                    # drop the bit declaraitons
                    if("[" in rearrangedLine ) & ("]" in rearrangedLine):
                        rearrangedLine = re.sub('\[.*?\]', '', rearrangedLine) ## drop bitwidth
                        outputNames.extend(re.findall(r'\w+', rearrangedLine)) ## get all output signal's name
                    else:
                        outputNames.extend(re.findall(r'\w+', rearrangedLine)) ## get all the output signal's name
                
                if (not "output" in line) & any([x in line for x in outputNames]):
                    if(re.findall(r'\w+', line)[0] in outputNames) | ("assign" in line):
                        lineIndexes.append(lineIndex)
                        
            self.outputDict[fileName] = {"names": outputNames, "lineIndexes" : lineIndexes}
            self.numOfMutationsThatCanBeApplied = len(self.outputDict[fileName]["lineIndexes"])
        #print("Mutation Count (delayOutputs): ", self.numOfMutationsThatCanBeApplied)

    def applyMutation(self, x):
        global globalIterations
        for fileName in self.files: ## iterate over files
            text = open('TestingCode/'+fileName).readlines()
            line = text[self.outputDict[fileName]["lineIndexes"][x]]
            if(any([x in line for x in self.outputDict[fileName]["names"]])):
                param = next((x for x in self.outputDict[fileName]["names"] if x in line), False)
                #print("Delayed assignment (by #2): ", line)
                text[self.outputDict[fileName]["lineIndexes"][x]] = \
                    line.replace(param, "#2 "+ param)
            
            MutatedFileNames = list(map(lambda x: x.replace(fileName, fileName[:-2]+'_mutation_'+self.getMutationType()+str(globalIterations)+'.v'), self.files))
                        
            with open('TestingCode/'+fileName[:-2]+'_mutation_'+self.getMutationType()+str(globalIterations)+'.v', 'w') as file:
                for line in text:
                    file.write(str(line))
            
        self.iterations +=1
        #global globalIterations
        globalIterations +=1
        return self.iterations, MutatedFileNames