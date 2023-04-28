import os
import sys
import pandas as pd
from changeBitWidth import changeBitWidth
from forceConst import forceConst
from delayInputs import delayInputs
from delayOutputs import delayOutputs
from replaceOperator import replaceOperator

# from GlobalVars import globalIterations, IverilogFilePath, vvpPath


class MutationController:
    def __init__(self, TB):
        self.TB = TB
        all_files = os.listdir('TestingCode/')
        self.files = []
        for i in all_files:
            if ('.v' in i) and ('.vcd' not in i) and (i != TB):
                self.files.append(i)
                # add all verilog files except tb

        if self.files == '':
            print('No verilog files detected, make sure they are in the same folder')
        self.mutationTypes = [
            changeBitWidth(self.TB, self.files),
            delayInputs(self.TB, self.files),
            delayOutputs(self.TB, self.files), replaceOperator(self.TB, self.files), forceConst(self.TB, self.files)]#[changeBitWidth, forceConstant, unstableOutput, raceCondition, delayOut, operatorChange, randomFlips]
        
        self.cols1 = ['Mutation','iteration','resultType']
        self.complete_df = pd.DataFrame(columns=self.cols1)
        self.summarized_df = pd.DataFrame(columns=['Mutation', 'iterations', 'percentage_passed'])
        
        
    def applyMutations(self):
        for i in self.mutationTypes:
            mutationOperator = i
            list = mutationOperator.applyMutationAndSimulate()
            for j in list:
                # self.complete_df = self.complete_df.concat(pd.DataFrame([['changeBitWidth',j[0], j[1]]], columns=self.cols1), ignore_index=True)
                self.complete_df.loc[len(self.complete_df)] = [j[0], j[1], j[2]]
        #for i in self.mutationTypes:
            
#    def printSummarizedTable(self):
#        for i in self.mutationTypes:
#            self.summarized_df.loc[len(self.complete_df)] = [i.getMutationType(), complete_df.]
    def getComplete_df(self):
        return self.complete_df

    def getSummarized_df(self):
        for i in self.mutationTypes:
            self.summarized_df.loc[len(self.summarized_df)] = [i.getMutationType(), len(self.complete_df.query('Mutation == "'+i.getMutationType()+'"')),self.complete_df.query('Mutation == "'+i.getMutationType()+'"').query('resultType == True').resultType.count()/ len(self.complete_df.query('Mutation == "'+i.getMutationType()+'"'))]
            
        return self.summarized_df
    def getPlots(self):
        return self.summarized_df.plot(x="Mutation",y='iterations', kind="bar", rot=5, fontsize=8), self.summarized_df.plot(x="Mutation",y='iterations', kind="bar", rot=5, fontsize=8)


class main:
    def __init__(self, TestbenchName, TopModuleName):
        self.TestbenchName = TestbenchName
        self.TopModuleName = TopModuleName
