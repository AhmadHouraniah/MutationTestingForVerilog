import sys
#import MutationOperator
from MutationOperator import MutationOperator
from GlobalVars import globalIterations, IverilogFilePath, vvpPath


class replaceOperator(MutationOperator):
    
    def __init__(self, TB, files, dont_touch):
        #print(files)
        super().__init__('feedback for replaceOperator', 'replaceOperator',TB, files, dont_touch)
        self.numOfMutationsThatCanBeApplied = 0
        for i in self.files:
            text = open('TestingCode/'+i).readlines()
            for j in text:
                if(('!' in j) or ('~' in j) or ('&' in j) or ('|' in j) or ('<' in j) or ('>' in j) or ('%' in j) or ('+' in j)
                   or ('-' in j) or ('/' in j) or ('*' in j) or ('^' in j) or ('==' in j)):
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
                if(('!' in text[j]) or ('~' in text[j]) or ('&' in text[j]) or ('|' in text[j]) or ('<' in text[j]) or ('>' in text[j]) or ('%' in text[j]) or ('+' in text[j])
                   or ('-' in text[j]) or ('/' in text[j]) or ('*' in text[j]) or ('^' in text[j]) or ('==' in text[j])):
                    if(cnt <= self.numOfMutationsThatCanBeApplied):
                        if(cnt == x):
                            if('!' in text[j]):
                                search_text = "!"
                                replace_text = ""
                                #print(text[j] + '-> ' )
                                #text[j] = text[j].replace(search_text, replace_text)
                                #print(text[j])
                            elif('~' in text[j]):
                                search_text = "~"
                                replace_text = ""
                            elif('&' in text[j]):
                                search_text = "&"
                                replace_text = "|"
                            elif('|' in text[j]): 
                                search_text = "|"
                                replace_text = "&"
                            elif('<' in text[j]):
                                search_text = "<"
                                replace_text = ">"  
                            elif('>' in text[j]):
                                search_text = ">"
                                replace_text = "<"
                            elif('%' in text[j]):
                                search_text = "%"
                                replace_text = "*"
                            elif('+' in text[j]):
                                search_text = "+"
                                replace_text = "-"
                            elif('-' in text[j]):
                                search_text = "-"
                                replace_text = "+"
                            elif('/' in text[j]):
                                search_text = "/"
                                replace_text = "*"
                            elif('*' in text[j]):
                                search_text = "*"
                                replace_text = "-"
                            elif('^' in text[j]):
                                search_text = "^"
                                replace_text = "&"
                            elif('==' in text[j]):
                                search_text = "=="
                                replace_text = "!="
                                
                            print(text[j] + '-> ' )
                            text[j] = text[j].replace(search_text, replace_text)
                            print(text[j])
                            text.insert(j-1, ' //error insterted here \n')
                            
                    cnt+=1

            MutatedFileNames = list(map(lambda x: x.replace(i, i[:-2]+'_mutation_'+self.getMutationType()+str(globalIterations)+'.v'), self.files))

            #MutatedFileNames.replace(i,i[:-2]+'_mutation_'+str(self.iterations)+'.v')                         
            with open('TestingCode/'+i[:-2]+'_mutation_'+self.getMutationType()+str(globalIterations)+'.v', 'w') as file:
                for line in text:
                    file.write(str(line))
            
        self.iterations +=1
        #global globalIterations
        globalIterations +=1
        return self.iterations, MutatedFileNames
    
    
    