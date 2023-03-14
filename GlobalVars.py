from sys import platform
globalIterations = int(0)
if(platform == 'linux'):
    IverilogFilePath = 'iverilog'
    vvpPath = 'vvp'
else:
    IverilogFilePath = r"C:\iverilog\bin\iverilog.exe"
    vvpPath = r"C:\iverilog\bin\vvp.exe"
