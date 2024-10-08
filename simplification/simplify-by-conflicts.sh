#!/bin/bash

s=false

# Option parsing
#if the s flag is enabled, DRAT file will still be generated but verification will be skipped
while getopts ":s" opt; do
  case $opt in
    s) s=true ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

shift $((OPTIND -1))

# Ensure parameters are specified on the command-line
if [ -z "$3" ]; then
  echo "Need filename, order, and the number of conflicts for which to simplify"
  echo "if the s flag is enabled, DRAT file will still be generated but verification will be skipped"
  exit
fi

f=$1 # Filename
o=$2 # Order
m=$3 # Number of conflicts
e=$((o*(o-1)/2)) # Number of edge variables

# Create necessary directories
mkdir -p log

f_dir=$f
f_base=$(basename "$f")
echo $f_dir $f_base
# Simplify m seconds
echo "simplifying for $m conflicts"

# Check if "exit 20" is in the log
if [ "$s" != "true" ]; then
  ./cadical-ks/build/cadical-ks "$f_dir" "$f_dir.drat" --order $o -o "$f_dir".simp1 -e "$f_dir".ext -n -c $m | tee "$f_dir".simplog
  echo "verifying the simplification now..."
  if grep -q "exit 20" "$f_dir".simplog; then
    echo "CaDiCaL returns UNSAT, using backward proof checking..."
    ./drat-trim/drat-trim "$f_dir" "$f_dir.drat" | tee "$f_dir".verify
  else
    echo "CaDiCaL returns UNKNOWN, using forward proof checking..."
    ./drat-trim/drat-trim "$f_dir" "$f_dir.drat" -f | tee "$f_dir".verify
  fi
else
  echo "skipping generation of DRAT file"
  ./cadical-ks/build/cadical-ks "$f_dir" --order $o -o "$f_dir".simp1 -e "$f_dir".ext -n -c $m | tee "$f_dir".simplog
fi

# Output final simplified instance
./gen_cubes/concat-edge.sh $o "$f_dir".simp1 "$f_dir".ext > "$f_dir".simp
rm -f "$f_dir".simp1
