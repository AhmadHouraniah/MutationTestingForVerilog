import sys
# import MutationOperator
from MutationOperator import MutationOperator
from GlobalVars import globalIterations, IverilogFilePath, vvpPath


class forceConst(MutationOperator):
    # force a 0/1 to bit position of any reg/wire
    # create temp wire/reg
    # change assignment of original to temp
    # assign output using tmp and reg

    # ex: x= 1+z ->
    #   tmp = 1+z
    #   x =tmp{[3], 1'b1, tmp[1:0]}
    # do for all bits in every reg
    # find assign statement,
    def __init__(self, TB, files):
        print(files)
        super().__init__('feedback for forceConst', 'forceConst', TB, files)
        self.numOfMutationsThatCanBeApplied = 0
        bitWidthsOfRegsAndWires = []
        super().repaceParams()
        for i in self.files:
            text = open('TestingCode/' + i).readlines()
            for j in text:
                if ('reg' in j) or ('output' in j) or ('wire' in j):
                    if ('[' in j) and (']' in j) and (':' in j):
                        print(j)
                        print(j.find('[', 0))
                        print(j.find(':', 0))
                        print(j.find(':', 0))
                        print(j.find(']', 0))
                        print('--------------------')
                        print(eval(j[j.find('[', 0)+1:j.find(':', 0)]))
                        print(eval(j[j.find(':', 0)+1:j.find(']', 0)]))
                        bits = 1 + int(eval(j[j.find('[', 0)+1:j.find(':', 0)])) - int(eval(
                            j[j.find(':', 0)+1:j.find(']', 0)]))  # 1 + number between [ and :, - number between : and ]
                        bitWidthsOfRegsAndWires.append(bits)
                    else:
                        bits = 1
                    self.numOfMutationsThatCanBeApplied += bits
                print(self.numOfMutationsThatCanBeApplied)

    def applyMutation(self, x):
        cnt = 0
        global globalIterations
        # MutatedFileNames = self.files[:]
        for i in self.files:
            text = open('TestingCode/' + i).readlines()
            for j in range(len(text)):
                # create tmp
                # change assignment to tmp
                # assign to original while forcing one of the bits of tmp to be 0

                cnt += 1
            # Theres a bug here!!!!
            MutatedFileNames = list(
                map(lambda x: x.replace(i, i[:-2] + '_mutation_' + str(globalIterations) + '.v'), self.files))

            # MutatedFileNames.replace(i,i[:-2]+'_mutation_'+str(self.iterations)+'.v')
            with open('TestingCode/' + i[:-2] + '_mutation_' + str(globalIterations) + '.v', 'w') as file:
                for line in text:
                    file.write(str(line))

        self.iterations += 1
        # global globalIterations
        globalIterations += 1
        return self.iterations, MutatedFileNames
