#!/bin/bash

while getopts "s" opt
do
	case $opt in
        s) s="-s" ;;
	esac
done
shift $((OPTIND-1))

n=$1 #order
f=$2 #instance file name

[ "$1" = "-h" -o "$1" = "--help" -o "$#" -ne 2 ] && echo "
Description:
    Script for solving and generating drat proof for instance

Usage:
    ./solve-verify.sh n f e

Options:
    [-l]: generate learnt clauses
    <n>: the order of the instance/number of vertices in the graph
    <f>: file name of the CNF instance to be solved
" && exit

#./cadical-ks/build/cadical-ks $f $f.drat --order $n --unembeddable-check 17 --perm-out $f.perm --proofsize 7168 | tee $f.log
./maplesat-ks/simp/maplesat_static $f $f.drat -perm-out=$f.perm -exhaustive=$f.exhaust -order=$n -no-pre -minclause -max-proof-size=7168 -unembeddable-check=17 -unembeddable-out="$f.nonembed" | tee $f.log
#remove verification for now for testing purposes
