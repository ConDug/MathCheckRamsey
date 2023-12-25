#!/bin/bash

[ "$1" = "-h" -o "$1" = "--help" -o "$#" -ne 2 ] && echo "
Description:
    Updated on 2023-01-11
    This script generate non-canonical blocking clauses of order o using maplesat-ks, then concanate the clauses into the instance.

Usage:
    ./2-add-blocking-clauses.sh n o f

Options:
    <n>: the order of the instance/number of vertices in the graph
    <f>: file name of the current SAT instance
" && exit

n=$1 #order of the graph we are solving
f=$2 #instance file name
#generate non canonical subgraph

command="./cadical-ks/build/cadical-ks $f $f.drat --order $n --unembeddable-check 17 --no-binary -c 10000"

echo $command
eval $command

grep 't' $f.drat | cut -d' ' -f 2- >> $f
lines=$(wc -l < "$f")
sed -i -E "s/p cnf ([0-9]*) ([0-9]*)/p cnf \1 $((lines-1))/" "$f"