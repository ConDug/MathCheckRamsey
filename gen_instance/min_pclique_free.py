import math
import csv
import itertools

def max_pclique_free(n,p,start_var, cnf_file):
    total_vars=start_var
    edge_counter=0
    edge_dict=dict()
    clauses = []
    for j in range(1, n+1):             #generating the edge variables
        for i in range(1, j):
            edge_counter += 1
            edge_dict[(i,j)] = edge_counter
            
    clique_dict=dict()
    vertices=range(1,n+1)

    # Want to select p-clique variables, and the edges of the p-clique
    # iterate over the vertices, to select each p-clique (less the edge we are on)
    for i,j in itertools.combinations(vertices,2): #for each edge
        for clique in itertools.combinations(vertices,p): #select all cliques
            if i in clique and j in clique: #ensures only cliques on the current edge
                # define a variable for each p-clique on each edge
                # variables represent a p-clique minus the edge
                total_vars += 1
                clique_dict[edge_dict[(i,j)],clique]=total_vars
                
                #define equivelance of p-cliques and edges (except for current edge)
                clauses.append([clique_dict[edge_dict[(i,j)],clique]]+[-edge_dict[edge] for edge in list(itertools.combinations(clique,2)) if edge != (i,j)])
                [clauses.append([-clique_dict[edge_dict[(i,j)],clique]]+[edge_dict[edge]]) for edge in list(itertools.combinations(clique,2)) if edge != (i,j)]
        #maximality constraint: 
        clauses.append([edge_dict[(i,j)]]+[clique_dict[edge_dict[(i,j)],edge] for edge in list(itertools.combinations(vertices,p)) if i in edge and j in edge])

    clause_count=0    
    cnf = open(cnf_file, 'a+')
    for clause in clauses:
        string_lst = []
        for var in clause:
            string_lst.append(str(var))
        string = ' '.join(string_lst)
        #print(string)
        cnf.write(string + " 0\n")
        clause_count += 1
    
    return(total_vars,clause_count)
