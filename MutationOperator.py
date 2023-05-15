import shutil


from numpy.core.defchararray import strip

from GlobalVars import globalIterations, IverilogFilePath, vvpPath

from subprocess import STDOUT, check_output
import pandas as np

class MutationOperator:

    def __init__(self, feedback, mutationType, TB, files, dont_touch):
        self.dont_touch = dont_touch
        self.feedback = ""
        self.iterations = 0
        self.mutationType = mutationType
        self.files = files
        self.TB = TB
        self.default_true_sim = True

    def repaceParams(self): # replaces parameters with constants so that they can be parsed
        for i in self.files:
            text = open('TestingCode/' + i).readlines()
            params = []
            vals = []
            ii = 0
            for j in text:
                if ('PARAMETER' in j or 'parameter' in j or 'LOCALPARAM' in j or 'localparam' in j):
                    if('PARAMETER' in j):
                        params.append(strip(j[j.find('PARAMETER')+10:j.find('=')-1]))
                    elif('parameter' in j):
                        params.append(strip(j[j.find('PARAMETER')+10:j.find('=')-1]))
                    elif ('LOCALPARAM' in j):
                        params.append( strip(j[j.find('LOCALPARAM') +11:j.find('=') - 1]))
                    elif ('localparam' in j):
                        params.append( strip(j[j.find('localparam') +11:j.find('=') - 1]))
                    vals.append(int(strip(j[j.find('=')+1:j.find(';')])))
                    ii += 1

            for j in range(len(text)):
                for k in range(len(params)):
                    if str(params[k]) in text[j]:
                        if (not('PARAMETER' in text[j] or 'parameter' in text[j] or 'LOCALPARAM' in text[j] or 'localparam' in text[j])):
                            text[j]=text[j].replace(str(params[k]), str(vals[k]))
            with open('TestingCode/' + i, 'w') as file:
                for line in text:
                    file.write(str(line))

    def getMutationType(self):
        return self.mutationType

    def getNumOfMutationsThatCanBeApplied(self):
        return self.numOfMutationsThatCanBeApplied

    def applyMutationAndSimulate(self):
        iterationsAndResults = []
        for i in range(self.getNumOfMutationsThatCanBeApplied()):
            iteration, MutatedFileNames = self.applyMutation(i)
            result = self.simulate(MutatedFileNames)
            iterationsAndResults.append([self.getMutationType(),iteration, result])
            if (result):
                for i in MutatedFileNames:
                    if ('mutation' in i):
                        shutil.move('TestingCode/' + i, 'Pass/' + i)
                    else:
                        shutil.copy('TestingCode/' + i, 'Pass/' + i)
            else:
                for i in MutatedFileNames:
                    if ('mutation' in i):
                        shutil.move('TestingCode/' + i, 'Fail/' + i)
                    else:
                        shutil.copy('TestingCode/' + i, 'Fail/' + i)
        return iterationsAndResults

    def applyMutation(self, x):
        # should create MutatedFileNames
        # current code has a bug, its sometimes marking unchanged code as mutated, thus moving its folder
        MutatedFileNames = ''
        self.iterations += 1
        global globalIterations
        global IverilogFilePath
        global vvpPath
        globalIterations += 1
        return self.iterations, MutatedFileNames

    def simulate(self, MutatedFileNames):

        global IverilogFilePath
        global vvpPath
        try:
            tmp_list = ''
            for i in MutatedFileNames:
                tmp_list += ' TestingCode/' + i
            for i in self.dont_touch:
                tmp_list += ' TestingCode/' + i
            
            
            check_output(IverilogFilePath + ' -o simulationResult ' + tmp_list + ' TestingCode/' + self.TB,
                         stderr=STDOUT, timeout=10, shell=True)
            output = check_output(vvpPath + ' simulationResult', stderr=STDOUT, timeout=5, shell=True).decode("utf-8")
        except:
            output = ' syntaxProb '
            print(IverilogFilePath + ' -o simulationResult ' + tmp_list + ' TestingCode/' + self.TB)
            print('simulationFailed, syntax error, for debugging')
        print('*************************')
        
        #print(output)
        print('*************************')
        
        if ('fail' in output or 'error' in output):
            print('faillll')
            return not self.default_true_sim
        elif ('pass' in output):
            return self.default_true_sim
        elif ('syntaxProb' in output):
            return None
        
        else:
            #return np.nan
            return not self.default_true_sim

    def getFeedBack(self):
        return self.feedback
