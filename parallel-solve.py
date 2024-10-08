import subprocess
import multiprocessing
import os
import queue

def run_command(command):
    process_id = os.getpid()
    print(f"Process {process_id}: Executing command: {command}")

    file_to_cube = command.split()[-1]

    try:
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        stdout, stderr = process.communicate()

        if stderr:
            print(f"Error executing command: {stderr.decode()}")

        if "UNSAT" in stdout.decode():
            print("solved")
            remove_related_files(file_to_cube)
            process.terminate()
        else:
            print("Continue cubing this subproblem...")
            command = f"cube('{file_to_cube}', 'N', 0, {mg}, '{orderg}', {numMCTSg}, queue, '{cutoffg}', {cutoffvg}, {dg}, 'True')"
            queue.put(command)

    except Exception as e:
        print(f"Failed to run command due to: {str(e)}")

def run_cube_command(command):
    print (command)
    eval(command)

def remove_related_files(new_file):
    files_to_remove = [
        new_file,
        f"{new_file}.perm",
        #f"{new_file}.nonembed",
        f"{new_file}.drat",
        #f"{base_file}.drat"
    ]

    for file in files_to_remove:
        try:
            os.remove(file)
            print(f"Removed: {file}")
        except OSError as e:
            print(f"Error: {e.strerror}. File: {file}")

def rename_file(filename):
    # Remove .simp from file name
    
    if filename.endswith('.simp'):
        filename = filename[:-5]
    
    return filename
    
def worker(queue):
    while True:
        args = queue.get()
        if args is None:
            queue.task_done()
            break
        if args.startswith("./solve-verify"):
            run_command(args)
        else:
            run_cube_command(args)
        queue.task_done()

def cube(original_file, cube, index, m, order, numMCTS, queue, cutoff='d', cutoffv=5, d=0, extension="False"):
    if cube != "N":
        command = f"./gen_cubes/apply.sh {original_file} {cube} {index} > {cube}{index}.cnf && ./simplification/simplify-by-conflicts.sh -s {cube}{index}.cnf {order} 10000"
        file_to_cube = f"{cube}{index}.cnf.simp"
        simplog_file = f"{cube}{index}.cnf.simplog"
        file_to_check = f"{cube}{index}.cnf.ext"
    else:
        command = f"./simplification/simplify-by-conflicts.sh -s {original_file} {order} 10000"
        file_to_cube = f"{original_file}.simp"
        simplog_file = f"{original_file}.simplog"
        file_to_check = f"{original_file}.ext"
    subprocess.run(command, shell=True)

    # Check if the output contains "c exit 20"
    with open(simplog_file, "r") as file:
        if "c exit 20" in file.read():
            print("the cube is UNSAT")
            if cube != "N":
                os.remove(f'{cube}{index}.cnf')
            os.remove(file_to_cube)
            os.remove(file_to_check)
            return
    
    command = f"sed -E 's/.* 0 [-]*([0-9]*) 0$/\\1/' < {file_to_check} | awk '$0<={m}' | sort | uniq | wc -l"
    result = subprocess.run(command, shell=True, text=True, capture_output=True)
    var_removed = int(result.stdout.strip())
    if extension == "True":
        cutoffv = var_removed + 40

    print (f'{var_removed} variables removed from the cube')

    if cutoff == 'd':
        if d >= cutoffv:
            if solveaftercubeg == 'True':
                os.remove(f'{cube}{index}.cnf')
                command = f"./solve-verify.sh {order} {file_to_cube}"
                queue.put(command)
            return
    if cutoff == 'v':
        if var_removed >= cutoffv:
            if solveaftercubeg == 'True':
                os.remove(f'{cube}{index}.cnf')
                command = f"./solve-verify.sh {order} {file_to_cube}"
                queue.put(command)
            return
    subprocess.run(f"python3 -u alpha-zero-general/main.py {file_to_cube} -d 1 -m {m} -o {file_to_cube}.temp -order {order} -prod -numMCTSSims {numMCTS}", shell=True)
    d += 1
    if cube != "N":
        subprocess.run(f'''sed -E "s/^a (.*)/$(head -n {index} {cube} | tail -n 1 | sed -E 's/(.*) 0/\\1/') \\1/" {file_to_cube}.temp > {cube}{index}''', shell=True)
        next_cube = f'{cube}{index}'
    else:
        subprocess.run(f'mv {file_to_cube}.temp {original_file}0', shell=True)
        next_cube = f'{original_file}0'
    if cube != "N":
        os.remove(f'{cube}{index}.cnf')
        os.remove(f'{file_to_cube}.temp')
    os.remove(file_to_cube)
    os.remove(file_to_check)
    command1 = f"cube('{original_file}', '{next_cube}', 1, {m}, '{order}', {numMCTS}, queue, '{cutoff}', {cutoffv}, {d})"
    command2 = f"cube('{original_file}', '{next_cube}', 2, {m}, '{order}', {numMCTS}, queue, '{cutoff}', {cutoffv}, {d})"
    queue.put(command1)
    queue.put(command2)

def main(order, file_name_solve, numMCTS=2, cutoff='d', cutoffv=5, solveaftercube='True'):

    d=0 
    
    cutoffv = int(cutoffv)
    m = int(int(order)*(int(order)-1)/2)
    global queue, orderg, numMCTSg, cutoffg, cutoffvg, dg, mg, solveaftercubeg, file_name_solveg
    orderg, numMCTSg, cutoffg, cutoffvg, dg, mg, solveaftercubeg, file_name_solveg = order, numMCTS, cutoff, cutoffv, d, m, solveaftercube, file_name_solve
    queue = multiprocessing.JoinableQueue()
    num_worker_processes = multiprocessing.cpu_count()

    # Start worker processes
    processes = [multiprocessing.Process(target=worker, args=(queue,)) for _ in range(num_worker_processes)]
    for p in processes:
        p.start()

    #file_name_solve is a file where each line is a filename to solve
    with open(file_name_solve, 'r') as file:
        first_line = file.readline().strip()  # Read the first line and strip whitespace

        # Check if the first line starts with 'p cnf'
        if first_line.startswith('p cnf'):
            print("input file is a CNF file")
            cube(file_name_solve, "N", 0, m, order, numMCTS, queue, cutoff, cutoffv, d)
        else:
            print("input file contains name of multiple CNF file, solving them first")
            # Prepend the already read first line to the list of subsequent lines
            instance_lst = [first_line] + [line.strip() for line in file]
            for instance in instance_lst:
                command = f"./solve-verify.sh {order} {instance}"
                queue.put(command)

    # Wait for all tasks to be completed
    queue.join()

    # Stop workers
    for _ in processes:
        queue.put(None)
    for p in processes:
        p.join()

if __name__ == "__main__":
    import sys
    main(*sys.argv[1:])
