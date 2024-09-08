#!/bin/bash

[ "$1" = "-h" -o "$1" = "--help" -o "$#" -lt 8 ] && echo "
Description:
    Updated on 2023-01-11
    This script calls the python file generate.py in gen_instance to generate the SAT encoding for Ramsey number candidates. Such candidates satisfy the following conditions:
    1. The graph is squarefree, hence does not contain C4 subgraph
    2. All vertices are part of a triangle
    3. The graph avoids monochromatic cliques of specified sizes
    4. Minimum degree of each vertex is specified
    5. We also applied the cubic isomorphism blocking clauses

Usage:
    ./generate-instance.sh n p q lower upper u_e_b u_e_r mpcf

Options:
    <n>: the order of the instance/number of vertices in the graph
    <p>: size of monochromatic clique to avoid in first color
    <q>: size of monochromatic clique to avoid in second color
    <lower>: lower bound for degree constraints
    <upper>: upper bound for degree constraints
    <u_e_b>: parameter for blue triangle constraints
    <u_e_r>: parameter for red triangle constraints
    <mpcf>: maximum p-clique free parameter (0 or 1)

Example:
    ./generate-instance.sh 18 4 4 8 9 1 1 1
    
" && exit

n=$1
p=$2
q=$3
lower=$4
upper=$5
u_e_b=$6
u_e_r=$7
mpcf=$8

if [ -f constraints_${n}_${p}_${q}_${lower}_${upper}_${u_e_b}_${u_e_r}_${mpcf} ]
then
    echo "instance already generated"
else
    python3 gen_instance/generate.py $n $p $q $lower $upper $u_e_b $u_e_r $mpcf
fi
