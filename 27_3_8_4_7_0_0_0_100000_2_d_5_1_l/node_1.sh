#!/bin/bash
#SBATCH --account=def-vganesh
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=0
#SBATCH --time=6-00:00
#SBATCH --output=27_3_8_4_7_0_0_0_100000_2_d_5_1_l/node_1_%N_%j.out

module load python/3.10

module load scipy-stack
source ENV/bin/activate
python parallel-solve.py 27 27_3_8_4_7_0_0_0_100000_2_d_5_1_l/node_1.txt 2 d 5

