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
    -s: Cubing with parallel solving on one node
    -l: Cubing with parallel solving across different nodes
    [-d]: lower bound on number of (colour 1) edges
    [-D]: upper bound on number of (colour 1) edges
    [-E]: upper bound on number of monochromatic triangles on a colour 1 edges
    [-F]: upper bound on number of monochromatic triangles on a colour 2 edges
    <n>: the order of the instance/number of vertices in the graph
    <p>: colour 1 cliques to block in encoding
    <q>: colour 2 cliques to block in encoding
    <m>: Number of MCTS simulations (default: 2)
    <d>: Cubing cutoff criteria, choose d(depth) as default #d, v (default: d)
    <dv>: By default cube to depth 5 (default: 5)
    <nodes>: Number of nodes to submit to if using -l (default: 1)
" && exit

while getopts "nsld:D:E:F:P" opt; do
    case $opt in
    n) solve_mode="no_cubing" ;;
    s) solve_mode="sin_cubing" ;;
    l) solve_mode="mul_cubing" ;;
    d) lower=${OPTARG} ;;  #lower bound on degree of blue vertices
    D) upper=${OPTARG} ;;  #upper bound on degree of blue vertices
    E) Edge_b=${OPTARG} ;; #upper bound on blue triangles per blue edge
    F) Edge_r=${OPTARG} ;; #upper bound on red triangles per red edge
    P) mpcf="MPCF" ;;
    *)
        echo "Invalid option: -$OPTARG. Only -p and -m are supported. Use -h or --help for help" >&2
        exit 1
        ;;
    esac

done
shift $((OPTIND - 1))

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
if [ -z "$1" ]; then
    echo "Need instance order (number of vertices) and number of simplification, use -h or --help for further instruction"
    exit
fi

n=$1 #order
p=$2
q=$3
t=${4:-100000} #conflicts for which to simplify each time CaDiCal is called, or % of variables to eliminate
m=${5:-2}      #Num of MCTS simulations. m=0 activate march
d=${6:-v}      #Cubing cutoff criteria, choose d(depth) as default #d, n, v
dv=${7:-50}    #By default cube to depth 5
nodes=${8:-1}  #Number of nodes to submit to if using -l

#step 2: setp up dependencies
./dependency-setup.sh
di="${n}_${p}_${q}_${lower}_${upper}_${Edge_b}_${Edge_r}_${mpcf}_${t}_${m}_${d}_${dv}_${nodes}_${solve_mode}"
mkdir -p $di
cnf="constraints_${n}_${p}_${q}_${lower}_${upper}_${Edge_b}_${Edge_r}_${mpcf}"
echo $di
#step 3 and 4: generate pre-processed instance

if [ -f ${cnf}_${t}_${m}_${d}_${dv}_${nodes}_final.simp.log ]; then
    echo "Instance with these parameters has already been solved."
    exit 0
fi

if [ -f ${cnf} ]; then
    echo "instance already generated"
    cp ${cnf} ${cnf}_${t}_${m}_${d}_${dv}_${nodes}
else
    #echo $n $p $q $lower $upper $Edge_b $Edge_r
    python3 gen_instance/generate.py $n $p $q $lower $upper $Edge_b $Edge_r ${mpcf} #generate the instance of order n for p,q
    cp ${cnf} ${cnf}_${t}_${m}_${d}_${dv}_${nodes}
fi

echo $solve_mode
cp ${cnf}_${t}_${m}_${d}_${dv}_${nodes} $di
# Solve Based on Mode
case $solve_mode in
"no_cubing")
    echo "No cubing, just solve"

    echo "Simplifying $f for t conflicts using CaDiCaL+CAS"
    ./simplification/simplify-by-conflicts.sh ${di}/${cnf}_${t}_${m}_${d}_${dv}_${nodes} $n $t

    echo "Solving $f using MapleSAT+CAS"
    ./solve-verify.sh $n ${di}/${cnf}_${t}_${m}_${d}_${dv}_${nodes}.simp
    ;;
"sin_cubing")
    echo "Simplifying $f for t conflicts using CaDiCaL+CAS"
    ./simplification/simplify-by-conflicts.sh ${di}/${cnf}_${t}_${m}_${d}_${dv}_${nodes} $n $t
    mv ${di}/${cnf}_${t}_${m}_${d}_${dv}_${nodes}.simp ${di}/${cnf}_${t}_${m}_${d}_${dv}_${nodes}
    echo "Cubing and solving in parallel on local machine"
    python parallel-solve.py $n ${di}/${cnf}_${t}_${m}_${d}_${dv}_${nodes} $m $d $dv
    ;;
"mul_cubing")
    echo "Simplifying $f for t conflicts using CaDiCaL+CAS"
    ./simplification/simplify-by-conflicts.sh ${di}/${cnf}_${t}_${m}_${d}_${dv}_${nodes} $n $t
    mv ${di}/${cnf}_${t}_${m}_${d}_${dv}_${nodes}.simp ${di}/${cnf}_${t}_${m}_${d}_${dv}_${nodes}
    echo "Cubing and solving in parallel on Compute Canada"
    python parallel-solve.py $n ${di}/${cnf}_${t}_${m}_${d}_${dv}_${nodes} $m $d $dv False
    found_files=()

    # Populate the array with the names of files found by the find command

    while IFS= read -r -d $'\0' file; do
        found_files+=("$file")
        #old
        #done < <(find "${di}" -mindepth 1 ! -name '*.drat' ! -name '*.ext' ! -name '*.ext1' ! -name '*.simp1' ! -name '*.simplog' ! -name '*.cubes' -print0)
        #done < <(find "${di}" -mindepth 1 -regex ".*\.\(11.cnf\|12.cnf\|21.cnf\|22.cnf\)$" -print0)
    done < <(find "${di}" -mindepth 1 -name "*.cnf" -print0)

    # Calculate the number of files to distribute names across and initialize counters
    total_files=${#found_files[@]}
    files_per_node=$(((total_files + nodes - 1) / nodes)) # Ceiling division to evenly distribute
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
        cat <<EOF >"$submit_file"
#!/bin/bash
#SBATCH --account=def-vganesh
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=4G
#SBATCH --time=3-00:00
#SBATCH --output=${di}/node_${file_counter}_%N_%j.out

#module load python/3.10
module load python/3.10

module load scipy-stack
source ENV/bin/activate
python parallel-solve.py $n $output_file $m $d $dv

EOF

        # Write the current file name to the output file
        echo "${file_name}.simp" >>"$output_file"

        # Update counters
        ((counter++))
        if [ "$counter" -ge "$files_per_node" ]; then
            counter=0
            ((file_counter++))
        fi
    done

    ;;
esac
