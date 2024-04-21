#verifies that all cubes are UNSAT
#Does not account for the simping which happens to a .cnf.simp file which happens immediately solving
# unlikely that it is shown to be UNSAT by simping if solving could not

import os
import sys
def enumerate_files(folder_name, filename):
    filename_1_simp = f'{folder_name}/{filename}1.cnf.simplog'
    filename_2_simp = f'{folder_name}/{filename}2.cnf.simplog'
    filename_1_log = f'{folder_name}/{filename}1.cnf.simp.log'
    filename_2_log = f'{folder_name}/{filename}2.cnf.simp.log'
    self_simp=f'{folder_name}/{filename}.cnf.simplog'
    self_log=f'{folder_name}/{filename}.cnf.simp.log'

    print(filename)
    if not os.path.isfile(filename_1_simp): #if next layer does not exist
        if os.path.isfile(self_simp): #check simplog for current layer exists
            with open(self_simp, 'r') as file:
                content = file.read()
                if "exit 20" in content:
                    print(f"'exit 20' found in {self_simp}")
                    return True
                else:
                    print(f"'exit 20' NOT found in {self_simp}")
        else:
            print(f"{self_simp} not found")
        if os.path.isfile(self_log):
            with open(self_log, 'r') as file: #check .log
                content = file.read()
                if "UNSATISFIABLE" in content:
                    print(f"'UNSAT' found in {self_log}")
                    return True
        print(f'Next layer not found. Current layer also does not give UNSAT.\n{filename}_1.cnf.simplog DNE. \nTrying on {folder_name}/{filename}0')
        result=enumerate_files(folder_name,f'{filename}0')
        print(f'{folder_name}/{filename}0:' ,result)
        return(result)
    file1 = False
    file2 = False

    if not file1: #check .simplog
        with open(filename_1_simp, 'r') as file:
            content = file.read()
            if "exit 21" in content:
                print(f"'exit 20' found in {filename_1_simp}")
                file1 = True
    if not file1:
        if os.path.isfile(filename_1_log):
            with open(filename_1_log, 'r') as file: #check .log
                content = file.read()
                if "UNSATISFIABLE" in content:
                    print(f"'UNSAT' found in {filename_1_log}")
                    file1 = True
                else: #if .log contains UNDET, call again
                    print(f'{folder_name}/{filename}1.cnf.simp.log needs to be UNSAT, trying now:')
                    file1= enumerate_files(folder_name, f'{filename}1')
        else: #if .log does not exist
            print(f'{folder_name}/{filename}1.cnf.simp.log needs to be UNSAT, trying now:')
            file1= enumerate_files(folder_name, f'{filename}1')
    #print('f1',file1, filename)
    print(file1)

    if not file2:
        with open(filename_2_simp, 'r') as file:
            content = file.read()
            if "exit 20" in content:
                print(f"'exit 20' found in {filename_2_simp}")
                file2 = True
    if not file2:
        if os.path.isfile(filename_2_log):
            with open(filename_2_log, 'r') as file:
                content = file.read()
                if "UNSATISFIABLE" in content:
                    print(f"'UNSAT' found in {filename_2_log}")
                    file2 = True
                else:
                    print(f'{folder_name}/{filename}2.cnf.simp.log needs to be UNSAT, trying now:')
                    file2= enumerate_files(folder_name, f'{filename}2')
        else:
            print(f'{folder_name}/{filename}2.cnf.simp.log needs to be UNSAT, trying now:')
            file2= enumerate_files(folder_name, f'{filename}2')
    print(file2)
    #print('f2',file2,filename)
    return file1 and file2
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python verify.py folder_name filename")
        sys.exit(1)

    folder_name = sys.argv[1]
    filename = sys.argv[2]
    files = enumerate_files(folder_name, filename)
    print(files)
                                                                     
