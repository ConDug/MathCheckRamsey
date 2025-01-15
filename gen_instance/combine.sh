#!/bin/bash
n=$1
p=$2
q=$3
lower=$4
upper=$5
u_e_b=$6
u_e_r=$7
mpcf=$8
count=$9
clause_count=${10}
temp_filename=${11}
final_filename=${12}

# Create the CNF header
echo "p cnf $count $clause_count" > header

# Combine header with temp file into final file
cat header "$temp_filename" > "$final_filename"

# Cleanup
rm header "$temp_filename"
