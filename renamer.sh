#!/bin/bash
cd completed_27_3_8_4_7_0_0_0_100000_2_v_150_16_mul_cubing
for file in constraints_*.cnf.simp0*.cnf.simp*; do
        filename=$(basename -- "$file")
        newname=$(echo $filename | awk '{sub(".cnf.simp0","0");print}')
        mv $file $newname
done
echo 'complete'
