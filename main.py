from MutationController import MutationController

print("Welcome to the mutation testing tool for Verilog")
TestbenchName= 'FIFO_tb.v'#input("Enter the file name of your testbench: ")
#TopModuleName= input("Enter the file name of your top module: ")
print("Store all the required files in the same folder")
x=MutationController(TestbenchName)
x.applyMutations()
print(x.getComplete_df())