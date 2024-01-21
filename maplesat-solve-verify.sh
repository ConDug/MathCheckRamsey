#!/bin/bash

while getopts "l" opt
do
	case $opt in
        l) l="-l" ;;
	esac
done
shift $((OPTIND-1))

n=$1 #order
f=$2 #instance file name

[ "$1" = "-h" -o "$1" = "--help" -o "$#" -ne 2 ] && echo "
Description:
    Script for solving and generating drat proof for instance

Usage:
    ./maplesat-solve-verify.sh n f e

Options:
    [-l]: generate learnt clauses
    <n>: the order of the instance/number of vertices in the graph
    <f>: file name of the CNF instance to be solved
" && exit

./maplesat-ks/simp/maplesat_static $f $f.drat -perm-out=$f.perm -order=$n -no-pre -minclause | tee $f.log #-max-proof-size=7168 

if ! grep -q "UNSAT" "$f.log" || [ "$s" == "-s" ]; then
    echo "instance not solved, no need to verify unless learnt clause or skipping verification"
else
    ./proof-module.sh $n $f $f.verify
fi
