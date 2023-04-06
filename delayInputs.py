import sys
#import MutationOperator
from MutationOperator import MutationOperator
from GlobalVars import globalIterations, IverilogFilePath, vvpPath
import re
import string
import numpy as np


class delayInputs(MutationOperator):

    ## inputDict = {
    #   fileName: [{
    #       name: ....
    #       bitWidth: ...
    #       }, ....
    #   ]
    # }
    
    def __init__(self, TB, files):
        print(files)
        super().__init__('feedback for delayInputs', 'delayInputs',TB, files)
        self.numOfMutationsThatCanBeApplied = 0
        self.inputDict = {fileName: None for fileName in self.files}
        for fileName in self.files:
            text = open('TestingCode/'+fileName).readlines()
            inputList = []
            for line in text: ## Go in the text line by line.
                if(('input' in line)):
                    rearrangedLine = line.replace('input', '') ## drop input statement
                    # drop the bit declaraitons
                    if("[" in line ) & ("]" in line):
                        bitWidths = re.findall('\[.*?\]', rearrangedLine) ## save bitwidths for later usage.
                        rearrangedLine = re.sub('\[.*?\]', '', rearrangedLine) ## drop bitwidth
                        inputNames = re.findall(r'\w+', rearrangedLine) ## get all input signal's name
                        ## append to the total dict under the fileName
                        inputList.append(list(map(lambda x, y: {"name": x, "bitWidths": y}, inputNames, bitWidths)))
                    else:
                        
                        inputNames = re.findall(r'\w+', rearrangedLine) ## get all the input signal's name
                        ## append to the total dict under the fileName
                        inputList.append(list(map(lambda x: {"name": x, "bitWidths": ""}, inputNames)))
            self.inputDict[fileName] = [item for sublist in inputList for item in sublist] ## flatten the list
            self.numOfMutationsThatCanBeApplied = len(self.inputDict[fileName]) ## length of total input count in a single file
        print("Mutation Count: ", self.numOfMutationsThatCanBeApplied)

    def applyMutation(self, x):
        global globalIterations
        for fileName in self.files: ## iterate over files
            text = open('TestingCode/'+fileName).readlines()
            for lineIndex, line in enumerate(text): ## get the lineIndex for later use

                ## delay wire is written directly after the declaration of input to do not create syntax error.
                if((self.inputDict[fileName][x]["name"] in line) & ("input" in line)):
                    text[lineIndex] = line \
                    + "\nwire "+ str(self.inputDict[fileName][x]["bitWidths"]) \
                    + " #2 " + self.inputDict[fileName][x]["name"] \
                    +"Delayed = " + self.inputDict[fileName][x]["name"] + ";\n"
                    print("Wire Line: ", text[lineIndex])
                ## to change the input name in all file
                ## the question is should we delay the clock ????????
                if((self.inputDict[fileName][x]["name"] in line) &
                    (not "input" in line) & 
                    (not "module" in line)):
                    text[lineIndex] = line.replace(self.inputDict[fileName][x]["name"], self.inputDict[fileName][x]["name"] + "Delayed")
                    # print("Changed Line: ", text[lineIndex])
            ## This will have only one fileName not multiple. When this function called
            ## this will generate a single mutation file.
            MutatedFileNames = list(map(lambda x: x.replace(fileName, fileName[:-2]+'_mutation_'+self.getMutationType()+str(globalIterations)+'.v'), self.files))

            #MutatedFileNames.replace(i,i[:-2]+'_mutation_'+str(self.iterations)+'.v')                         
            with open('TestingCode/'+fileName[:-2]+'_mutation_'+self.getMutationType()+str(globalIterations)+'.v', 'w') as file:
                for line in text:
                    file.write(str(line))
            
        self.iterations +=1
        #global globalIterations
        globalIterations +=1
        return self.iterations, MutatedFileNames