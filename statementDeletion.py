import sys
#import MutationOperator
from MutationOperator import MutationOperator
from GlobalVars import globalIterations, IverilogFilePath, vvpPath


class statementDeletion(MutationOperator):
    
    def __init__(self, TB, files, dont_touch):
        print(files)
        super().__init__('feedback for statementDeletion', 'statementDeletion',TB, files, dont_touch)
        self.numOfMutationsThatCanBeApplied = 0
        for i in self.files:
            text = open('TestingCode/'+i).readlines()
            for j in text:
                #if(('<' in j) and ('=' in j) and ('#')):
                if(not j.isspace() and 'reg' not in j and 'wire' not in j and  'input' not in j and  'output' not in j and 'begin' not in j and  'end' not in j):
                    self.numOfMutationsThatCanBeApplied+=1
        
    def getNumOfMutationsThatCanBeApplied(self):
        return self.numOfMutationsThatCanBeApplied
    
    def applyMutation(self, x):
        cnt = 0
        global globalIterations
        #MutatedFileNames = self.files[:]
        for i in self.files:
            text = open('TestingCode/'+i).readlines()
            for j in range(len(text)):
                if(not text[j].isspace() and 'reg' not in text[j] and 'wire' not in text[j] and  'input' not in text[j] and  'output' not in text[j] and 'begin' not in text[j] and  'end' not in text[j]):
                    if(cnt == x):
                        text[j]= "//////"+text[j]
                    cnt+=1
              
            #There is a bug here!!!!
            MutatedFileNames = list(map(lambda x: x.replace(i, i[:-2]+'_mutation_'+self.getMutationType()+str(globalIterations)+'.v'), self.files))

            #MutatedFileNames.replace(i,i[:-2]+'_mutation_'+str(self.iterations)+'.v')                         
            with open('TestingCode/'+i[:-2]+'_mutation_'+self.getMutationType()+str(globalIterations)+'.v', 'w') as file:
                for line in text:
                    file.write(str(line))
            
        self.iterations +=1
        #global globalIterations
        globalIterations +=1
        return self.iterations, MutatedFileNames
    
    
    