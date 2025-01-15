import sys
import itertools
from cubic import cubic
import math
import csv
import subprocess
from degree_constraints import generate_degree_clauses #sinz sequential
from triangle_constraints import generate_triangle_clauses
from min_pclique_free import max_pclique_free
from b_b_card import generate_edge_clauses #totalizer
#requires that the cnf file does not exist
def generate(n, p, q, lower=0, upper=0, u_e_b=0, u_e_r=0, mpcf=0, card_type="sinz", edge_card_type="sinz", edge_lb=0, edge_ub=0):
    # Create base filename without temp suffix
    base_filename = f"constraints_{n}_{p}_{q}_{lower}_{upper}_{u_e_b}_{u_e_r}_{mpcf}"
    if lower > 0 or upper > 0:
        base_filename += f"_deg{card_type}"
    if edge_lb > 0 or edge_ub > 0:
        base_filename += f"_edge{edge_card_type}_lb{edge_lb}_ub{edge_ub}"

    # Use consistent temp filename for all intermediate operations
    temp_filename = f"constraints_temp_{n}_{p}_{q}_{lower}_{upper}_{u_e_b}_{u_e_r}_{mpcf}"
    if lower > 0 or upper > 0:
        temp_filename += f"_deg{card_type}"
    if edge_lb > 0 or edge_ub > 0:
        temp_filename += f"_edge{edge_card_type}_lb{edge_lb}_ub{edge_ub}"

    vertices = range(1, n+1)
    edge_dict = {}
    edge_counter = 0

    # Use temp_filename consistently for all intermediate writes
    for j in range(1, n+1):
        for i in range(1, j):
            edge_counter += 1
            edge_dict[(i,j)] = edge_counter

    for clique in itertools.combinations(vertices,p):
        constraint=""
        for j in itertools.combinations(clique,2):
            constraint+=str(-edge_dict[j])+" "
        with open(temp_filename, 'a') as f:
            f.write(constraint + "0" + "\n")

    for clique in itertools.combinations(vertices,q):
        constraint=""
        for j in itertools.combinations(clique,2):
            constraint+=str(edge_dict[j])+" "
        with open(temp_filename, 'a') as f: #q-cliques
           f.write(constraint + "0" + "\n")


    count,clause_count= cubic(n, math.comb(n,2), temp_filename) # write cubic constraints to file and count their total variables, and num_cubic constriants
    
    if lower>0:
        for i in range(1,n+1):
            if card_type == "sinz":
                deg_count, deg_clause = generate_degree_clauses([edge_dict[key] for key in edge_dict if i in key], lower, upper, count, temp_filename)
            elif card_type in ["totalizer", "totalizerconcise"]:  # totalizer
                deg_count, deg_clause = generate_edge_clauses([edge_dict[key] for key in edge_dict if i in key], lower, upper, count, temp_filename, card_type == "totalizer")
            else:
                print("Error: Invalid card_type")
            clause_count += deg_clause
            count = deg_count

    if u_e_b>0:
        print('blue triangle constraints')
        for i in range(1,n*(n-1)//2+1):
            X=set(range(1,n+1)) - set(list(edge_dict.keys())[list(edge_dict.values()).index(i)])#select all vertices except on i'th edge
            edge_count,edge_clause=generate_triangle_clauses(X,u_e_b,count,temp_filename,colour='b')
            #print('edges_blue',edge_count)
            clause_count +=edge_clause
            count=edge_count #+= built into generate_degree_clauses

    if u_e_r>0:
        print('red triangle constraints')
        for i in range(1,n*(n-1)//2+1):
            X=set(range(1,n+1)) - set(list(edge_dict.keys())[list(edge_dict.values()).index(i)])#select all vertiecs expect on i'th edge
            edge_count,edge_clause=generate_triangle_clauses(X,u_e_r,count,temp_filename,colour='r')
            #print('edges_red',edge_count)
            clause_count +=edge_clause
            count=edge_count #+= built into generate_degree_clauses

    if mpcf==0:
        mtf_count,mtf_clause=max_pclique_free(n,p,count,temp_filename)
        clause_count+=mtf_clause
        count=mtf_count
        MPCF='MPCF'
    else:
        MPCF=0

    # Add edge cardinality constraints if bounds are specified
    if edge_lb > 0 or edge_ub > 0:
        if edge_card_type == "sinz":
            edge_count, edge_clause = generate_degree_clauses(list(edge_dict.values()), edge_lb, edge_ub, count, temp_filename)
        elif edge_card_type in ["totalizer", "totalizerconcise"]:  # totalizer
            edge_count, edge_clause = generate_edge_clauses(list(edge_dict.values()), edge_lb, edge_ub, count, temp_filename, edge_card_type == "totalizer")
        else:
            print("Error: Invalid edge_card_type")
        clause_count += edge_clause
        count = edge_count

    count=str(count)
    clause_count=str(clause_count+math.comb(n,p)+math.comb(n,q))
    print(str(u_e_r), str(MPCF), count, clause_count)
    
    # Pass both temp filename and final filename to combine.sh
    proc1=subprocess.Popen([
        "./gen_instance/combine.sh",
        str(n), str(p), str(q), str(lower), str(upper), 
        str(u_e_b), str(u_e_r), str(MPCF), count, clause_count,
        temp_filename, base_filename
    ])
    proc1.wait()


if __name__ == "__main__":
    generate(
        int(sys.argv[1]), 
        int(sys.argv[2]), 
        int(sys.argv[3]),
        int(sys.argv[4]),
        int(sys.argv[5]),
        int(sys.argv[6]),
        int(sys.argv[7]),
        sys.argv[8],
        sys.argv[9],
        sys.argv[10],
        int(sys.argv[11]),
        int(sys.argv[12])
    )
