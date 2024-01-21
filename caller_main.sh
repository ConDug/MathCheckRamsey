#!/bin/bash
#SBATCH --account=def-vganesh
#SBATCH --time=100:00:00
#SBATCH --mem-per-cpu=4G
#SBATCH --nodes=1
#SBATCH --constraint=broadwell

while getopts "apsbm" opt
do
    case $opt in
        p) d="-p" ;;
        m) m="-m" ;;
        *) echo "Invalid option: -$OPTARG. Only -p and -m are supported. Use -h or --help for help" >&2
           exit 1 ;;

        esac
done
shift $((OPTIND-1))

n=$1 #order
p=${2}
q=$3
r=${4:-0} #num of var to eliminate during first cubing stage
a=${5:-0} #amount of additional variables to remove for each cubing call
lower=${6:-0}
upper=${7:-0}

module load python/3.10 
./main.sh $d $n $p $q $r $a $lower $upper
