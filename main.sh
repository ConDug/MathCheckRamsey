#!/bin/bash

[ "$1" = "-h" -o "$1" = "--help" ] && echo "
Description:
    Updated on 2024-03-19
    This is a driver script that handles generating the SAT encoding, simplifying the instance using CaDiCaL, 
    then cubing if directed and finally solving.

Usage:
    ./main.sh [options] n p q [t m d dv nodes]

Example:
    # Search for R(3,7) on 23 vertices with vertex degrees between 5 and 6
    ./main.sh -n -d 5 -D 6 23 3 7
    
    # Same search but using totalizer encoding for degree constraints
    ./main.sh -n -d 5 -D 6 --deg-card totalizer 23 3 7
    
    # Using different encodings for vertex degrees and edge count constraints
    ./main.sh -n -d 5 -D 6 --deg-card totalizer --edge-lb 80 --edge-ub 85 --edge-card sinz 23 3 7

Required Arguments:
    n               Number of vertices in the graph
    p               Number of colour 1 cliques to block in encoding
    q               Number of colour 2 cliques to block in encoding

Optional Arguments:
    t               Conflicts for simplification (default: 100000)
    m               Number of MCTS simulations (default: 2)
    d               Cubing cutoff criteria: d(depth), n, or v (default: d)
    dv              Cubing depth value (default: 50)
    nodes           Number of nodes for parallel solving (default: 1)

Options:
    -n              No cubing, just solve
    -s              Cubing with parallel solving on one node
    -l              Cubing with parallel solving across different nodes
    -d INT          Lower bound on number of (colour 1) edges per vertex
    -D INT          Upper bound on number of (colour 1) edges per vertex
    -E INT          Upper bound on monochromatic triangles on colour 1 edges
    -F INT          Upper bound on monochromatic triangles on colour 2 edges
    -P              Include maximum p-clique free constraints
    --deg-card TYPE Cardinality encoding type for degree constraints (sinz, totalizer, default: sinz)
    --edge-lb INT   Lower bound on total number of edges
    --edge-ub INT   Upper bound on total number of edges
    --edge-card TYPE Cardinality encoding type for edge constraints (sinz, totalizer, default: sinz)
" && exit

# Add new variables for the new parameters
deg_card_type="sinz"
edge_card_type="sinz"
edge_lb=0
edge_ub=0
solve_mode=""
lower=0
upper=0
Edge_b=0
Edge_r=0
mpcf=0

# Modify the getopts section to handle new parameters
while [ $# -gt 0 ]; do
    case "$1" in
        -n) solve_mode="no_cubing" ;;
        -s) solve_mode="sin_cubing" ;;
        -l) solve_mode="mul_cubing" ;;
        -d) lower="$2"; shift ;;
        -D) upper="$2"; shift ;;
        -E) Edge_b="$2"; shift ;;
        -F) Edge_r="$2"; shift ;;
        -P) mpcf="MPCF" ;;
        --deg-card) deg_card_type="$2"; shift ;;
        --edge-lb) edge_lb="$2"; shift ;;
        --edge-ub) edge_ub="$2"; shift ;;
        --edge-card) edge_card_type="$2"; shift ;;
        -*) echo "Invalid option: $1" >&2; exit 1 ;;
        *) break ;;
    esac
    shift
done

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
d=${6:-v} #Cubing cutoff criteria, choose d(depth) as default #d, n, v
dv=${7:-50} #By default cube to depth 5
nodes=${8:-1} #Number of nodes to submit to if using -l


#step 2: setp up dependencies
./dependency-setup.sh
di="${n}_${p}_${q}_${lower}_${upper}_${Edge_b}_${Edge_r}_${mpcf}_${t}_${m}_${d}_${dv}_${nodes}_${solve_mode}"
mkdir -p $di
cnf="constraints_${n}_${p}_${q}_${lower}_${upper}_${Edge_b}_${Edge_r}_${mpcf}"
echo $di
#step 3 and 4: generate pre-processed instance

if [ -f ${cnf}_${t}_${m}_${d}_${dv}_${nodes}_final.simp.log ]
then
    echo "Instance with these parameters has already been solved."
    exit 0
fi

if [ -f ${cnf} ]
then
    echo "instance already generated"
    cp ${cnf} ${cnf}_${t}_${m}_${d}_${dv}_${nodes}
else
    #echo $n $p $q $lower $upper $Edge_b $Edge_r
    python3 gen_instance/generate.py $n $p $q $lower $upper $Edge_b $Edge_r $mpcf $deg_card_type $edge_card_type $edge_lb $edge_ub
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
        python3 parallel-solve.py $n ${di}/${cnf}_${t}_${m}_${d}_${dv}_${nodes} $m $d $dv
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
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=4G
#SBATCH --time=3-00:00
#SBATCH --output=${di}/node_${file_counter}_%N_%j.out

# Following 3 lines due to our server requirements. Replace as needed.
#module load python/3.10
#module load scipy-stack
#source ENV/bin/activate

python parallel-solve.py $n $output_file $m $d $dv

EOF
            
            # Write the current file name to the output file
            echo "${file_name}.simp" >> "$output_file"
            
            # Update counters
            ((counter++))
            if [ "$counter" -ge "$files_per_node" ]; then
                counter=0
                ((file_counter++))
            fi
        done


        ;;
esac
