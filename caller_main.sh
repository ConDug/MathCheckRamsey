#!/bin/bash
#SBATCH --account=def-vganesh
#SBATCH --time=30:00:00
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=4G
#SBATCH --ntasks-per-node=1
#SBATCH --constraint=broadwell
#SBATCH --nodes=1

[ "$1" = "-h" -o "$1" = "--help" ] && echo "
Description:
    Updated on 2024-03-19
    A wrapper script for main.sh that handles job submission on compute clusters.

Usage:
    ./caller_main.sh [options] n p q [t m d dv nodes]

Example:
    # Search for R(3,7) on 23 vertices with vertex degrees between 5 and 6
    ./caller_main.sh -n -d 5 -D 6 23 3 7
    
    # Same search but using totalizer encoding for degree constraints
    ./caller_main.sh -n -d 5 -D 6 --deg-card totalizer 23 3 7
    
    # Using different encodings for vertex degrees and edge count constraints
    ./caller_main.sh -n -d 5 -D 6 --deg-card totalizer --edge-lb 80 --edge-ub 85 --edge-card sinz 23 3 7

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

# Initialize variables
deg_card_type="sinz"
edge_card_type="sinz"
edge_lb=0
edge_ub=0

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -n) t1="-n" ;;
        -s) t1="-s" ;;
        -l) t1="-l" ;;
        -d) lower="$2"; shift ;;
        -D) upper="$2"; shift ;;
        -E) Edge_b="$2"; shift ;;
        -F) Edge_r="$2"; shift ;;
        -P) mpcf="-P" ;;
        --deg-card) deg_card_type="$2"; shift ;;
        --edge-lb) edge_lb="$2"; shift ;;
        --edge-ub) edge_ub="$2"; shift ;;
        --edge-card) edge_card_type="$2"; shift ;;
        -*) echo "Invalid option: $1" >&2; exit 1 ;;
        *) break ;;
    esac
    shift
done

# Add these variable checks after the argument parsing
if [ -z "${lower+x}" ]; then
    lower=0
fi
if [ -z "${upper+x}" ]; then
    upper=0
fi
if [ -z "${Edge_b+x}" ]; then
    Edge_b=0
fi
if [ -z "${Edge_r+x}" ]; then
    Edge_r=0
fi
if [ -z "${mpcf+x}" ]; then
    mpcf=0
fi

# Get positional arguments
n=$1 #order
p=$2
q=$3
t=${4:-100000}
m=${5:-2}
d=${6:-d}
dv=${7:-5}
nodes=${8:-1}

# Build the command with all options
cmd="./main.sh ${t1}"
[ -n "$lower" ] && cmd+=" -d $lower"
[ -n "$upper" ] && cmd+=" -D $upper"
[ -n "$Edge_b" ] && cmd+=" -E $Edge_b"
[ -n "$Edge_r" ] && cmd+=" -F $Edge_r"
[ -n "$mpcf" ] && cmd+=" $mpcf"
cmd+=" --deg-card $deg_card_type"
cmd+=" --edge-lb $edge_lb"
cmd+=" --edge-ub $edge_ub"
cmd+=" --edge-card $edge_card_type"
cmd+=" $n $p $q $t $m $d $dv $nodes"

# Execute the command
eval $cmd
