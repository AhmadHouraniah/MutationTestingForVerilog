To use this you need to have iverilog simulator installed
Set the iverilog and vvp installation path in GlobalVars.py

Place all verilog files in the working directory 
The script will find all verilog files and apply mutations on them

Mutation operators need to return the number of possible mutations that can be applied
If its too big we can use a fixed number maybe 50 

The mutationOperator class defines the methods to be use for the operators
The MutationController class applied the mutations and lists the types of mutations available. It is also responsible for the reporting techniques.

Currently mutations are marked by the iteration number, this should be updated to include the mutation type with an identifier.

Current version supports bit width reduction operation for regs
Rest of operators need to be implemented 
