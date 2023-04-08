import os
import sys
import pandas as pd
import shutil

import codecs

from numpy.core.defchararray import strip

from GlobalVars import globalIterations, IverilogFilePath, vvpPath

# import subprocess, threading
from subprocess import STDOUT, check_output


class MutationOperator:

    def __init__(self, feedback, mutationType, TB, files):
        self.feedback = ""
        self.iterations = 0
        self.mutationType = mutationType
        self.files = files
        self.TB = TB

    def repaceParams(self): # replaces parameters with constants so that they can be parsed
        print(self.files)
        for i in self.files:
            text = open('TestingCode/' + i).readlines()
            params = []
            vals = []
            ii = 0
            for j in text:
                if ('PARAMETER' in j or 'parameter' in j or 'LOCALPARAM' in j or 'localparam' in j):
                    if('PARAMETER' in j):
                        params[ii] = strip(j[j.find('PARAMETER')+10:j.find('=')-1])
                    elif('parameter' in j):
                        params.append(strip(j[j.find('PARAMETER')+10:j.find('=')-1]))
                    elif ('LOCALPARAM' in j):
                        params[ii] = strip(j[j.find('LOCALPARAM') +10:j.find('=') - 1])
                    elif ('localparam' in j):
                        params[ii] = strip(j[j.find('localparam') +10:j.find('=') - 1])
                    vals.append(int(strip(j[j.find('=')+1:j.find(';')])))
                    ii += 1

            for j in range(len(text)):
                for k in range(len(params)):
                    if str(params[k]) in text[j]:
                        if (not('PARAMETER' in text[j] or 'parameter' in text[j] or 'LOCALPARAM' in text[j] or 'localparam' in text[j])):
                            text[j]=text[j].replace(str(params[k]), str(vals[k]))
            with open('TestingCode/' + "replaced_params_"+i, 'w') as file:
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
            # we need to decide how we deal with this,
            # since projects can have multiple verilog files
            # should we store each mutation in a folder
            # or should we keep them in the same path with
            result = self.simulate(MutatedFileNames)
            iterationsAndResults.append([self.getMutationType(),iteration, result])
            # if mutation in name move, else copy
            # if not os.path.exists(newpath): use this to create folders for each mutation
            # os.makedirs(newpath)
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
        # tmp_list = ''
        # for i in MutatedFileNames:
        #    tmp_list += ' TestingCode/' + i
        # !'^+^+%%&%&//())==??é!'^+%&&//(())output = check_output(IverilogFilePath+' -o simulationResult ' + tmp_list +' TestingCode/'+ self.TB, stderr=STDOUT, timeout=5, shell=True)
        # output = check_output(vvpPath + ' simulationResult', stderr=STDOUT, timeout=5, shell=True).decode("utf-8")
        try:
            tmp_list = ''
            for i in MutatedFileNames:
                tmp_list += 'TestingCode/' + i
            check_output(IverilogFilePath + ' -o simulationResult ' + tmp_list + ' TestingCode/' + self.TB,
                         stderr=STDOUT, timeout=5, shell=True)
            output = check_output(vvpPath + ' simulationResult', stderr=STDOUT, timeout=5, shell=True).decode("utf-8")
        except:
            output = ' fail '
            print('simulationFailed, syntax error, for debugging')
        print(output)
        if ('pass' in output):
            return True
        elif ('fail' in output):
            return False
        else:
            return False

    def getFeedBack(self):
        return self.feedback