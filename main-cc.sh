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
    [-d]: cubing/solving in parallel
    <n>: the order of the instance/number of vertices in the graph
    <r>: number of variable to remove in cubing, if not passed in, assuming no cubing needed
    <a>: amount of additional variables to remove for each cubing call
" && exit

#step 1: input parameters
if [ -z "$1" ]
then
    echo "Need instance order (number of vertices), use -h or --help for further instruction"
    exit
fi

n=$1 #order
p=${2}
q=$3
r=${4:-0} #num of cubes to generate first cubing stage
a=${5:-0} #amount of cubes to generate in each proceeding cubing stage
nodes=${6:-1} #number of nodes to use
lower=${7:-0}
upper=${8:-0}
#step 2: setp up dependencies
./dependency-setup.sh

#step 3 and 4: generate pre-processed instance

dir="."

if [ -f constraints_${n}_${p}_${q}_${lower}_${upper}_${r}_${a}_final.simp.log ]
then
    echo "Instance with these parameters has already been solved."
    exit 0
fi

./generate-instance.sh $n $p $q $lower $upper

if [ "$r" != "0" ] 
then
    dir="${n}_${p}_${q}_${lower}_${upper}_${r}_${a}"
    #./generate-instance.sh $n 0
    ./cube-solve-cc.sh $n constraints_${n}_${p}_${q}_${lower}_${upper} $dir $r $a constraints_${n}_${p}_${q}_${lower}_${upper} $nodes
else
    ./solve-verify.sh $n constraints_${n}_${p}_${q}_${lower}_${upper}_${r}_${a}.simp
fi
