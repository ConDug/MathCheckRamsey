import sys
import itertools
from cubic import cubic
import math
import csv
import subprocess
from degree_constraints import generate_degree_clauses
from triangle_constraints import generate_triangle_clauses
from min_pclique_free import max_pclique_free
from edges_sinz_seq import generate_edge_clauses
#requires that the cnf file does not exist
def generate(n, p, q,lower=0,upper=0, u_e_b=0, u_e_r=0,mpcf=0):

    vertices=range(1,n+1)
    edge_dict={}
    edge_counter=0

    for j in range(1, n+1):             #generating the edge variables
        for i in range(1, j):
            edge_counter += 1
            edge_dict[(i,j)] = edge_counter

    for clique in itertools.combinations(vertices,p):
        constraint=""
        for j in itertools.combinations(clique,2):
            constraint+=str(-edge_dict[j])+" "
        with open(f"./constraints_temp_{n}_{p}_{q}_{lower}_{upper}_{u_e_b}_{u_e_r}_{mpcf}", 'a') as f: #p-cliques
            f.write(constraint + "0" + "\n")

    for clique in itertools.combinations(vertices,q):
        constraint=""
        for j in itertools.combinations(clique,2):
            constraint+=str(edge_dict[j])+" "
        with open(f"./constraints_temp_{n}_{p}_{q}_{lower}_{upper}_{u_e_b}_{u_e_r}_{mpcf}", 'a') as f: #q-cliques
           f.write(constraint + "0" + "\n")


    count,clause_count= cubic(n, math.comb(n,2),f"constraints_temp_{n}_{p}_{q}_{lower}_{upper}_{u_e_b}_{u_e_r}_{mpcf}") # write cubic constraints to file and count their total variables, and num_cubic constriants
    #clause_count =0
    #count=math.comb(n,2)
    #print(count,clause_count)
    
    if lower>0:
        for i in range(1,n+1):
            deg_count,deg_clause=generate_degree_clauses([edge_dict[key] for key in edge_dict if i in key],lower,upper,count,f"constraints_temp_{n}_{p}_{q}_{lower}_{upper}_{u_e_b}_{u_e_r}_{mpcf}")
            print(deg_count)
            clause_count +=deg_clause
            count=deg_count #+= built into generate_degree_clauses

    if u_e_b>0:
        print('blue triangle constraints')
        for i in range(1,n*(n-1)//2+1):
            X=set(range(1,n+1)) - set(list(edge_dict.keys())[list(edge_dict.values()).index(i)])#select all vertices except on i'th edge
            edge_count,edge_clause=generate_triangle_clauses(X,u_e_b,count,f"constraints_temp_{n}_{p}_{q}_{lower}_{upper}_{u_e_b}_{u_e_r}_{mpcf}",colour='b')
            #print('edges_blue',edge_count)
            clause_count +=edge_clause
            count=edge_count #+= built into generate_degree_clauses

    if u_e_r>0:
        print('red triangle constraints')
        for i in range(1,n*(n-1)//2+1):
            X=set(range(1,n+1)) - set(list(edge_dict.keys())[list(edge_dict.values()).index(i)])#select all vertiecs expect on i'th edge
            edge_count,edge_clause=generate_triangle_clauses(X,u_e_r,count,f"constraints_temp_{n}_{p}_{q}_{lower}_{upper}_{u_e_b}_{u_e_r}_{mpcf}",colour='r')
            #print('edges_red',edge_count)
            clause_count +=edge_clause
            count=edge_count #+= built into generate_degree_clauses

    if mpcf==0:
        mtf_count,mtf_clause=max_pclique_free(n,p,count,f"constraints_temp_{n}_{p}_{q}_{lower}_{upper}_{u_e_b}_{u_e_r}_{mpcf}")
        clause_count+=mtf_clause
        count=mtf_count
        MPCF='MPCF'
    else:
        MPCF=0
   
    print('80 edges') 
    #edge_count,edge_clause=generate_degree_clauses(list(range(1,math.comb(n,2)+1)),61,61,count,f"constraints_temp_{n}_{p}_{q}_{lower}_{upper}_{u_e_b}_{u_e_r}_{mpcf}")
    edge_count,edge_clause=generate_edge_clauses(list(range(1,math.comb(n,2)+1)),80,80,count,f"constraints_temp_{n}_{p}_{q}_{lower}_{upper}_{u_e_b}_{u_e_r}_{mpcf}")
    clause_count +=edge_clause
    count=edge_count

    count=str(count)
    clause_count =str(clause_count+math.comb(n,p)+math.comb(n,q))
    print(str(u_e_r), str(MPCF), count, clause_count)
    proc1=subprocess.Popen(["./gen_instance/combine.sh",str(n), str(p), str(q), str(lower), str(upper), str(u_e_b), str(u_e_r), str(MPCF), count, clause_count]) # call a bash file to combine cubic constraints and 1st line of cnf file
    proc1.wait()

if __name__ == "__main__":
    generate(int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]),int(sys.argv[4]),int(sys.argv[5]),int(sys.argv[6]),int(sys.argv[7]),sys.argv[8])
