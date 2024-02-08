#!/bin/bash

# Ensure parameters are specified on the command-line

[ "$1" = "-h" -o "$1" = "--help" ] && echo "
Description:
    Updated on 2023-12-19
    This is a driver script that handles generating the SAT encoding, solve the instance using CaDiCaL, then finally determine if a KS system exists for a certain order.

Usage:
    ./main.sh [-p] n r a
    If only parameter n is provided, default run ./main.sh n 0 0

Options:
    -n: No cubing, just solve
    -s: Cubing with sequential solving
    -l: Cubing with parallel solving
    [-p]: cubing/solving in parallel
    [-d]: lower bound on number of (colour 1) edges
    [-D]: upper bound on number of (colour 1) edges
    [-E]: upper bound on number of monochromatic triangles on a colour 1 edges
    [-F]: upper bound on number of monochromatic triangles on a colour 2 edges
    <n>: the order of the instance/number of vertices in the graph
    <p>: colour 1 cliques to block in encoding
    <q>: colour 2 cliques to block in encoding
    <t>: conflicts for which to simplify each time CaDiCal is called
    <r>: number of variable to remove in cubing, if not passed in, assuming no cubing needed
    <a>: amount of additional variables to remove for each cubing call
" && exit


while getopts "nsld:D:E:F:P" opt
do
    case $opt in
        n) solve_mode="no_cubing" ;;
        s) solve_mode="seq_cubing" ;;
        l) solve_mode="par_cubing" ;;
        d) lower=${OPTARG} ;; #lower bound on degree of blue vertices
        D) upper=${OPTARG} ;; #upper bound on degree of blue vertices
        E) Edge_b=${OPTARG} ;; #upper bound on blue triangles per blue edge
        F) Edge_r=${OPTARG} ;; #upper bound on red triangles per red edge
        P) mpcf="MPCF" ;;
        *) echo "Invalid option: -$OPTARG. Only -p and -m are supported. Use -h or --help for help" >&2
           exit 1 ;;
    esac
    
done
shift $((OPTIND-1))

if [[ ! -v lower ]]; then
    lower=0
fi
if [[ ! -v upper ]]; then
    upper=0
fi

if [[ ! -v Edge_b ]]; then
    Edge_b=0
fi

if [[ ! -v Edge_r ]]; then
    Edge_r=0
fi

if [[ ! -v mpcf ]]; then
    mpcf=0
fi

#step 1: input parameters
if [ -z "$1" ]
then
    echo "Need instance order (number of vertices) and number of simplification, use -h or --help for further instruction"
    exit
fi

n=$1 #order
p=$2
q=$3
t=${4:-100000} #conflicts for which to simplify each time CaDiCal is called, or % of variables to eliminate
m=${5:-2} #Num of MCTS simulations. m=0 activate march
d=${6:-d} #Cubing cutoff criteria, choose d(depth) as default #d, n, v
dv=${7:-5} #By default cube to depth 5
nodes=${8:-1} #Number of nodes to submit to if using -l


#step 2: setp up dependencies
./dependency-setup.sh
di="${n}_${p}_${q}_${lower}_${upper}_${Edge_b}_${Edge_r}_${mpcf}_${t}_${m}_${d}_${dv}_${nodes}"
mkdir -p $di
cnf="constraints_${n}_${p}_${q}_${lower}_${upper}_${Edge_b}_${Edge_r}_${mpcf}"

#step 3 and 4: generate pre-processed instance

if [ -f ${cnf}_${r}_${a}_final.simp.log ]
then
    echo "Instance with these parameters has already been solved."
    exit 0
fi

python3 gen_instance/generate.py $n $p $q $lower $upper $Edge_b $Edge_r ${mpcf} #generate the instance of order n for p,q
cp $cnf $di
# Solve Based on Mode
case $solve_mode in
    "no_cubing")
        echo "No cubing, just solve"
        
        echo "Simplifying $f for 10000 conflicts using CaDiCaL+CAS"
        ./simplification/simplify-by-conflicts.sh ${di}/$cnf $n $t

        echo "Solving $f using MapleSAT+CAS"
        ./solve-verify.sh $n ${di}/$cnf.simp
        ;;
    "seq_cubing")
        echo "Cubing and solving in parallel on local machine"
        python parallel-solve.py $n ${di}/$cnf $m $d $dv
        ;;
    "par_cubing")
        echo "Cubing and solving in parallel on Compute Canada"
        python parallel-solve.py $n ${di}/$cnf $m $d $dv False
        found_files=()

        # Populate the array with the names of files found by the find command
        while IFS= read -r -d $'\0' file; do
        found_files+=("$file")
        done < <(find . -regextype posix-extended -regex "./${di}/$cnf[^/]*" ! -regex '.*\.(simplog|ext)$' -print0)

        # Calculate the number of files to distribute names across and initialize counters
        total_files=${#found_files[@]}
        files_per_node=$(( (total_files + nodes - 1) / nodes )) # Ceiling division to evenly distribute
        counter=0
        file_counter=1

        # Check if there are files to distribute
        if [ ${#found_files[@]} -eq 0 ]; then
            echo "No files found to distribute."
            exit 1
        fi

        # Create $node number of files and distribute the names of found files across them
        for file_name in "${found_files[@]}"; do
            # Determine the current output file to write to
            output_file="${di}/node_${file_counter}.txt"
            submit_file="${di}/node_${file_counter}.sh"
            cat <<EOF > "$submit_file"
#!/bin/bash
#SBATCH --account=def-vganesh
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=0
#SBATCH --time=1-00:00

module load python/3.10

python parallel-solve.py $n $output_file $m $d $dv

EOF
            
            # Write the current file name to the output file
            echo "$file_name" >> "$output_file"
            
            # Update counters
            ((counter++))
            if [ "$counter" -ge "$files_per_node" ]; then
                counter=0
                ((file_counter++))
            fi
        done


        ;;
esac
