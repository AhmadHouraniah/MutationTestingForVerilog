from MutationOperator import MutationOperator
from GlobalVars import globalIterations, IverilogFilePath, vvpPath


class forceConst(MutationOperator):
    def __init__(self, TB, files):
        print(files)
        super().__init__('feedback for forceConst', 'forceConst', TB, files)
        self.numOfMutationsThatCanBeApplied = 0
        self.bitWidthsOfRegsAndWires = []
        self.names = []
        super().repaceParams()
        for i in self.files:
            text = open('TestingCode/' + i).readlines()
            for j in text:
                if (('reg' in j) or ('output' in j) or ('wire' in j)) and j.count('[')<2:
                    if ('[' in j) and (']' in j) and (':' in j):
                        bits = 1 + int(eval(j[j.find('[', 0)+1:j.find(':', 0)])) - int(eval(
                            j[j.find(':', 0)+1:j.find(']', 0)]))  # 1 + number between [ and :, - number between : and ]
                    else:
                        bits = 1
                    self.bitWidthsOfRegsAndWires.append(bits)
                    
                    if ('[' in j) and (']' in j) and (':' in j):    
                        self.names.append(j[j.find(']')+1:j.find(';')].strip())
                    elif 'output' in j and ('reg' in j or 'wire' in j):
                        self.names.append(j.split()[2][:j.split()[2].find(';')])
                    else:
                        self.names.append(j.split()[1][:j.split()[1].find(';')])
                    self.numOfMutationsThatCanBeApplied += bits

    def applyMutation(self, x):
        cnt = 0
        global globalIterations
        cu_list = []
        length = len(self.bitWidthsOfRegsAndWires)
        cu_list = [sum(self.bitWidthsOfRegsAndWires[0:y:1]) for y in range(0, length+1)]
        cu_list = cu_list[1:]        
        k=0
        while(x>cu_list[k]):
            k+=1        
            
        for i in self.files:
            text = open('TestingCode/' + i).readlines()
            for j in range(len(text)):
                if 'endmodule' in text[j]:
                    
                    if(self.bitWidthsOfRegsAndWires[k]==1):
                        text[j] = 'initial force ' + self.names[k] + ' = 1\'b0;\n'

                    else:
                        text[j] = 'initial force ' + self.names[k] + '['+str(max(0,x-cu_list[k-1]-1))+'] = 1\'b0;\n'

                    text.append('endmodule')

                cnt += 1
            MutatedFileNames = list(map(lambda x: x.replace(i, i[:-2]+'_mutation_'+self.getMutationType()+str(globalIterations)+'.v'), self.files))

            with open('TestingCode/'+i[:-2]+'_mutation_'+self.getMutationType()+str(globalIterations)+'.v', 'w') as file:
                for line in text:
                    file.write(str(line))

        self.iterations += 1
        globalIterations += 1
        return self.iterations, MutatedFileNames
