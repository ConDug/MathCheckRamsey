#!/bin/bash

s=false

# Option parsing
while getopts ":s" opt; do
  case $opt in
    s) s=true ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

shift $((OPTIND -1))

# Ensure parameters are specified on the command-line
if [ -z "$2" ]; then
  echo "Need filename, order, and the number of conflicts for which to simplify"
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
i=1
./cadical-ks/build/cadical-ks "$f_dir" "$f_dir.drat" --order $o -o "$f_dir".simp1 -e "$f_dir".ext1 -n -c $m | tee log/"$f_base".simp1

if [ "$s" != "true" ]; then
    echo "verifying the simplification now..."
    ./drat-trim/drat-trim "$f_dir" "$f_dir.drat" -f
    if ! grep -E "s DERIVATION|s VERIFIED" -q log/"$f_base".simp1.verify; then
        echo "ERROR: Proof not verified"
    fi
    rm -f "$f_dir.drat"
fi

conf_used=$(awk '/c conflicts:/ {print $3; exit}' log/"$f_base".simp1)
echo "$conf_used conflicts used for simplification"

if grep -q "UNSATISFIABLE" log/"$f_base".simp1; then
  conf_left=0
else
  conf_left=$((m - conf_used))
fi

while (( conf_used < m && conf_left != 0 )); do
  ./gen_cubes/concat-edge.sh $o "$f_dir".simp"$i" "$f_dir".ext"$i" | ./cadical-ks/build/cadical-ks /dev/stdin "$f_dir".simp"$i".drat --order $o -o "$f_dir".simp$((i+1)) -e "$f_dir".ext$((i+1)) -n -c $conf_left | tee log/"$f_base".simp$((i+1))
  if [ "$s" != "true" ]; then
    ./gen_cubes/concat-edge.sh $o "$f_dir".simp"$i" "$f_dir".ext"$i" | ./drat-trim/drat-trim /dev/stdin "$f_dir".simp"$i".drat -f | tee log/"$f_base".simp$((i+1)).verify
    if ! grep -E "s DERIVATION|s VERIFIED" -q log/"$f_base".simp$((i+1)).verify; then
      echo "ERROR: Proof not verified"
    fi
    rm -f "$f_dir".simp"$i".drat "$f_dir".simp"$i"
  fi
  conf_used_2=$(awk '/c conflicts:/ {print $3; exit}' log/"$f_base".simp$((i+1)))
  conf_used=$((conf_used + conf_used_2))
  conf_left=$((m - conf_used))
  ((i++))
  if grep -q "UNSATISFIABLE" log/"$f_base".simp$i; then
    break
  fi
done

echo "Called CaDiCaL $i times"

# Output final simplified instance
./gen_cubes/concat-edge.sh $o "$f_dir".simp"$i" "$f_dir".ext"$i" > "$f_dir".simp

cat "$f_dir".ext* > "$f_dir".ext
