#!/bin/bash
#SBATCH --account=def-vganesh
#SBATCH --time=02:00:00
#SBATCH --mem-per-cpu=4G
#SBATCH --nodes=1
#SBATCH --constraint=broadwell

while getopts "pmd:D:E:F:P" opt
do
    case $opt in
        p) d="-p" ;;
        m) m="-m" ;;
        d) lower=${OPTARG} ;; #lower bound on degree of blue vertices
        D) upper=${OPTARG} ;; #upper bound on degree of blue vertices
        E) Edge_b=${OPTARG} ;; #upper bound on triangles per blue edge
        F) Edge_r=${OPTARG} ;; #upper bound on triangles per red edge
        P) mpcf="-P" ;;
        *) echo "Invalid option: -$OPTARG. Only -p and -m are supported. Use -h or --help for help" >&2
           exit 1 ;;
    esac
    
done
shift $((OPTIND-1))

if [[ ! -v lower ]]; then
    lower=0
fi
if [[ ! -v upper ]]; then
    upper=0
fi

if [[ ! -v Edge_b ]]; then
    Edge_b=0
fi

if [[ ! -v Edge_r ]]; then
    Edge_r=0
fi

if [[ ! -v mpcf ]]; then
    mpcf=0
fi


n=$1 #order
p=$2
q=$3
t=${4:-100000} #conflicts for which to simplify each time CaDiCal is called, or % of variables to eliminate
r=${5:-0} #number of variables to eliminate until the cubing terminates
a=${6:-10}

module load python/3.10
./main.sh $d "-d" $lower "-D" $upper "-E" $Edge_b "-F" $Edge_r $mpcf $n $p $q $t $r $a $lower $upper
