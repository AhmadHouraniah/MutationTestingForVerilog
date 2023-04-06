import os
import sys
import pandas as pd
from changeBitWidth import changeBitWidth
from forceConst import forceConst
from delayInputs import delayInputs


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
            delayInputs(self.TB, self.files)]#[changeBitWidth, forceConstant, unstableOutput, raceCondition, delayOut, operatorChange, randomFlips]
        self.cols1 = ['Mutation','iteration','result type']
        self.complete_df = pd.DataFrame(columns=self.cols1)
        self.summarized_df = pd.DataFrame(columns=['Mutation', 'iterations', 'percentage passed', 'percentage failed'])

    def applyMutations(self):
        for i in self.mutationTypes:
            mutationOperator = i
            list = mutationOperator.applyMutationAndSimulate()
            for j in list:
                # self.complete_df = self.complete_df.concat(pd.DataFrame([['changeBitWidth',j[0], j[1]]], columns=self.cols1), ignore_index=True)
                self.complete_df.loc[len(self.complete_df)] = ['changeBitWidth', j[0], j[1]]

    def getComplete_df(self):
        return self.complete_df

    def getSummarized_df(self):
        return self.summarized_df


class main:
    def __init__(self, TestbenchName, TopModuleName):
        self.TestbenchName = TestbenchName
        self.TopModuleName = TopModuleName
