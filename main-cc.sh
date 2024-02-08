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


while getopts "pmd:D:E:F:P" opt
do
    case $opt in
        p) d="-p" ;;
        m) m="-m" ;;
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
r=${5:-0} #num of var to eliminate during first cubing stage
a=${6:-10} #amount of additional variables to remove for each cubing call


#step 2: setp up dependencies
dir="${n}_${p}_${q}_${lower}_${upper}_${Edge_b}_${Edge_r}_${mpcf}_${t}_${r}_${a}"
cnf="constraints_${n}_${p}_${q}_${lower}_${upper}_${Edge_b}_${Edge_r}_${mpcf}"
#step 3 and 4: generate pre-processed instance

dir="."

if [ -f ${cnf}_${r}_${a}_final.simp.log ]
then
    echo "Instance with these parameters has already been solved."
    exit 0
fi

./generate-instance.sh $n $p $q $lower $upper

if [ "$r" != "0" ] 
then
    dir="${cnf}_${r}_${a}"
    #./generate-instance.sh $n 0
    ./cube-solve-cc.sh $n ${cnf} $dir $r $a ${cnf} $nodes
else
    ./solve-verify.sh $n ${cnf}_${r}_${a}.simp
fi
