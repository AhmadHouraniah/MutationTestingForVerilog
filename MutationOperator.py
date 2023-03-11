import os
import sys
import pandas as pd
import shutil

import codecs  

from GlobalVars import globalIterations, IverilogFilePath, vvpPath

# import subprocess, threading
from subprocess import STDOUT, check_output

# class Command(object):
#     def __init__(self, cmd):
#         self.cmd = cmd
#         self.process = None

#     def run(self, timeout):
#         def target():
            
#             self.process = subprocess.Popen(self.cmd, shell=True, stdout=subprocess.PIPE)
#             self.process.wait()
#             response = self.process.communicate()[0]
#             print(response)

#         thread = threading.Thread(target=target)
#         thread.start()

#         thread.join()
#         if thread.is_alive():
#             print('Terminating process')
#             self.process.terminate()
#             thread.join()
#         print(self.process.returncode)


      
class MutationOperator:
    
    def __init__(self, feedback, mutationType,TB, files):
        self.feedback = ""
        self.iterations = 0
        self.mutationType = mutationType
        self.files = files
        self.TB = TB
    def getMutationType(self):
        return self.mutationType
    
    def getNumOfMutationsThatCanBeApplied(self):
        return None
        
    def applyMutationAndSimulate(self):
        iterationsAndResults = []
        for i in range (self.getNumOfMutationsThatCanBeApplied()):
            iteration, MutatedFileNames = self.applyMutation(i)
            #we need to decide how we deal with this, 
            #since projects can have multiple verilog files
            #should we store each mutation in a folder
            #or should we keep them in the same path with 
            result =  self.simulate(MutatedFileNames)
            iterationsAndResults.append([iteration, result])
            #if mutation in name move, else copy            
            #if not os.path.exists(newpath): use this to create folders for each mutation
                #os.makedirs(newpath)
            if(result):
                for i in MutatedFileNames:
                    shutil.move('TestingCode/'+i, 'Pass/'+i)
            else:
                for i in MutatedFileNames:
                    shutil.move('TestingCode/'+i, 'Fail/'+i)
        return iterationsAndResults
        
    def applyMutation(self, x):
        #should create MutatedFileNames 
        #current code has a bug, its sometimes marking unchanged code as mutated, thus moving its folder
        MutatedFileNames = ''
        self.iterations +=1
        global globalIterations
        globalIterations +=1
        return self.iterations, MutatedFileNames
    def simulate(self, MutatedFileNames):
        
        
        
        try:
            output = check_output(IverilogFilePath+' -o simulationResult ' + ' TestingCode/'.join(MutatedFileNames) +' TestingCode/'+ self.TB, stderr=STDOUT, timeout=100)
            output = check_output(vvpPath + ' simulationResult', stderr=STDOUT, timeout=100).decode("utf-8")
        except:
            output = ' fail '
            print('simulationFailed, syntax error, for debugging')
        
        if('pass' in output   ):
            return True
        elif('fail' in output ):
            return False
        else:
            return False
        
    def getFeedBack(self):
        return self.feedback
        
        


    
