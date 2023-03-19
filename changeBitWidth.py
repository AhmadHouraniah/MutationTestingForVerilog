import sys
#import MutationOperator
from MutationOperator import MutationOperator
from GlobalVars import globalIterations, IverilogFilePath, vvpPath


class changeBitWidth(MutationOperator):
    
    def __init__(self, TB, files):
        print(files)
        super().__init__('feedback for changeBitWidth', 'changeBitWidth',TB, files)
        self.numOfMutationsThatCanBeApplied = 0
        for i in self.files:
            text = open('TestingCode/'+i).readlines()
            for j in text:
                if(('[' in j) and (']' in j) and (':' in j)):
                   self.numOfMutationsThatCanBeApplied+=1
        print(self.numOfMutationsThatCanBeApplied)

    
    def applyMutation(self, x):
        cnt = 0
        global globalIterations
        #MutatedFileNames = self.files[:]
        for i in self.files:
            text = open('TestingCode/'+i).readlines()
            for j in range(len(text)):
                if(('reg' in text[j]) and ('[' in text[j]) and (']' in text[j]) and (':' in text[j])):
                    if(cnt <= self.numOfMutationsThatCanBeApplied):
                        if(cnt == x):
                            search_text = ":"
                            replace_text = "-1:"
                            print(text[j] + '-> ' )
                            text[j] = text[j].replace(search_text, replace_text)
                            print(text[j])
                    cnt+=1
            #Theres a bug here!!!!
            MutatedFileNames = list(map(lambda x: x.replace(i, i[:-2]+'_mutation_'+str(globalIterations)+'.v'), self.files))

            #MutatedFileNames.replace(i,i[:-2]+'_mutation_'+str(self.iterations)+'.v')                         
            with open('TestingCode/'+i[:-2]+'_mutation_'+str(globalIterations)+'.v', 'w') as file:
                for line in text:
                    file.write(str(line))
            
        self.iterations +=1
        #global globalIterations
        globalIterations +=1
        return self.iterations, MutatedFileNames
    
    
    