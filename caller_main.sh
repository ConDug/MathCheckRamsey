#!/bin/bash
#SBATCH --account=def-vganesh
#SBATCH --time=110:00:00
#####SBATCH --mem-per-cpu=4G
#SBATCH --nodes=1
#SBATCH --mem=0
#SBATCH --constraint=broadwell

while getopts "nsld:D:E:F:P" opt
do
    case $opt in
        n) t1="-n" ;;
        s) t1="-s" ;;
        l) t1="-l" ;;
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


n=$1 #order
p=$2
q=$3
t=${4:-100000} #conflicts for which to simplify each time CaDiCal is called, or % of variables to eliminate
m=${5:-2} #Num of MCTS simulations. m=0 activate march
d=${6:-d} #Cubing cutoff criteria, choose d(depth) as default #d, n, v
dv=${7:-5} #By default cube to depth 5
nodes=${8:-1} #Number of nodes to submit to if using -l

module load python/3.10

module load scipy-stack
pip install tqdm --no-index
pip install rl_coach
pip install coloredlogs --no-index
pip install wandb --no-index
pip install argparse --no-index
./main.sh ${t1} "-d" $lower "-D" $upper "-E" $Edge_b "-F" $Edge_r $mpcf $n $p $q $t $m $d ${dv} $nodes
