import pandas as pd
from mutationController import mutationController

print("Welcome to the mutation testing tool for Verilog")
TestbenchName= input("Enter the file name of your testbench: ")
#TopModuleName= input("Enter the file name of your top module: ")
print("Store all the required files in the same folder")
x=mutationController(TestbenchName)
x.applyMutations()
print(x.getComplete_df())